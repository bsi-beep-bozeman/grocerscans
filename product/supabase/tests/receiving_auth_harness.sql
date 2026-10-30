-- SOURCE ONLY. Run only after R03 target, fixture and cleanup approval.
-- psql -v ON_ERROR_STOP=1 -f receiving_auth_harness.sql on that exact target.
-- Uses synthetic transaction-local identities; no production credentials.
\set ON_ERROR_STOP on
begin;
create function pg_temp.check_receiving(ok boolean,label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'Receiving assertion failed: %',label;end if;end $$;
insert into auth.users(id) values
 ('97000000-0000-4000-8000-000000000001'),('97000000-0000-4000-8000-000000000002'),('97000000-0000-4000-8000-000000000003');
insert into public.orgs(id,name) values('97000000-0000-4000-8000-000000000010','S2-A synthetic organisation');
insert into public.branches(id,org_id,name,timezone) values('97000000-0000-4000-8000-000000000011','97000000-0000-4000-8000-000000000010','S2-A synthetic branch','Australia/Perth');
insert into public.kiosk_devices(id,org_id,branch_id,device_auth_user_id,label) values
 ('97000000-0000-4000-8000-000000000012','97000000-0000-4000-8000-000000000010','97000000-0000-4000-8000-000000000011','97000000-0000-4000-8000-000000000001','S2-A synthetic device');
-- Fixed bcrypt salt is acceptable only for these synthetic test PINs.
insert into public.staff_profiles(id,org_id,branch_id,display_name,role,is_shift_lead,pin_hash,pin_last_changed_at) values
 ('97000000-0000-4000-8000-000000000002','97000000-0000-4000-8000-000000000010','97000000-0000-4000-8000-000000000011','S2-A synthetic staff','staff',false,private.receiving_crypt('1234','$2a$08$abcdefghijklmnopqrstuu'),clock_timestamp()),
 ('97000000-0000-4000-8000-000000000003','97000000-0000-4000-8000-000000000010','97000000-0000-4000-8000-000000000011','S2-A synthetic lead','staff',true,private.receiving_crypt('5678','$2a$08$abcdefghijklmnopqrstuu'),clock_timestamp());
insert into public.categories(id,org_id,name,expiry_mode) values('97000000-0000-4000-8000-000000000020','97000000-0000-4000-8000-000000000010','S2-A category','printed');
insert into public.products(id,org_id,category_id,name,upc,unit_cost_cents) values
 ('97000000-0000-4000-8000-000000000021','97000000-0000-4000-8000-000000000010','97000000-0000-4000-8000-000000000020','S2-A synthetic item','001234',999);
select set_config('request.jwt.claims',jsonb_build_object('sub','97000000-0000-4000-8000-000000000001','exp',extract(epoch from clock_timestamp()+interval '1 hour'),'role','authenticated')::text,true);
create temporary table receiving_test_session(response jsonb);
\ir receiving_identity.sql
\ir receiving_reads.sql
\ir receiving_recovery.sql
rollback;
-- Rollback here is fixture isolation, not proof of disposable-baseline restoration.
