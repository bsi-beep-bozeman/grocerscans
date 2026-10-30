-- SQL assertions are authored, not executed. Actual Auth/API checks remain separate.
do $$ declare r jsonb;catalog jsonb;policy jsonb;begin
 select response into strict r from receiving_test_session;
 catalog:=public.get_receiving_catalog_v1((r#>>'{session,id}')::uuid,r#>>'{session,secret}','{"kind":"upc","value":"001234"}',null,50);
 perform pg_temp.check_receiving(jsonb_array_length(catalog->'items')=1,'exact leading-zero identifier');
 perform pg_temp.check_receiving(catalog#>>'{items,0,upc}'='001234','identifier preserved');
 perform pg_temp.check_receiving(not(catalog#>'{items,0}'?'unit_cost_cents'),'financial field absent');
 perform pg_temp.check_receiving((select count(*)=7 from jsonb_object_keys(catalog#>'{items,0}')),'exact item field count');
 policy:=public.get_receiving_policy_v1((r#>>'{session,id}')::uuid,r#>>'{session,secret}','97000000-0000-4000-8000-000000000021');
 perform pg_temp.check_receiving(policy->'setup'='null'::jsonb,'missing setup stays null');
 perform pg_temp.check_receiving(policy#>'{readiness,blocking_codes}'?'setup_missing','missing setup disclosed');
 perform pg_temp.check_receiving(policy#>>'{readiness,can_confirm}'='false','confirmation disabled');
 begin perform public.get_receiving_catalog_v1((r#>>'{session,id}')::uuid,r#>>'{session,secret}','{"kind":null,"value":""}',null,50);raise exception 'Expected invalid query';exception when sqlstate 'PT422' then null;end;
end $$;
