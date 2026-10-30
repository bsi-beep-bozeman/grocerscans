-- BREAKING legacy-client permission restriction. Requires consumer inventory and
-- explicit R03 approval for the exact target. This file has NOT been applied.
revoke all on table public.orgs,public.branches,public.staff_profiles,public.kiosk_devices,
 public.categories,public.suppliers,public.products,public.batches,public.purchase_orders,
 public.po_lines,public.receiving_events,public.alerts,public.rounds,public.round_items,
 public.temp_logs,public.audit_log,public.supplier_profiles,
 public.v_upcoming_shipments,public.v_stock_by_product,public.v_supplier_scorecard,
 public.v_waste_recovery,public.v_alert_response_times from public,anon,authenticated;

-- Every overload of the exact reviewed legacy names; no blanket public-function revoke.
do $$ declare f record; begin
 for f in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname=any(array[
  'current_staff','current_app_role','current_org_id','current_branch_scope','is_admin','is_manager_or_admin','is_kiosk_device','is_supplier','current_supplier_id',
  'set_staff_pin','kiosk_verify_pin','_assert_kiosk_actor','kiosk_log_batch','kiosk_resolve_alert','kiosk_start_round','kiosk_add_round_item','kiosk_complete_round','kiosk_log_temp','refresh_alerts']) loop
  execute format('revoke all on function %s from public,anon,authenticated',f.signature);
 end loop;
 -- Close table-owned sequence alternatives only; retained schema currently uses UUIDs.
 for f in select distinct seq.oid::regclass sequence_name from pg_class seq join pg_depend dep on dep.objid=seq.oid
  join pg_class tbl on tbl.oid=dep.refobjid join pg_namespace n on n.oid=tbl.relnamespace
  where seq.relkind='S' and dep.deptype in ('a','i') and n.nspname='public' and tbl.relname=any(array[
   'orgs','branches','staff_profiles','kiosk_devices','categories','suppliers','products','batches','purchase_orders','po_lines','receiving_events','alerts','rounds','round_items','temp_logs','audit_log','supplier_profiles']) loop
  execute format('revoke all on sequence %s from public,anon,authenticated',f.sequence_name);
 end loop;
end $$;
-- Six guarded S1 entry points remain the supported administrator path.
grant execute on function public.get_admin_setup_context(),public.get_store_setup(uuid),public.save_store_setup(uuid,uuid,integer,jsonb),
 public.activate_store_setup(uuid,uuid,uuid,integer,integer,text),public.mutate_setup_preset(jsonb),public.mutate_setup_location(jsonb) to authenticated;
