-- Source-only recovery assertions. No real identities or production keys.
create function pg_temp.fail_receiving_audit() returns trigger language plpgsql as $$
begin if new.action='partition_recovered' then raise exception using errcode='PT500',message='Synthetic audit failure';end if;return new;end $$;
do $$ declare r jsonb;lead jsonb;grant_result jsonb;begin
 select response into strict r from receiving_test_session;
 begin
  perform public.recover_receiving_partition_v1((r#>>'{session,id}')::uuid,r#>>'{session,secret}','97000000-0000-4000-8000-000000000002','Synthetic recovery reason');raise exception 'Expected ordinary staff denial';
 exception when insufficient_privilege then null;end;
 lead:=public.begin_staff_session_v1('5678');
 begin perform private.receiving_session((r#>>'{session,id}')::uuid,r#>>'{session,secret}');raise exception 'Expected predecessor revoked';exception when insufficient_privilege then null;end;
 update public.staff_profiles set active=false where id='97000000-0000-4000-8000-000000000002';
 grant_result:=public.recover_receiving_partition_v1((lead#>>'{session,id}')::uuid,lead#>>'{session,secret}','97000000-0000-4000-8000-000000000002','Synthetic recovery reason');
 perform pg_temp.check_receiving(grant_result->>'key_b64'=r#>>'{vault,key_b64}','original partition key retained');
 perform pg_temp.check_receiving(exists(select 1 from private.receiving_identity_audit where recovery_id=(grant_result->>'recovery_id')::uuid),'audit before key release');
 create trigger receiving_test_audit_failure before insert on private.receiving_identity_audit for each row execute function pg_temp.fail_receiving_audit();
 begin
  perform public.recover_receiving_partition_v1((lead#>>'{session,id}')::uuid,lead#>>'{session,secret}','97000000-0000-4000-8000-000000000002','Synthetic failure injection');
  raise exception 'Expected audit failure';
 exception when sqlstate 'PT500' then null;end;
 perform pg_temp.check_receiving((select count(*)=1 from private.receiving_recovery_grants where session_id=(lead#>>'{session,id}')::uuid),'failed audit rolled back recovery grant');
 drop trigger receiving_test_audit_failure on private.receiving_identity_audit;
 update public.staff_profiles set is_shift_lead=false where id='97000000-0000-4000-8000-000000000003';
 begin perform private.receiving_session((lead#>>'{session,id}')::uuid,lead#>>'{session,secret}');raise exception 'Expected lost-lead revocation';exception when insufficient_privilege then null;end;
end $$;
