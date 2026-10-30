-- S2-A API source. Not applied or API-tested under R01/R02.
create function public.get_receiving_context_v1() returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare u uuid:=private.receiving_auth();d public.kiosk_devices;b public.branches;
begin
 if exists(select 1 from public.staff_profiles where id=u and active and role='admin') and
  not exists(select 1 from public.kiosk_devices where device_auth_user_id=u) and not exists(select 1 from public.supplier_profiles where id=u) then
  return jsonb_build_object('contract_version',1,'server_time',clock_timestamp(),'kind','admin_setup');
 end if;
 begin d:=private.receiving_device(); exception when insufficient_privilege then
  return jsonb_build_object('contract_version',1,'server_time',clock_timestamp(),'kind','unavailable'); end;
 select * into strict b from public.branches where id=d.branch_id and org_id=d.org_id;
 return jsonb_build_object('contract_version',1,'server_time',clock_timestamp(),'kind','kiosk','org_id',d.org_id,'branch_id',d.branch_id,'branch_name',b.name,'device_id',d.id,'device_label',d.label,'timezone',b.timezone);
end $$;

create function public.begin_staff_session_v1(p_pin text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare d public.kiosk_devices;again public.kiosk_devices;a public.staff_profiles;chosen public.staff_profiles;n integer:=0;
 attempt private.receiving_device_attempts;s private.receiving_staff_sessions;v private.receiving_vault_keys;
 secret text;issued timestamptz;remaining integer;
begin
 begin d:=private.receiving_device(); exception when insufficient_privilege then
  return jsonb_build_object('contract_version',1,'ok',false,'error',jsonb_build_object('code','unavailable','retry_after_seconds',null)); end;
 insert into private.receiving_device_attempts(device_id) values(d.id) on conflict do nothing;
 select * into strict attempt from private.receiving_device_attempts where device_id=d.id for update;
 perform 1 from public.kiosk_devices where id=d.id for share;
 perform 1 from public.staff_profiles where org_id=d.org_id and branch_id=d.branch_id order by id for share;
 again:=private.receiving_device();
 if (again.org_id,again.branch_id,again.id) is distinct from (d.org_id,d.branch_id,d.id) then raise exception using errcode='42501',message='unavailable'; end if;
 if attempt.blocked_until>clock_timestamp() then
  remaining:=ceil(extract(epoch from attempt.blocked_until-clock_timestamp()))::integer;
  return jsonb_build_object('contract_version',1,'ok',false,'error',jsonb_build_object('code','cooldown','retry_after_seconds',greatest(0,remaining)));
 end if;
 if attempt.blocked_until is not null then
  update private.receiving_device_attempts set failed_count=0,blocked_until=null where device_id=d.id;attempt.failed_count:=0;
 end if;
 if p_pin is not null and p_pin~'^[0-9]{4,6}$' then
  for a in select * from public.staff_profiles where org_id=d.org_id and branch_id=d.branch_id and active and role='staff' order by id loop
   if private.receiving_actor_valid(a,d) and a.pin_hash=private.receiving_crypt(p_pin,a.pin_hash) then chosen:=a;n:=n+1;end if;
  end loop;
 end if;
 -- Expected failure returns normally, preserving the durable counter transaction.
 if n<>1 then
  update private.receiving_device_attempts set failed_count=attempt.failed_count+1,
   blocked_until=case when attempt.failed_count+1>=5 then clock_timestamp()+interval '5 minutes' else null end where device_id=d.id;
  return jsonb_build_object('contract_version',1,'ok',false,'error',jsonb_build_object('code',case when attempt.failed_count+1>=5 then 'cooldown' else 'verification_failed' end,'retry_after_seconds',case when attempt.failed_count+1>=5 then 300 else null end));
 end if;
 perform private.receiving_auth();again:=private.receiving_device();
 if not private.receiving_actor_valid(chosen,again) then raise exception using errcode='42501',message='unavailable'; end if;
 issued:=clock_timestamp();secret:=encode(private.receiving_random(32),'base64');
 update private.receiving_device_attempts set failed_count=0,blocked_until=null where device_id=d.id;
 update private.receiving_staff_sessions set revoked_at=issued where device_id=d.id and revoked_at is null;
 insert into private.receiving_staff_sessions(secret_digest,subject_id,org_id,branch_id,device_id,actor_id,pin_changed_at,is_shift_lead,issued_at,expires_at)
 values(private.receiving_digest(secret),private.receiving_auth(),d.org_id,d.branch_id,d.id,chosen.id,chosen.pin_last_changed_at,chosen.is_shift_lead,issued,issued+interval '8 hours') returning * into s;
 insert into private.receiving_vault_keys(org_id,branch_id,device_id,original_actor_id,key_material)
 values(d.org_id,d.branch_id,d.id,chosen.id,private.receiving_random(32)) on conflict(org_id,branch_id,device_id,original_actor_id,key_version) do nothing;
 select * into strict v from private.receiving_vault_keys where org_id=d.org_id and branch_id=d.branch_id and device_id=d.id and original_actor_id=chosen.id and key_version=1 and retired_at is null for share;
 insert into private.receiving_identity_audit(device_id,actor_id,session_id,action) values(d.id,chosen.id,s.id,'session_started');
 perform private.receiving_session(s.id,secret);
 return jsonb_build_object('contract_version',1,'ok',true,'server_time',clock_timestamp(),
  'session',jsonb_build_object('id',s.id,'secret',secret,'issued_at',s.issued_at,'expires_at',s.expires_at),
  'context',jsonb_build_object('org_id',d.org_id,'branch_id',d.branch_id,'device_id',d.id),
  'actor',jsonb_build_object('id',chosen.id,'display_name',chosen.display_name,'is_shift_lead',chosen.is_shift_lead),
  'vault',jsonb_build_object('id',v.id,'key_version',v.key_version,'key_b64',encode(v.key_material,'base64')));
end $$;

create function public.end_staff_session_v1(p_session_id uuid,p_session_secret text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare d public.kiosk_devices;s private.receiving_staff_sessions;
begin
 d:=private.receiving_device();perform 1 from private.receiving_device_attempts where device_id=d.id for update;
 perform 1 from public.kiosk_devices where id=d.id for share;d:=private.receiving_device();
 select * into s from private.receiving_staff_sessions where id=p_session_id and device_id=d.id and subject_id=private.receiving_auth() for update;
 if s.id is null or p_session_secret is null or length(p_session_secret)<>44 or s.secret_digest<>private.receiving_digest(p_session_secret) then raise exception using errcode='42501',message='session_revoked';end if;
 if s.revoked_at is null then
  update private.receiving_staff_sessions set revoked_at=clock_timestamp() where id=s.id;
  insert into private.receiving_identity_audit(device_id,actor_id,session_id,action) values(d.id,s.actor_id,s.id,'session_ended');
 end if;
 return jsonb_build_object('contract_version',1,'ok',true);
end $$;

create function public.recover_receiving_partition_v1(p_session_id uuid,p_session_secret text,p_original_actor_id uuid,p_reason text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s private.receiving_staff_sessions;v private.receiving_vault_keys;g private.receiving_recovery_grants;a public.staff_profiles;t timestamptz;
begin
 s:=private.receiving_session(p_session_id,p_session_secret,p_original_actor_id);
 t:=clock_timestamp();
 if not s.is_shift_lead or s.issued_at+interval '5 minutes'<=t then raise exception using errcode='42501',message='session_revoked';end if;
 if p_reason is null or public._setup_length(public._setup_trim(p_reason)) not between 1 and 1000 then raise exception using errcode='PT422',message='invalid_request';end if;
 select * into a from public.staff_profiles where id=p_original_actor_id;
 if a.id is null or a.org_id<>s.org_id or a.branch_id is distinct from s.branch_id then raise exception using errcode='42501',message='unavailable';end if;
 select * into v from private.receiving_vault_keys where org_id=s.org_id and branch_id=s.branch_id and device_id=s.device_id and original_actor_id=a.id and key_version=1 and retired_at is null for share;
 if v.id is null then raise exception using errcode='42501',message='unavailable';end if;
 s:=private.receiving_session(p_session_id,p_session_secret,p_original_actor_id);t:=clock_timestamp();
 if not s.is_shift_lead or s.issued_at+interval '5 minutes'<=t then raise exception using errcode='42501',message='session_revoked';end if;
 insert into private.receiving_recovery_grants(vault_id,session_id,original_actor_id,recovering_actor_id,reason,issued_at,expires_at)
 values(v.id,s.id,a.id,s.actor_id,public._setup_trim(p_reason),t,least(s.expires_at,t+interval '5 minutes')) returning * into g;
 insert into private.receiving_identity_audit(device_id,actor_id,session_id,recovery_id,action) values(s.device_id,s.actor_id,s.id,g.id,'partition_recovered');
 return jsonb_build_object('recovery_id',g.id,'vault_id',v.id,'key_version',v.key_version,'key_b64',encode(v.key_material,'base64'),'original_actor_id',a.id,'recovering_actor_id',s.actor_id,'granted_at',g.issued_at,'expires_at',g.expires_at);
end $$;

create function private.receiving_product(p_id uuid,p_org uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare result jsonb;
begin
 select jsonb_build_object('id',p.id,'upc',p.upc,'sku',p.sku,'name',p.name,'category_id',c.id,'category_name',c.name,'default_supplier_id',p.default_supplier_id)
 into result from public.products p join public.categories c on c.id=p.category_id and c.org_id=p.org_id
 where p.id=p_id and p.org_id=p_org and (p.default_supplier_id is null or exists(select 1 from public.suppliers where id=p.default_supplier_id and org_id=p.org_id));
 if result is null then raise exception using errcode='PT422',message='invalid_request';end if;
 return result;
end $$;
create function private.receiving_bounded(p_value jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin if octet_length(p_value::text)>262144 then raise exception using errcode='PT422',message='catalog_too_large';end if;return p_value;end $$;

create function public.get_receiving_catalog_v1(p_session_id uuid,p_session_secret text,p_query jsonb,p_after_id uuid default null,p_limit integer default 50) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s private.receiving_staff_sessions;items jsonb:='[]';r record;last_id uuid;more boolean:=false;n integer:=0;active public.store_setup_active;value text;
begin
 s:=private.receiving_session(p_session_id,p_session_secret);
 if p_limit is null or p_limit not between 1 and 100 or jsonb_typeof(p_query) is distinct from 'object' then raise exception using errcode='PT422',message='invalid_request';end if;
 if (select count(*) from jsonb_object_keys(p_query))<>2 or not(p_query?'kind' and p_query?'value') or jsonb_typeof(p_query->'value') is distinct from 'string' or jsonb_typeof(p_query->'kind') is distinct from 'string' then raise exception using errcode='PT422',message='invalid_request';end if;
 value:=p_query->>'value';
 if p_query->>'kind' not in ('upc','sku','name','all') or public._setup_length(value)>128 or
  (p_query->>'kind'='name' and public._setup_length(public._setup_trim(value))<2) or
  (p_query->>'kind'='all' and value<>'') or (p_query->>'kind'<>'all' and value='') then raise exception using errcode='PT422',message='invalid_request';end if;
 for r in select p.id from public.products p where p.org_id=s.org_id and (p_after_id is null or p.id>p_after_id) and
  case p_query->>'kind' when 'upc' then p.upc=value when 'sku' then p.sku=value when 'name' then strpos(lower(p.name),lower(value))>0 when 'all' then true else false end
  order by p.id limit p_limit+1 loop
  n:=n+1;if n>p_limit then more:=true;exit;end if;
  items:=items||jsonb_build_array(private.receiving_product(r.id,s.org_id));last_id:=r.id;
 end loop;
 select * into active from public.store_setup_active where branch_id=s.branch_id and org_id=s.org_id;
 perform private.receiving_session(p_session_id,p_session_secret);
 return private.receiving_bounded(jsonb_build_object('contract_version',1,'server_time',clock_timestamp(),
  'context',jsonb_build_object('org_id',s.org_id,'branch_id',s.branch_id,'device_id',s.device_id),
  'active_setup_version_id',active.version_id,'active_setup_revision',active.revision,'items',items,'next_after_id',case when more then last_id else null end));
end $$;

create function public.get_receiving_policy_v1(p_session_id uuid,p_session_secret text,p_product_id uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s private.receiving_staff_sessions;product jsonb;active public.store_setup_active;cfg jsonb;ps jsonb;binding jsonb;
 preset public.setup_preset_versions;policy jsonb:='{}';setup jsonb;unit jsonb;pack jsonb;receiving jsonb;rule jsonb;
 locations jsonb:='[]';suppliers jsonb:='[]';location_ids jsonb:='[]';hold_id uuid;codes jsonb:='["confirmation_not_implemented"]';k text;identifier text;
begin
 s:=private.receiving_session(p_session_id,p_session_secret);
 -- S1 configuration/reference mutations serialize on the organisation row.
 perform 1 from public.orgs where id=s.org_id for share;
 product:=private.receiving_product(p_product_id,s.org_id);
 select * into active from public.store_setup_active where branch_id=s.branch_id and org_id=s.org_id for share;
 if active.version_id is null then codes:=codes||'"setup_missing"'::jsonb;
 else
  select configuration into cfg from public.store_setup_versions where id=active.version_id and org_id=s.org_id and branch_id=s.branch_id;
  if cfg is null then raise exception using errcode='42501',message='unavailable';end if;
  select value into ps from jsonb_array_elements(coalesce(cfg->'products','[]')) where value->>'product_id'=p_product_id::text;
  select value into binding from jsonb_array_elements(coalesce(cfg->'bindings','[]')) where value->>'category_id'=product->>'category_id';
  select pv.* into preset from public.setup_preset_versions pv join public.setup_presets p on p.id=pv.preset_id and p.org_id=pv.org_id and p.active
   where pv.id=nullif(binding->>'preset_version_id','')::uuid and pv.org_id=s.org_id;
  if binding is not null and preset.id is null then codes:=codes||'"invalid_reference"'::jsonb;end if;
  policy:=coalesce(preset.policy,'{}')||coalesce(ps->'overrides','{}');
  setup:=jsonb_build_object('version_id',active.version_id,'revision',active.revision,'timezone',cfg#>>'{store,timezone}','preset_version_id',preset.id);
  select jsonb_build_object('code',value->>'code','precision',value->'precision') into unit from jsonb_array_elements(coalesce(cfg->'units','[]'))
   where value->>'code'=ps->>'stock_unit' and value?'precision';
  if public._setup_trim(coalesce(ps->>'pack_name',''))<>'' and coalesce((ps->>'pack_count')::numeric,0)>0 then pack:=jsonb_build_object('name',ps->>'pack_name','count',ps->>'pack_count');end if;
  for identifier in select value from jsonb_array_elements_text(coalesce(cfg#>'{receiving,location_ids}','[]')) loop
   if exists(select 1 from public.setup_locations where id=identifier::uuid and org_id=s.org_id and branch_id=s.branch_id and active) then location_ids:=location_ids||to_jsonb(identifier);
   else codes:=codes||'"invalid_reference"'::jsonb;end if;
  end loop;
  identifier:=nullif(cfg#>>'{receiving,hold_location_id}','');
  if identifier is not null then
   select id into hold_id from public.setup_locations where id=identifier::uuid and org_id=s.org_id and branch_id=s.branch_id and active;
   if hold_id is null then codes:=codes||'"invalid_reference"'::jsonb;end if;
  end if;
  receiving:=jsonb_build_object('location_ids',location_ids,'hold_location_id',hold_id,'exception_role',coalesce(cfg#>>'{receiving,exception_role}','unknown'));
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'revision',revision) order by id),'[]') into locations
   from public.setup_locations where org_id=s.org_id and branch_id=s.branch_id and active;
  if (select count(*) from public.suppliers where org_id=s.org_id)>100 then raise exception using errcode='PT422',message='catalog_too_large';end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name) order by id),'[]') into suppliers from public.suppliers where org_id=s.org_id;
 end if;
 if unit is null then codes:=codes||'"unit_missing"'::jsonb;end if;
 if pack is null then codes:=codes||'"pack_missing"'::jsonb;end if;
 foreach k in array array['supplier_requirement','reference_requirement','lot_requirement'] loop
  if coalesce(policy->>k,'unknown')='unknown' then codes:=codes||'"requirement_unknown"'::jsonb;end if;
 end loop;
 if jsonb_array_length(location_ids)=0 then codes:=codes||'"location_missing"'::jsonb;end if;
 if not(coalesce(policy->'entry_modes','[]')?'manual') then codes:=codes||'"unsupported_mode"'::jsonb;end if;
 if public._setup_date_complete(policy->'expiry_rule') then
  rule:=jsonb_build_object('value',policy#>'{expiry_rule,value}','unit',policy#>>'{expiry_rule,unit}','policy_reference',policy#>>'{expiry_rule,policy_reference}');
 end if;
 if coalesce(policy->>'expiry_mode','unknown')='unknown' or (policy->>'expiry_mode'='calculated' and rule is null) then codes:=codes||'"policy_missing"'::jsonb;end if;
 select jsonb_agg(code order by code) into codes from (select distinct value code from jsonb_array_elements(codes)) dedup;
 perform private.receiving_session(p_session_id,p_session_secret);
 return private.receiving_bounded(jsonb_build_object('contract_version',1,'server_time',clock_timestamp(),
  'context',jsonb_build_object('org_id',s.org_id,'branch_id',s.branch_id,'device_id',s.device_id),'product',product,'setup',setup,'unit',unit,'pack',pack,
  'requirements',jsonb_build_object('supplier',coalesce(policy->>'supplier_requirement','unknown'),'reference',coalesce(policy->>'reference_requirement','unknown'),'lot',coalesce(policy->>'lot_requirement','unknown')),
  'entry_modes',coalesce(policy->'entry_modes','[]'),'label_profile',coalesce(policy->>'label_profile','unknown'),
  'expiry',jsonb_build_object('mode',coalesce(policy->>'expiry_mode','unknown'),'rule',rule),'receiving',receiving,'locations',locations,'suppliers',suppliers,
  'readiness',jsonb_build_object('can_capture_draft',true,'can_confirm',false,'blocking_codes',codes)));
end $$;

revoke all on function private.receiving_product(uuid,uuid),private.receiving_bounded(jsonb) from public,anon,authenticated;
revoke all on function public.get_receiving_context_v1(),public.begin_staff_session_v1(text),public.end_staff_session_v1(uuid,text),
 public.recover_receiving_partition_v1(uuid,text,uuid,text),public.get_receiving_catalog_v1(uuid,text,jsonb,uuid,integer),public.get_receiving_policy_v1(uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.get_receiving_context_v1(),public.begin_staff_session_v1(text),public.end_staff_session_v1(uuid,text),
 public.recover_receiving_partition_v1(uuid,text,uuid,text),public.get_receiving_catalog_v1(uuid,text,jsonb,uuid,integer),public.get_receiving_policy_v1(uuid,text,uuid) to authenticated;
