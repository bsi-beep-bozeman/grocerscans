create or replace function public.get_receiving_policy_v1(p_session_id uuid,p_session_secret text,p_product_id uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s private.receiving_staff_sessions;product jsonb;active_setup public.store_setup_active;cfg jsonb;ps jsonb;binding jsonb;
 preset public.setup_preset_versions;policy jsonb:='{}';setup jsonb;unit jsonb;pack jsonb;receiving jsonb;rule jsonb;
 locations jsonb:='[]';suppliers jsonb:='[]';location_ids jsonb:='[]';hold_id uuid;codes jsonb:='["confirmation_not_implemented"]';k text;identifier text;
begin
 s:=private.receiving_session(p_session_id,p_session_secret);
 -- S1 configuration/reference mutations serialize on the organisation row.
 perform 1 from public.orgs where id=s.org_id for share;
 product:=private.receiving_product(p_product_id,s.org_id);
 select * into active_setup from public.store_setup_active where branch_id=s.branch_id and org_id=s.org_id for share;
 if active_setup.version_id is null then codes:=codes||'"setup_missing"'::jsonb;
 else
  select configuration into cfg from public.store_setup_versions where id=active_setup.version_id and org_id=s.org_id and branch_id=s.branch_id;
  if cfg is null then raise exception using errcode='42501',message='unavailable';end if;
  select value into ps from jsonb_array_elements(coalesce(cfg->'products','[]')) where value->>'product_id'=p_product_id::text;
  select value into binding from jsonb_array_elements(coalesce(cfg->'bindings','[]')) where value->>'category_id'=product->>'category_id';
  select pv.* into preset from public.setup_preset_versions pv join public.setup_presets p on p.id=pv.preset_id and p.org_id=pv.org_id and p.active
   where pv.id=nullif(binding->>'preset_version_id','')::uuid and pv.org_id=s.org_id;
  if binding is not null and preset.id is null then codes:=codes||'"invalid_reference"'::jsonb;end if;
  policy:=coalesce(preset.policy,'{}')||coalesce(ps->'overrides','{}');
  setup:=jsonb_build_object('version_id',active_setup.version_id,'revision',active_setup.revision,'timezone',cfg#>>'{store,timezone}','preset_version_id',preset.id);
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
