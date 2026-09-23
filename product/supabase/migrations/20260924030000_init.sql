-- ShelfLife MVP schema
-- 1 org, N branches, kiosk devices per branch, PIN-authed staff, email-authed admin/viewer.

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ─────────────────────────────────────────────────────────────
-- Enums
-- ─────────────────────────────────────────────────────────────

create type app_role as enum ('admin', 'manager', 'staff', 'viewer');
create type expiry_mode as enum ('printed', 'computed');
create type batch_state as enum (
  'active', 'flagged', 'pulled', 'sold_out',
  'relabeled', 'frozen', 'discarded', 'donated'
);
create type po_status as enum ('draft', 'sent', 'partial', 'received', 'cancelled');
create type alert_status as enum ('open', 'acked', 'resolved');
create type alert_resolution as enum (
  'pulled', 'already_sold', 'relabeled', 'frozen',
  'discounted', 'donated', 'discarded'
);
create type shift_slot as enum ('opening', 'mid', 'closing');
create type round_item_status as enum (
  'ok', 'flagged', 'pulled', 'relabeled', 'frozen', 'discarded'
);
create type actor_channel as enum ('web', 'kiosk');

-- ─────────────────────────────────────────────────────────────
-- Core tenancy
-- ─────────────────────────────────────────────────────────────

create table orgs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table branches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  name text not null,
  address text,
  timezone text not null default 'America/New_York',
  created_at timestamptz not null default now(),
  unique (org_id, name)
);

-- Staff profile extends auth.users. For kiosk-only staff there is still a
-- row in auth.users (a passwordless account created by admin) so we can
-- always resolve actor_id via foreign keys.
create table staff_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid references branches(id) on delete set null,
  display_name text not null,
  role app_role not null,
  is_shift_lead boolean not null default false,
  pin_hash text,                     -- bcrypt-style, nullable for non-kiosk users
  pin_last_changed_at timestamptz,
  email citext,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint staff_needs_branch check (
    role in ('admin', 'viewer') or branch_id is not null
  ),
  constraint kiosk_needs_pin check (
    role <> 'staff' or pin_hash is not null
  )
);

create index staff_profiles_org_role_idx on staff_profiles(org_id, role);
create index staff_profiles_branch_idx on staff_profiles(branch_id) where branch_id is not null;

-- A kiosk device is a physical tablet/phone bolted to a branch. It signs
-- into Supabase as its own auth.users row and then staff step through
-- actions via PIN on top.
create table kiosk_devices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  device_auth_user_id uuid not null unique references auth.users(id) on delete cascade,
  label text not null,
  active boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  unique (branch_id, label)
);

-- ─────────────────────────────────────────────────────────────
-- Catalog
-- ─────────────────────────────────────────────────────────────

create table categories (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  name text not null,
  expiry_mode expiry_mode not null,
  default_shelf_life_days int,
  alert_thresholds int[] not null default '{30,7}',
  allows_markdown_past_date boolean not null default false,
  allows_donation_past_date boolean not null default false,
  is_ftl boolean not null default false,                  -- FDA Food Traceability List
  requires_relabel_on_freeze boolean not null default true,
  created_at timestamptz not null default now(),
  unique (org_id, name),
  constraint computed_needs_shelf_life check (
    expiry_mode = 'printed' or default_shelf_life_days is not null
  )
);

create table suppliers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  name text not null,
  contact_email citext,
  contact_phone text,
  notes text,
  created_at timestamptz not null default now(),
  unique (org_id, name)
);

create table products (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  upc text,
  sku text,
  name text not null,
  category_id uuid not null references categories(id) on delete restrict,
  default_supplier_id uuid references suppliers(id) on delete set null,
  default_location text,
  unit_cost_cents int,
  unit_price_cents int,
  created_at timestamptz not null default now(),
  unique (org_id, upc),
  unique (org_id, sku)
);

create index products_org_name_idx on products(org_id, lower(name));

-- ─────────────────────────────────────────────────────────────
-- Inventory
-- ─────────────────────────────────────────────────────────────

create table batches (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  quantity_received numeric(10,3) not null check (quantity_received > 0),
  quantity_remaining numeric(10,3) not null check (quantity_remaining >= 0),
  expiry_date date not null,
  expiry_source expiry_mode not null,
  received_date date not null default current_date,
  supplier_id uuid references suppliers(id) on delete set null,
  traceability_lot_code text,          -- FSMA 204 KDE
  supplier_ref text,                   -- invoice / PO reference
  location text,
  state batch_state not null default 'active',
  parent_batch_id uuid references batches(id) on delete set null,
  notes text,
  received_by uuid references staff_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint remaining_lte_received check (quantity_remaining <= quantity_received)
);

create index batches_branch_state_idx on batches(branch_id, state);
create index batches_expiry_idx on batches(branch_id, expiry_date) where state = 'active';
create index batches_product_idx on batches(product_id);

-- ─────────────────────────────────────────────────────────────
-- Purchase orders
-- ─────────────────────────────────────────────────────────────

create table purchase_orders (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  supplier_id uuid not null references suppliers(id) on delete restrict,
  po_number text not null,
  status po_status not null default 'draft',
  expected_delivery_date date,           -- "date of next shipments"
  actual_delivery_date date,
  notes text,
  created_by uuid references staff_profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (org_id, po_number)
);

create index po_branch_status_idx on purchase_orders(branch_id, status);
create index po_expected_idx on purchase_orders(branch_id, expected_delivery_date) where status in ('draft', 'sent', 'partial');

create table po_lines (
  id uuid primary key default gen_random_uuid(),
  po_id uuid not null references purchase_orders(id) on delete cascade,
  product_id uuid not null references products(id) on delete restrict,
  quantity_ordered numeric(10,3) not null check (quantity_ordered > 0),
  quantity_received numeric(10,3) not null default 0 check (quantity_received >= 0),
  unit_cost_cents int,
  notes text
);

create index po_lines_po_idx on po_lines(po_id);

create table receiving_events (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  po_id uuid references purchase_orders(id) on delete set null,
  received_by uuid references staff_profiles(id) on delete set null,
  received_at timestamptz not null default now(),
  notes text
);

-- ─────────────────────────────────────────────────────────────
-- Alerts
-- ─────────────────────────────────────────────────────────────

create table alerts (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  batch_id uuid not null references batches(id) on delete cascade,
  threshold_days int not null,
  fired_at timestamptz not null default now(),
  status alert_status not null default 'open',
  resolved_by uuid references staff_profiles(id) on delete set null,
  resolved_at timestamptz,
  resolution alert_resolution,
  notes text,
  unique (batch_id, threshold_days)
);

create index alerts_branch_status_idx on alerts(branch_id, status);

-- ─────────────────────────────────────────────────────────────
-- Rounds (shift audits: opening / mid / closing, done in pairs)
-- ─────────────────────────────────────────────────────────────

create table rounds (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  shift shift_slot not null,
  scheduled_date date not null default current_date,
  started_at timestamptz,
  completed_at timestamptz,
  lead_staff_id uuid references staff_profiles(id) on delete set null,
  second_staff_id uuid references staff_profiles(id) on delete set null,
  notes text,
  unique (branch_id, scheduled_date, shift)
);

create table round_items (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references rounds(id) on delete cascade,
  batch_id uuid references batches(id) on delete set null,
  product_id uuid references products(id) on delete set null,
  category_id uuid references categories(id) on delete set null,
  status round_item_status not null,
  notes text,
  created_at timestamptz not null default now()
);

create index round_items_round_idx on round_items(round_id);

-- ─────────────────────────────────────────────────────────────
-- Temperature logs (optional cold-holding capture)
-- ─────────────────────────────────────────────────────────────

create table temp_logs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  location_label text not null,
  temp_f numeric(5,2) not null,
  recorded_by uuid references staff_profiles(id) on delete set null,
  recorded_at timestamptz not null default now(),
  notes text
);

create index temp_logs_branch_time_idx on temp_logs(branch_id, recorded_at desc);

-- ─────────────────────────────────────────────────────────────
-- Audit log (append-only, feeds admin oversight)
-- ─────────────────────────────────────────────────────────────

create table audit_log (
  id bigserial primary key,
  org_id uuid references orgs(id) on delete set null,
  branch_id uuid references branches(id) on delete set null,
  actor_id uuid references staff_profiles(id) on delete set null,
  actor_channel actor_channel not null,
  device_id uuid references kiosk_devices(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_org_time_idx on audit_log(org_id, created_at desc);
create index audit_log_branch_time_idx on audit_log(branch_id, created_at desc);
create index audit_log_actor_time_idx on audit_log(actor_id, created_at desc);
