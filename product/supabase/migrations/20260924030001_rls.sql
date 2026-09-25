-- Helper functions used by RLS policies.

create or replace function public.current_staff()
returns staff_profiles
language sql stable security definer set search_path = public as $$
  select * from staff_profiles where id = auth.uid() and active = true
$$;

create or replace function public.current_app_role()
returns app_role
language sql stable security definer set search_path = public as $$
  select role from staff_profiles where id = auth.uid() and active = true
$$;

create or replace function public.current_org_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select org_id from staff_profiles where id = auth.uid() and active = true
  union all
  select org_id from kiosk_devices where device_auth_user_id = auth.uid() and active = true
  limit 1
$$;

-- Returns the branch this session is scoped to, or null when the session
-- sees the whole org (admin, viewer).
create or replace function public.current_branch_scope()
returns uuid
language sql stable security definer set search_path = public as $$
  select case
    when sp.role in ('admin', 'viewer') then null
    else sp.branch_id
  end
  from staff_profiles sp
  where sp.id = auth.uid() and sp.active = true
  union all
  select branch_id
  from kiosk_devices
  where device_auth_user_id = auth.uid() and active = true
  limit 1
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from staff_profiles
    where id = auth.uid() and role = 'admin' and active = true
  )
$$;

create or replace function public.is_manager_or_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from staff_profiles
    where id = auth.uid() and role in ('admin', 'manager') and active = true
  )
$$;

create or replace function public.is_kiosk_device()
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from kiosk_devices
    where device_auth_user_id = auth.uid() and active = true
  )
$$;

-- ─────────────────────────────────────────────────────────────
-- Enable RLS everywhere
-- ─────────────────────────────────────────────────────────────

alter table orgs             enable row level security;
alter table branches         enable row level security;
alter table staff_profiles   enable row level security;
alter table kiosk_devices    enable row level security;
alter table categories       enable row level security;
alter table suppliers        enable row level security;
alter table products         enable row level security;
alter table batches          enable row level security;
alter table purchase_orders  enable row level security;
alter table po_lines         enable row level security;
alter table receiving_events enable row level security;
alter table alerts           enable row level security;
alter table rounds           enable row level security;
alter table round_items      enable row level security;
alter table temp_logs        enable row level security;
alter table audit_log        enable row level security;

-- ─────────────────────────────────────────────────────────────
-- Read policies — same shape everywhere: "you see rows in your org,
-- and if you're branch-scoped, only your branch."
-- ─────────────────────────────────────────────────────────────

create policy read_org on orgs
  for select using (id = current_org_id());

create policy read_branches on branches
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or id = current_branch_scope()
    )
  );

-- Staff can see their own row + other staff on the same branch. Admin/viewer see all.
create policy read_staff on staff_profiles
  for select using (
    org_id = current_org_id() and (
      current_app_role() in ('admin', 'viewer')
      or id = auth.uid()
      or (branch_id is not null and branch_id = current_branch_scope())
    )
  );

create policy read_kiosk on kiosk_devices
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_categories on categories
  for select using (org_id = current_org_id());

create policy read_suppliers on suppliers
  for select using (org_id = current_org_id());

create policy read_products on products
  for select using (org_id = current_org_id());

create policy read_batches on batches
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_pos on purchase_orders
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_po_lines on po_lines
  for select using (
    exists (
      select 1 from purchase_orders po
      where po.id = po_lines.po_id
        and po.org_id = current_org_id()
        and (current_branch_scope() is null or po.branch_id = current_branch_scope())
    )
  );

create policy read_receiving on receiving_events
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_alerts on alerts
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_rounds on rounds
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_round_items on round_items
  for select using (
    exists (
      select 1 from rounds r
      where r.id = round_items.round_id
        and r.org_id = current_org_id()
        and (current_branch_scope() is null or r.branch_id = current_branch_scope())
    )
  );

create policy read_temp_logs on temp_logs
  for select using (
    org_id = current_org_id() and (
      current_branch_scope() is null
      or branch_id = current_branch_scope()
    )
  );

create policy read_audit_log on audit_log
  for select using (
    org_id = current_org_id() and (
      current_app_role() in ('admin', 'viewer')
      or (branch_id is not null and branch_id = current_branch_scope())
    )
  );

-- ─────────────────────────────────────────────────────────────
-- Write policies
--   admin  — everything in org
--   manager — everything in their branch (no user mgmt, no rev ops writes)
--   staff  — never writes directly; all staff writes go through RPCs
--   viewer — never writes
--   kiosk device — never writes directly; RPCs only
-- ─────────────────────────────────────────────────────────────

-- Only admin manages orgs and branches
create policy write_orgs_admin on orgs
  for all using (is_admin() and id = current_org_id())
  with check (is_admin() and id = current_org_id());

create policy write_branches_admin on branches
  for all using (is_admin() and org_id = current_org_id())
  with check (is_admin() and org_id = current_org_id());

create policy write_staff_admin on staff_profiles
  for all using (is_admin() and org_id = current_org_id())
  with check (is_admin() and org_id = current_org_id());

create policy write_kiosk_admin on kiosk_devices
  for all using (is_admin() and org_id = current_org_id())
  with check (is_admin() and org_id = current_org_id());

-- Admin manages catalog; managers can add products/suppliers within their branch scope
create policy write_categories_admin on categories
  for all using (is_admin() and org_id = current_org_id())
  with check (is_admin() and org_id = current_org_id());

create policy write_suppliers_admin_manager on suppliers
  for all using (is_manager_or_admin() and org_id = current_org_id())
  with check (is_manager_or_admin() and org_id = current_org_id());

create policy write_products_admin_manager on products
  for all using (is_manager_or_admin() and org_id = current_org_id())
  with check (is_manager_or_admin() and org_id = current_org_id());

-- Manager can adjust batches within their branch; admin anywhere in org.
-- Staff writes go through RPCs (never here).
create policy write_batches_manager on batches
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

create policy write_pos_manager on purchase_orders
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

create policy write_po_lines_manager on po_lines
  for all using (
    is_manager_or_admin()
    and exists (
      select 1 from purchase_orders po
      where po.id = po_lines.po_id
        and po.org_id = current_org_id()
        and (current_branch_scope() is null or po.branch_id = current_branch_scope())
    )
  )
  with check (
    is_manager_or_admin()
    and exists (
      select 1 from purchase_orders po
      where po.id = po_lines.po_id
        and po.org_id = current_org_id()
        and (current_branch_scope() is null or po.branch_id = current_branch_scope())
    )
  );

create policy write_receiving_manager on receiving_events
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

create policy write_alerts_manager on alerts
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

create policy write_rounds_manager on rounds
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

create policy write_round_items_manager on round_items
  for all using (
    is_manager_or_admin()
    and exists (
      select 1 from rounds r
      where r.id = round_items.round_id
        and r.org_id = current_org_id()
        and (current_branch_scope() is null or r.branch_id = current_branch_scope())
    )
  )
  with check (
    is_manager_or_admin()
    and exists (
      select 1 from rounds r
      where r.id = round_items.round_id
        and r.org_id = current_org_id()
        and (current_branch_scope() is null or r.branch_id = current_branch_scope())
    )
  );

create policy write_temp_logs_manager on temp_logs
  for all using (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  )
  with check (
    is_manager_or_admin()
    and org_id = current_org_id()
    and (current_branch_scope() is null or branch_id = current_branch_scope())
  );

-- audit_log is written exclusively by RPCs (SECURITY DEFINER); no direct writes.
