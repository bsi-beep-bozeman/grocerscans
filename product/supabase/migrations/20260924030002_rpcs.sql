-- RPCs, alert evaluator, and views.
-- All RPCs are SECURITY DEFINER so they can bypass RLS after their own checks.
-- Grants at the end lock execution to authenticated sessions only.

-- ─────────────────────────────────────────────────────────────
-- PIN management (admin only)
-- ─────────────────────────────────────────────────────────────

create or replace function public.set_staff_pin(target_staff_id uuid, new_pin text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
  if new_pin !~ '^\d{4,6}$' then
    raise exception 'PIN must be 4-6 digits' using errcode = '22023';
  end if;
  update staff_profiles
     set pin_hash = crypt(new_pin, gen_salt('bf', 8)),
         pin_last_changed_at = now()
   where id = target_staff_id
     and org_id = current_org_id();
end $$;

-- ─────────────────────────────────────────────────────────────
-- Kiosk PIN verification
-- Returns the matching staff row, or empty if PIN is wrong.
-- ─────────────────────────────────────────────────────────────

create or replace function public.kiosk_verify_pin(pin text)
returns table (staff_id uuid, display_name text, is_shift_lead boolean)
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices%rowtype;
begin
  select * into device
    from kiosk_devices
   where device_auth_user_id = auth.uid()
     and active = true;
  if not found then
    raise exception 'not a kiosk device' using errcode = '42501';
  end if;

  update kiosk_devices set last_seen_at = now() where id = device.id;

  return query
    select sp.id, sp.display_name, sp.is_shift_lead
      from staff_profiles sp
     where sp.org_id = device.org_id
       and sp.branch_id = device.branch_id
       and sp.role = 'staff'
       and sp.active = true
       and sp.pin_hash is not null
       and sp.pin_hash = crypt(pin, sp.pin_hash);
end $$;

-- Internal helper — assert caller is the kiosk for a branch, and PIN belongs
-- to a staff in that same branch. Returns the resolved device row.
create or replace function public._assert_kiosk_actor(
  actor_staff_id uuid, actor_pin text
) returns kiosk_devices
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices%rowtype;
begin
  select * into device
    from kiosk_devices
   where device_auth_user_id = auth.uid()
     and active = true;
  if not found then
    raise exception 'kiosk only' using errcode = '42501';
  end if;

  perform 1 from staff_profiles
   where id = actor_staff_id
     and org_id = device.org_id
     and branch_id = device.branch_id
     and role = 'staff'
     and active = true
     and pin_hash = crypt(actor_pin, pin_hash);
  if not found then
    raise exception 'invalid PIN' using errcode = '42501';
  end if;

  return device;
end $$;

-- ─────────────────────────────────────────────────────────────
-- Kiosk writes
-- ─────────────────────────────────────────────────────────────

create or replace function public.kiosk_log_batch(
  actor_staff_id uuid,
  actor_pin text,
  p_product_id uuid,
  p_quantity numeric,
  p_expiry_date date,
  p_expiry_source expiry_mode,
  p_supplier_id uuid default null,
  p_traceability_lot_code text default null,
  p_location text default null,
  p_notes text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
  new_batch_id uuid;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  perform 1 from products where id = p_product_id and org_id = device.org_id;
  if not found then
    raise exception 'product not found in org' using errcode = 'P0002';
  end if;

  insert into batches (
    org_id, branch_id, product_id, quantity_received, quantity_remaining,
    expiry_date, expiry_source, supplier_id, traceability_lot_code, location, notes, received_by
  ) values (
    device.org_id, device.branch_id, p_product_id, p_quantity, p_quantity,
    p_expiry_date, p_expiry_source, p_supplier_id, p_traceability_lot_code,
    p_location, p_notes, actor_staff_id
  ) returning id into new_batch_id;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'batch.create', 'batch', new_batch_id,
          jsonb_build_object('product_id', p_product_id,
                             'quantity', p_quantity,
                             'expiry_date', p_expiry_date));
  return new_batch_id;
end $$;

create or replace function public.kiosk_resolve_alert(
  actor_staff_id uuid,
  actor_pin text,
  p_alert_id uuid,
  p_resolution alert_resolution,
  p_notes text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  update alerts
     set status = 'resolved',
         resolution = p_resolution,
         resolved_by = actor_staff_id,
         resolved_at = now(),
         notes = coalesce(p_notes, notes)
   where id = p_alert_id
     and org_id = device.org_id
     and branch_id = device.branch_id;
  if not found then
    raise exception 'alert not in this branch' using errcode = 'P0002';
  end if;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'alert.resolve', 'alert', p_alert_id,
          jsonb_build_object('resolution', p_resolution));
end $$;

create or replace function public.kiosk_start_round(
  actor_staff_id uuid,
  actor_pin text,
  p_shift shift_slot,
  p_second_staff_id uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
  round_id uuid;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  insert into rounds (org_id, branch_id, shift, scheduled_date, started_at,
                      lead_staff_id, second_staff_id)
  values (device.org_id, device.branch_id, p_shift, current_date, now(),
          actor_staff_id, p_second_staff_id)
  on conflict (branch_id, scheduled_date, shift) do update
    set started_at = coalesce(rounds.started_at, excluded.started_at),
        lead_staff_id = coalesce(rounds.lead_staff_id, excluded.lead_staff_id),
        second_staff_id = coalesce(rounds.second_staff_id, excluded.second_staff_id)
  returning id into round_id;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'round.start', 'round', round_id,
          jsonb_build_object('shift', p_shift));
  return round_id;
end $$;

create or replace function public.kiosk_add_round_item(
  actor_staff_id uuid,
  actor_pin text,
  p_round_id uuid,
  p_batch_id uuid,
  p_status round_item_status,
  p_notes text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
  item_id uuid;
  batch batches%rowtype;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  select * into batch from batches
   where id = p_batch_id
     and org_id = device.org_id
     and branch_id = device.branch_id;
  if not found then
    raise exception 'batch not in this branch' using errcode = 'P0002';
  end if;

  insert into round_items (round_id, batch_id, product_id, category_id, status, notes)
  select p_round_id, batch.id, batch.product_id, p.category_id, p_status, p_notes
    from products p where p.id = batch.product_id
  returning id into item_id;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'round_item.add', 'round_item', item_id,
          jsonb_build_object('status', p_status, 'batch_id', p_batch_id));
  return item_id;
end $$;

create or replace function public.kiosk_complete_round(
  actor_staff_id uuid,
  actor_pin text,
  p_round_id uuid,
  p_notes text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  update rounds
     set completed_at = now(),
         notes = coalesce(p_notes, notes)
   where id = p_round_id
     and org_id = device.org_id
     and branch_id = device.branch_id;
  if not found then
    raise exception 'round not in this branch' using errcode = 'P0002';
  end if;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'round.complete', 'round', p_round_id, '{}'::jsonb);
end $$;

create or replace function public.kiosk_log_temp(
  actor_staff_id uuid,
  actor_pin text,
  p_location_label text,
  p_temp_f numeric,
  p_notes text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  device kiosk_devices;
  log_id uuid;
begin
  device := _assert_kiosk_actor(actor_staff_id, actor_pin);

  insert into temp_logs (org_id, branch_id, location_label, temp_f, recorded_by, notes)
  values (device.org_id, device.branch_id, p_location_label, p_temp_f, actor_staff_id, p_notes)
  returning id into log_id;

  insert into audit_log (org_id, branch_id, actor_id, actor_channel, device_id,
                         action, entity_type, entity_id, metadata)
  values (device.org_id, device.branch_id, actor_staff_id, 'kiosk', device.id,
          'temp.log', 'temp_log', log_id,
          jsonb_build_object('location', p_location_label, 'temp_f', p_temp_f));
  return log_id;
end $$;

-- ─────────────────────────────────────────────────────────────
-- Alert evaluator — walks active batches, opens alerts where a
-- category threshold has been crossed and no alert exists yet.
-- Idempotent; safe to call repeatedly. Call it from pg_cron in prod.
-- ─────────────────────────────────────────────────────────────

create or replace function public.refresh_alerts()
returns int
language plpgsql security definer set search_path = public as $$
declare
  inserted_count int := 0;
begin
  if not is_manager_or_admin() and not is_kiosk_device() then
    raise exception 'not permitted' using errcode = '42501';
  end if;

  with candidate as (
    select b.id as batch_id, b.org_id, b.branch_id, t as threshold_days
      from batches b
      join products p on p.id = b.product_id
      join categories c on c.id = p.category_id
      cross join lateral unnest(c.alert_thresholds) as t
     where b.state = 'active'
       and b.quantity_remaining > 0
       and (b.expiry_date - current_date) <= t
  )
  insert into alerts (org_id, branch_id, batch_id, threshold_days)
  select org_id, branch_id, batch_id, threshold_days from candidate
  on conflict (batch_id, threshold_days) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end $$;

-- ─────────────────────────────────────────────────────────────
-- Rev-ops views (RLS applies via underlying tables)
-- ─────────────────────────────────────────────────────────────

create or replace view v_upcoming_shipments as
select po.id, po.org_id, po.branch_id, br.name as branch_name,
       s.name as supplier_name, po.po_number, po.expected_delivery_date, po.status,
       coalesce(sum(pl.quantity_ordered), 0) as units_ordered,
       coalesce(sum(pl.quantity_received), 0) as units_received
  from purchase_orders po
  join branches br on br.id = po.branch_id
  join suppliers s on s.id = po.supplier_id
  left join po_lines pl on pl.po_id = po.id
 where po.status in ('draft', 'sent', 'partial')
   and po.expected_delivery_date is not null
 group by po.id, br.name, s.name;

create or replace view v_stock_by_product as
select b.org_id, b.branch_id, br.name as branch_name,
       p.id as product_id, p.name as product_name, c.name as category_name,
       count(*) filter (where b.state = 'active') as active_batches,
       coalesce(sum(b.quantity_remaining) filter (where b.state = 'active'), 0) as units_on_hand,
       min(b.expiry_date) filter (where b.state = 'active' and b.quantity_remaining > 0) as next_expiry,
       max(b.received_date) as last_received
  from batches b
  join branches br on br.id = b.branch_id
  join products p on p.id = b.product_id
  join categories c on c.id = p.category_id
 group by b.org_id, b.branch_id, br.name, p.id, p.name, c.name;

create or replace view v_supplier_scorecard as
select s.org_id, s.id as supplier_id, s.name as supplier_name,
       count(b.id) as batches_received,
       avg(b.expiry_date - b.received_date)::numeric(10,2) as avg_days_shelf_life_received,
       count(*) filter (where b.expiry_date - b.received_date < 14) as short_dated_batches,
       count(*) filter (where b.state = 'discarded') as discarded_batches,
       coalesce(sum((b.quantity_received - b.quantity_remaining) *
                    coalesce(pr.unit_cost_cents, 0)) filter (where b.state = 'discarded'), 0) / 100.0
         as discarded_cost_dollars
  from suppliers s
  left join batches b on b.supplier_id = s.id
  left join products pr on pr.id = b.product_id
 group by s.org_id, s.id, s.name;

create or replace view v_waste_recovery as
select a.org_id, a.branch_id, br.name as branch_name,
       date_trunc('week', a.resolved_at)::date as week,
       count(*) filter (where a.resolution = 'discounted') as markdown_count,
       count(*) filter (where a.resolution = 'donated')    as donation_count,
       count(*) filter (where a.resolution = 'discarded')  as discard_count,
       count(*) filter (where a.resolution = 'already_sold') as sold_before_expiry_count
  from alerts a
  join branches br on br.id = a.branch_id
 where a.status = 'resolved'
   and a.resolved_at is not null
 group by a.org_id, a.branch_id, br.name, date_trunc('week', a.resolved_at);

create or replace view v_alert_response_times as
select a.org_id, a.branch_id, br.name as branch_name,
       date_trunc('week', a.fired_at)::date as week,
       count(*) as alerts_fired,
       count(*) filter (where a.status = 'resolved') as alerts_resolved,
       avg(extract(epoch from (a.resolved_at - a.fired_at)) / 3600)
         filter (where a.status = 'resolved')::numeric(10,2) as avg_hours_to_resolve
  from alerts a
  join branches br on br.id = a.branch_id
 group by a.org_id, a.branch_id, br.name, date_trunc('week', a.fired_at);

-- ─────────────────────────────────────────────────────────────
-- Grants — RPCs and views are for authenticated sessions only.
-- ─────────────────────────────────────────────────────────────

revoke all on function public.set_staff_pin(uuid, text) from public, anon;
grant execute on function public.set_staff_pin(uuid, text) to authenticated;

revoke all on function public.kiosk_verify_pin(text) from public, anon;
grant execute on function public.kiosk_verify_pin(text) to authenticated;

revoke all on function public._assert_kiosk_actor(uuid, text) from public, anon, authenticated;

revoke all on function public.kiosk_log_batch(uuid, text, uuid, numeric, date, expiry_mode, uuid, text, text, text) from public, anon;
grant execute on function public.kiosk_log_batch(uuid, text, uuid, numeric, date, expiry_mode, uuid, text, text, text) to authenticated;

revoke all on function public.kiosk_resolve_alert(uuid, text, uuid, alert_resolution, text) from public, anon;
grant execute on function public.kiosk_resolve_alert(uuid, text, uuid, alert_resolution, text) to authenticated;

revoke all on function public.kiosk_start_round(uuid, text, shift_slot, uuid) from public, anon;
grant execute on function public.kiosk_start_round(uuid, text, shift_slot, uuid) to authenticated;

revoke all on function public.kiosk_add_round_item(uuid, text, uuid, uuid, round_item_status, text) from public, anon;
grant execute on function public.kiosk_add_round_item(uuid, text, uuid, uuid, round_item_status, text) to authenticated;

revoke all on function public.kiosk_complete_round(uuid, text, uuid, text) from public, anon;
grant execute on function public.kiosk_complete_round(uuid, text, uuid, text) to authenticated;

revoke all on function public.kiosk_log_temp(uuid, text, text, numeric, text) from public, anon;
grant execute on function public.kiosk_log_temp(uuid, text, text, numeric, text) to authenticated;

revoke all on function public.refresh_alerts() from public, anon;
grant execute on function public.refresh_alerts() to authenticated;

grant select on v_upcoming_shipments, v_stock_by_product,
                v_supplier_scorecard, v_waste_recovery, v_alert_response_times
  to authenticated;
