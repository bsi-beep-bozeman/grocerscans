-- Invoked by receiving_auth_harness.sql only, after R03 approval. NOT EXECUTED.
do $$ declare r jsonb;i integer;blocked timestamptz;begin
 perform pg_temp.check_receiving(public.get_receiving_context_v1()->>'kind'='kiosk','kiosk context');
 for i in 1..5 loop
  r:=public.begin_staff_session_v1('malformed');
  perform pg_temp.check_receiving((r->>'ok')::boolean=false,'malformed denial');
 end loop;
 select blocked_until into blocked from private.receiving_device_attempts where device_id='97000000-0000-4000-8000-000000000012';
 r:=public.begin_staff_session_v1('1234');
 perform pg_temp.check_receiving(r#>>'{error,code}'='cooldown','valid PIN blocked during cooldown');
 perform pg_temp.check_receiving((select failed_count=5 and blocked_until=blocked from private.receiving_device_attempts where device_id='97000000-0000-4000-8000-000000000012'),'counter not extended');
 update private.receiving_device_attempts set blocked_until=clock_timestamp()-interval '1 second' where device_id='97000000-0000-4000-8000-000000000012';
 r:=public.begin_staff_session_v1('1234');
 perform pg_temp.check_receiving((r->>'ok')::boolean,'valid session after cooldown');
 perform pg_temp.check_receiving((r#>>'{session,expires_at}')::timestamptz-(r#>>'{session,issued_at}')::timestamptz=interval '8 hours','absolute lifetime');
 perform pg_temp.check_receiving((select secret_digest=private.receiving_digest(r#>>'{session,secret}') from private.receiving_staff_sessions where id=(r#>>'{session,id}')::uuid),'digest persistence');
 insert into receiving_test_session values(r);
 begin
  perform private.receiving_session((r#>>'{session,id}')::uuid,repeat('x',44));raise exception 'Expected forged secret denial';
 exception when insufficient_privilege then null;end;
end $$;
do $$ declare t text;begin
 foreach t in array array['orgs','branches','staff_profiles','kiosk_devices','categories','suppliers','products','batches','purchase_orders','po_lines','receiving_events','alerts','rounds','round_items','temp_logs','audit_log','supplier_profiles','v_upcoming_shipments','v_stock_by_product','v_supplier_scorecard','v_waste_recovery','v_alert_response_times'] loop
  perform pg_temp.check_receiving(not has_table_privilege('authenticated','public.'||t,'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'),'legacy table closed: '||t);
 end loop;
 perform pg_temp.check_receiving(not has_schema_privilege('authenticated','private','USAGE'),'private schema closed');
 perform pg_temp.check_receiving(has_function_privilege('authenticated','public.get_admin_setup_context()','EXECUTE'),'S1 context retained');
 perform pg_temp.check_receiving(not has_function_privilege('authenticated','public.current_staff()','EXECUTE'),'legacy composite helper closed');
end $$;
