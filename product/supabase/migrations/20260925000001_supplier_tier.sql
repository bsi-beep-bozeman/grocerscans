-- ShelfLife — Supplier tier, part 2: table, functions, RLS.
--
-- Depends on 20260925000000_supplier_tier.sql (which added 'supplier' to
-- app_role in its own transaction). Per PLAN_ADDENDUM_2026-09-25.md §1.
--
-- Note: 'manager' remains an unused enum value. Dropping it requires an
-- enum swap that trips on existing check constraints and RLS policies —
-- not worth the churn since the seed never creates a manager. All write
-- policies below are admin-only regardless.

-- ─────────────────────────────────────────────────────────────
-- 1. supplier_profiles: link a Supabase auth user to one supplier
-- ─────────────────────────────────────────────────────────────

create table supplier_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  org_id       uuid not null references orgs(id) on delete cascade,
  supplier_id  uuid not null references suppliers(id) on delete cascade,
  display_name text not null,
  email        citext,
  active       boolean not null default true,
  created_at   timestamptz not null default now(),
  unique (supplier_id, id)
);

create index supplier_profiles_supplier_idx
  on supplier_profiles(supplier_id) where active = true;
create index supplier_profiles_org_idx
  on supplier_profiles(org_id);

alter table supplier_profiles enable row level security;

-- ─────────────────────────────────────────────────────────────
-- 2. Helper functions — supplier-aware
-- ─────────────────────────────────────────────────────────────

-- Rebuild current_app_role() so suppliers resolve to 'supplier'.
create or replace function public.current_app_role()
returns app_role
language sql stable security definer set search_path = public as $$
  select role from staff_profiles
    where id = auth.uid() and active = true
  union all
  select 'supplier'::app_role from supplier_profiles
    where id = auth.uid() and active = true
  limit 1
$$;

create or replace function public.is_supplier()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from supplier_profiles
    where id = auth.uid() and active = true
  )
$$;

-- Supplier's linked supplier_id, or null when the caller isn't a supplier.
create or replace function public.current_supplier_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select supplier_id from supplier_profiles
    where id = auth.uid() and active = true
  limit 1
$$;

-- Extend current_org_id() so suppliers resolve to their org too.
create or replace function public.current_org_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select org_id from staff_profiles
    where id = auth.uid() and active = true
  union all
  select org_id from kiosk_devices
    where device_auth_user_id = auth.uid() and active = true
  union all
  select org_id from supplier_profiles
    where id = auth.uid() and active = true
  limit 1
$$;

-- ─────────────────────────────────────────────────────────────
-- 3. RLS for supplier_profiles
--    Admin: full CRUD in own org.
--    Viewer: read all rows in org.
--    Supplier: read own row only.
--    Staff, kiosk: no access.
-- ─────────────────────────────────────────────────────────────

create policy supplier_profiles_admin_all on supplier_profiles
  for all using (is_admin() and org_id = current_org_id())
  with check (is_admin() and org_id = current_org_id());

create policy supplier_profiles_viewer_read on supplier_profiles
  for select using (
    current_app_role() = 'viewer' and org_id = current_org_id()
  );

create policy supplier_profiles_self_read on supplier_profiles
  for select using (id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- 4. Supplier read scoping on existing tables.
--    Suppliers get READ-only access to their own slice. No write policies.
-- ─────────────────────────────────────────────────────────────

create policy read_suppliers_own on suppliers
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
    and id = current_supplier_id()
  );

create policy read_products_own_supplier on products
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
    and default_supplier_id = current_supplier_id()
  );

create policy read_batches_own_supplier on batches
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
    and supplier_id = current_supplier_id()
  );

create policy read_pos_own_supplier on purchase_orders
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
    and supplier_id = current_supplier_id()
  );

create policy read_po_lines_own_supplier on po_lines
  for select using (
    current_app_role() = 'supplier'
    and exists (
      select 1 from purchase_orders po
      where po.id = po_lines.po_id
        and po.org_id = current_org_id()
        and po.supplier_id = current_supplier_id()
    )
  );

create policy read_receiving_own_supplier on receiving_events
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
    and exists (
      select 1 from purchase_orders po
      where po.id = receiving_events.po_id
        and po.supplier_id = current_supplier_id()
    )
  );

-- Categories: suppliers need to read all in-org categories so their own
-- products render with their category names.
create policy read_categories_supplier on categories
  for select using (
    current_app_role() = 'supplier'
    and org_id = current_org_id()
  );

-- ─────────────────────────────────────────────────────────────
-- 5. Rewrite existing read policies to exclude suppliers.
--
-- Postgres RLS OR-combines permissive policies for a given command, so the
-- existing broad "any role in org sees everything" policies would grant
-- suppliers full visibility on top of the narrow policies above. Each
-- affected policy is dropped and recreated with `and not is_supplier()`
-- so suppliers are only served by the narrow slice.
-- ─────────────────────────────────────────────────────────────

drop policy if exists read_suppliers  on suppliers;
drop policy if exists read_products   on products;
drop policy if exists read_batches    on batches;
drop policy if exists read_pos        on purchase_orders;
drop policy if exists read_po_lines   on po_lines;
drop policy if exists read_receiving  on receiving_events;

-- read_categories is broad but suppliers already get a matching narrow
-- policy that grants the same rows (all in-org categories) — no visibility
-- change, but drop-and-recreate anyway so the intent is explicit.
drop policy if exists read_categories on categories;

create policy read_suppliers on suppliers
  for select using (
    org_id = current_org_id() and not is_supplier()
  );

create policy read_products on products
  for select using (
    org_id = current_org_id() and not is_supplier()
  );

create policy read_categories on categories
  for select using (
    org_id = current_org_id() and not is_supplier()
  );

create policy read_batches on batches
  for select using (
    org_id = current_org_id()
    and not is_supplier()
    and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_pos on purchase_orders
  for select using (
    org_id = current_org_id()
    and not is_supplier()
    and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_po_lines on po_lines
  for select using (
    not is_supplier()
    and exists (
      select 1 from purchase_orders po
      where po.id = po_lines.po_id
        and po.org_id = current_org_id()
        and (current_branch_scope() is null or po.branch_id = current_branch_scope())
    )
  );

create policy read_receiving on receiving_events
  for select using (
    org_id = current_org_id()
    and not is_supplier()
    and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );
