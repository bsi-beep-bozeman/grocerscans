-- SOURCE ONLY: deliberately not executed in R01/R02. R03 approval required.
-- Run with psql ON_ERROR_STOP=1 against an approved disposable local database.
-- Every assertion raises on failure; all fixture/data mutations roll back.
begin;
create function pg_temp.assert_true(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'ASSERTION FAILED: %', label; end if; end $$;
create function pg_temp.expect_state(statement text, expected text) returns void language plpgsql as $$
declare actual text;
begin
  begin execute statement; exception when others then get stacked diagnostics actual = returned_sqlstate; end;
  if actual is distinct from expected then raise exception 'Expected %, got % for %', expected, coalesce(actual,'success'), statement; end if;
end $$;
create function pg_temp.assert_active_pair(state jsonb) returns void language plpgsql as $$
begin
 perform pg_temp.assert_true(
  case when state->'active'='null'::jsonb then state->>'active_revision'='0'
   else (state#>>'{active,version}')::integer=(state->>'active_revision')::integer
    and (state->>'active_revision')::integer>0 end,
  'active version and pointer revision share one snapshot');
end $$;
create temp table setup_inventory_before as
select (select count(*) from public.batches) batches,
       (select count(*) from public.alerts) alerts,
       (select count(*) from public.receiving_events) receiving,
       (select count(*) from public.rounds) rounds,
       (select count(*) from public.round_items) items,
       (select count(*) from public.audit_log) audit;
insert into auth.users(id) select ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid from generate_series(1,10) n;
insert into public.orgs(id,name) values ('20000000-0000-0000-0000-000000000001','setup-test A'),('20000000-0000-0000-0000-000000000002','setup-test B');
insert into public.branches(id,org_id,name) values
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','A1'),
('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','A2'),
('30000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000002','B1');
insert into public.staff_profiles(id,org_id,branch_id,display_name,role,pin_hash,active,is_shift_lead)
select ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
 '20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','Test '||n,
 (case n when 2 then 'manager' when 3 then 'staff' when 4 then 'viewer' else 'admin' end)::public.app_role,
 'fixture-not-a-login',n<>5,n=2 from generate_series(1,7) n;
insert into public.suppliers(id,org_id,name) values ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Test supplier');
insert into public.supplier_profiles(id,org_id,supplier_id,display_name) values
 ('10000000-0000-0000-0000-000000000006','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Conflicting admin supplier'),
 ('10000000-0000-0000-0000-000000000008','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Supplier only');
insert into public.kiosk_devices(org_id,branch_id,device_auth_user_id,label) values
 ('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000007','Conflicting admin kiosk'),
 ('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000009','Kiosk only');
insert into public.categories(id,org_id,name,expiry_mode) values
 ('50000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Category A','printed'),
 ('50000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002','Category B','printed');
insert into public.products(id,org_id,name,category_id) values
 ('60000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Product A','50000000-0000-0000-0000-000000000001');
-- Role matrix applies to EVERY public endpoint, including retries.
do $$ declare n int; q text; begin
 for n in 2..10 loop
  perform set_config('request.jwt.claims',jsonb_build_object('sub','10000000-0000-0000-0000-'||lpad(n::text,12,'0'),'exp',extract(epoch from clock_timestamp())+3600)::text,true);
  foreach q in array array[
   'select public.get_admin_setup_context()',
   'select public.get_store_setup(''30000000-0000-0000-0000-000000000001'')',
   'select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000001'',0,''{"schema_version":1}'')',
   'select public.activate_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000002'',0,0,''test'')',
   'select public.mutate_setup_preset(''{}'')', 'select public.mutate_setup_location(''{}'')'
  ] loop perform pg_temp.expect_state(q,'42501'); end loop;
 end loop;
 perform set_config('request.jwt.claims','{}',true);
 perform pg_temp.expect_state('select public.get_admin_setup_context()','42501');
 perform set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","exp":1}',true);
 perform pg_temp.expect_state('select public.get_admin_setup_context()','PT401');
 perform set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001"}',true);
 perform pg_temp.expect_state('select public.get_admin_setup_context()','PT401');
end $$;
select set_config('request.jwt.claims',jsonb_build_object('sub','10000000-0000-0000-0000-000000000001','exp',extract(epoch from clock_timestamp())+3600)::text,true);
select pg_temp.assert_active_pair(public.get_store_setup('30000000-0000-0000-0000-000000000001'));
select pg_temp.expect_state('select public.get_store_setup(''30000000-0000-0000-0000-000000000003'')','42501');
create temp table setup_test_state(value jsonb);
insert into setup_test_state select public.save_store_setup('30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001',0,'{"schema_version":1}');
select pg_temp.assert_true((select value from setup_test_state)=public.save_store_setup('30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001',0,'{"schema_version":1}'),'identical retry response');
select pg_temp.expect_state('select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000001'',0,''{"schema_version":1,"store":{}}'')','PT409');
select pg_temp.expect_state('select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000002'',0,''{"schema_version":1}'')','PT409');
select pg_temp.expect_state('select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000002'',1,''{"schema_version":1,"bindings":[{"category_id":"50000000-0000-0000-0000-000000000002"}]}'')','PT422');
select pg_temp.expect_state('select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000002'',1,''{"schema_version":1,"units":[{"code":"each","precision":1}]}'')','PT422');
select pg_temp.expect_state('select public.activate_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000002'',(select (value#>>''{draft,id}'')::uuid from setup_test_state),1,0,''Incomplete'')','PT422');
-- Invalid values must fail before creating audit or idempotency records.
do $$ declare invalid jsonb; before_audit bigint; before_operations bigint; begin
 select count(*) into before_audit from public.setup_audit;
 select count(*) into before_operations from public.setup_operations;
 for invalid in select value from jsonb_array_elements('[
  {"schema_version":1,"unknown":true},
  {"schema_version":1,"store":{"confirmed":null}},
  {"schema_version":1,"units":[{"code":"each","precision":0.5}]},
  {"schema_version":1,"products":[{"stock_unit":"each","pack_count":1.5}]},
  {"schema_version":1,"restrictions":{"past_date_donation_allowed":true}},
  {"schema_version":1,"bindings":[{"category_id":"not-a-uuid"}]},
  {"schema_version":1,"receiving":{"location_ids":["",""]}}
 ]') loop
  perform pg_temp.expect_state(format('select public.save_store_setup(%L,%L,1,%L)',
   '30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000003',invalid),'PT422');
 end loop;
 perform pg_temp.assert_true(before_audit=(select count(*) from public.setup_audit) and before_operations=(select count(*) from public.setup_operations),'invalid requests are atomic');
 perform pg_temp.assert_true(public._setup_trim(chr(9)||chr(160)||chr(65279))='','Dart whitespace parity');
 -- Revocation must also deny a previously successful operation UUID.
 update public.staff_profiles set active=false where id='10000000-0000-0000-0000-000000000001';
 perform pg_temp.expect_state('select public.save_store_setup(''30000000-0000-0000-0000-000000000001'',''70000000-0000-0000-0000-000000000001'',0,''{"schema_version":1}'')','42501');
 update public.staff_profiles set active=true where id='10000000-0000-0000-0000-000000000001';
end $$;
-- Complete fixture and snapshot assertions follow the source API contract.
do $$ declare loc jsonb; other_loc jsonb; preset jsonb; cfg jsonb; saved jsonb; activated jsonb; snapshot jsonb; begin
 loc:=public.mutate_setup_location('{"operation_id":"70000000-0000-0000-0000-000000000010","action":"create","branch_id":"30000000-0000-0000-0000-000000000001","expected_revision":0,"name":"Receiving","reason":"Fixture"}');
 other_loc:=public.mutate_setup_location('{"operation_id":"70000000-0000-0000-0000-000000000011","action":"create","branch_id":"30000000-0000-0000-0000-000000000002","expected_revision":0,"name":"Other branch","reason":"Fixture"}');
 perform pg_temp.expect_state(format('select public.save_store_setup(%L,%L,1,%L)','30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000012',jsonb_build_object('schema_version',1,'receiving',jsonb_build_object('hold_location_id',(select x->>'id' from jsonb_array_elements(other_loc#>'{catalog,locations}') x where x->>'name'='Other branch')))),'PT422');
 preset:=public.mutate_setup_preset('{"operation_id":"70000000-0000-0000-0000-000000000013","action":"create","expected_revision":0,"name":"Default","reason":"Fixture","policy":{"supplier_requirement":"optional","reference_requirement":"optional","lot_requirement":"optional","entry_modes":["manual"],"label_profile":"manual_only","expiry_mode":"printed"}}');
 cfg:=jsonb_build_object('schema_version',1,'store',jsonb_build_object('display_name','Store','country','AU','region','WA','timezone','Australia/Perth','confirmed',true),'units',jsonb_build_array(jsonb_build_object('code','each','precision',0)),
 'receiving',jsonb_build_object('location_ids',jsonb_build_array(loc#>>'{catalog,locations,0,id}'),'hold_location_id',loc#>>'{catalog,locations,0,id}','exception_role','admin'),
 'bindings',jsonb_build_array(jsonb_build_object('category_id','50000000-0000-0000-0000-000000000001','preset_version_id',preset#>>'{preset_version,id}')),
 'products',jsonb_build_array(jsonb_build_object('product_id','60000000-0000-0000-0000-000000000001','stock_unit','each','pack_name','Single','pack_count',1)));
 saved:=public.save_store_setup('30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000014',1,cfg);
 activated:=public.activate_store_setup('30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000015',(saved#>>'{draft,id}')::uuid,2,0,'Activate fixture');
 perform pg_temp.assert_active_pair(activated);
 perform pg_temp.assert_active_pair(public.get_store_setup('30000000-0000-0000-0000-000000000001'));
 perform pg_temp.assert_true(activated#>'{active,configuration}'=cfg,'active configuration strict DTO');
 perform pg_temp.assert_true(activated=public.activate_store_setup('30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000015',(saved#>>'{draft,id}')::uuid,2,0,'Activate fixture'),'activation retry');
 perform pg_temp.expect_state(format('select public.activate_store_setup(%L,%L,%L,2,0,%L)','30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000016',saved#>>'{draft,id}','stale pointer'),'PT409');
 select reference_snapshot into snapshot from public.store_setup_versions where id=(activated#>>'{active,id}')::uuid;
 perform public.mutate_setup_location(jsonb_build_object('operation_id','70000000-0000-0000-0000-000000000017','action','rename','branch_id','30000000-0000-0000-0000-000000000001','location_id',loc#>>'{catalog,locations,0,id}','expected_revision',1,'name','Renamed','reason','Test history'));
 perform public.mutate_setup_preset(jsonb_build_object('operation_id','70000000-0000-0000-0000-000000000018','action','deactivate','preset_id',preset#>>'{preset_version,preset_id}','expected_revision',1,'reason','Test history'));
 perform pg_temp.assert_true(preset=public.mutate_setup_preset('{"operation_id":"70000000-0000-0000-0000-000000000013","action":"create","expected_revision":0,"name":"Default","reason":"Fixture","policy":{"supplier_requirement":"optional","reference_requirement":"optional","lot_requirement":"optional","entry_modes":["manual"],"label_profile":"manual_only","expiry_mode":"printed"}}'),'preset retry returns original response after deactivation');
 perform pg_temp.assert_true(loc=public.mutate_setup_location('{"operation_id":"70000000-0000-0000-0000-000000000010","action":"create","branch_id":"30000000-0000-0000-0000-000000000001","expected_revision":0,"name":"Receiving","reason":"Fixture"}'),'location retry returns original response after rename');
 perform pg_temp.expect_state(format('select public.activate_store_setup(%L,%L,%L,2,1,%L)','30000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000019',saved#>>'{draft,id}','Deactivated preset'),'PT422');
 perform pg_temp.assert_true(snapshot=(select reference_snapshot from public.store_setup_versions where id=(activated#>>'{active,id}')::uuid),'reference names frozen');
 perform pg_temp.assert_true((select count(*)=1 from public.store_setup_versions where branch_id='30000000-0000-0000-0000-000000000001'),'one version per operation');
 perform pg_temp.expect_state('update public.store_setup_versions set reason=''tamper''','42501');
 perform pg_temp.expect_state('delete from public.setup_audit','42501');
 perform pg_temp.expect_state('update public.setup_preset_versions set policy=''{}''','42501');
 perform pg_temp.expect_state('delete from public.setup_operations','42501');
end $$;
-- Actual database roles must lack direct read/write and helper execution.
do $$ declare created jsonb; edited jsonb; copied jsonb; request jsonb; begin
 request:='{"operation_id":"70000000-0000-0000-0000-000000000020","action":"create","expected_revision":0,"name":"Editable","reason":"Fixture","policy":{}}';
 created:=public.mutate_setup_preset(request);
 perform pg_temp.expect_state(format('select public.mutate_setup_preset(%L)',request||'{"unexpected":true}'::jsonb),'PT409');
 edited:=public.mutate_setup_preset(jsonb_build_object('operation_id','70000000-0000-0000-0000-000000000021','action','edit','preset_id',created#>>'{preset_version,preset_id}','expected_revision',1,'name','Edited','reason','Edit test','policy','{"expiry_mode":"printed"}'::jsonb));
 perform pg_temp.assert_true(edited#>>'{preset_version,version}'='2','edit creates immutable version two');
 perform pg_temp.expect_state(format('select public.mutate_setup_preset(%L)',jsonb_build_object('operation_id','70000000-0000-0000-0000-000000000022','action','edit','preset_id',created#>>'{preset_version,preset_id}','expected_revision',1,'name','Stale','reason','Stale test','policy','{}'::jsonb)),'PT409');
 copied:=public.mutate_setup_preset(jsonb_build_object('operation_id','70000000-0000-0000-0000-000000000023','action','duplicate','preset_id',created#>>'{preset_version,preset_id}','expected_revision',2,'name','Copy','reason','Copy test'));
 perform pg_temp.assert_true(copied#>>'{preset_version,preset_id}'<>created#>>'{preset_version,preset_id}' and copied#>>'{preset_version,version}'='1' and copied#>'{preset_version,policy}'=edited#>'{preset_version,policy}','duplicate starts a new stable preset with copied policy');
 perform pg_temp.assert_true(created#>'{preset_version,policy}'=(select policy from public.setup_preset_versions where id=(created#>>'{preset_version,id}')::uuid),'edit preserves prior preset policy');
end $$;
select pg_temp.assert_true(not has_table_privilege('authenticated','public.store_setup_drafts','SELECT,INSERT,UPDATE,DELETE'),'no authenticated direct access');
select pg_temp.assert_true(not has_table_privilege('anon','public.store_setup_drafts','SELECT,INSERT,UPDATE,DELETE'),'no anonymous direct access');
select pg_temp.assert_true(not has_function_privilege('authenticated','public._setup_actor()','EXECUTE'),'private helper');
-- Exercise privilege denial as the real API roles, not only by catalog lookup.
set local role authenticated;
select pg_temp.expect_state('update public.store_setup_drafts set revision=revision+1','42501');
select pg_temp.expect_state('select public._setup_actor()','42501');
reset role;
set local role anon;
select pg_temp.expect_state('select public.get_admin_setup_context()','42501');
select pg_temp.expect_state('insert into public.setup_locations(org_id,branch_id,name,revision) values(null,null,''denied'',1)','42501');
reset role;
select pg_temp.assert_true(not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname=any(array['store_setup_drafts','store_setup_versions','store_setup_active','setup_presets','setup_preset_versions','setup_locations','setup_operations','setup_audit']) and not c.relrowsecurity),'RLS enabled on every setup table');
select pg_temp.assert_true((select batches=(select count(*) from public.batches) and alerts=(select count(*) from public.alerts) and receiving=(select count(*) from public.receiving_events) and rounds=(select count(*) from public.rounds) and items=(select count(*) from public.round_items) and audit=(select count(*) from public.audit_log) from setup_inventory_before),'inventory and operational audit counts unchanged');
rollback;
