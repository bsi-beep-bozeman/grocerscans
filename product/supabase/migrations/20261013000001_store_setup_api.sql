-- RPC implementation. Every public endpoint reauthorizes before scoped access.
create function public._setup_catalog(o uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare result jsonb; item jsonb; bucket text;
begin
 -- Baseline foreign keys do not enforce matching tenant IDs. Fail closed before
 -- returning any foreign category identifier from an inconsistent legacy row.
 if exists(select 1 from public.products p where p.org_id=o and not exists(
  select 1 from public.categories c where c.id=p.category_id and c.org_id=o
 )) then perform public._setup_invalid('catalog.products.category_id'); end if;
 result:=jsonb_build_object('org_id',o,
 'branches',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'name',name,'active',true,'revision',1) order by id) from public.branches where org_id=o),'[]'),
 'categories',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'name',name,'active',true,'revision',1) order by id) from public.categories where org_id=o),'[]'),
 'products',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'name',name,'category_id',category_id,'active',true,'revision',1) order by id) from public.products where org_id=o),'[]'),
 'presets',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'name',name,'active',active,'revision',revision) order by id) from public.setup_presets where org_id=o),'[]'),
 'preset_versions',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'preset_id',preset_id,'version',version,'policy',policy) order by id) from public.setup_preset_versions where org_id=o),'[]'),
 'locations',coalesce((select jsonb_agg(jsonb_build_object('id',id,'org_id',org_id,'branch_id',branch_id,'name',name,'active',active,'revision',revision) order by id) from public.setup_locations where org_id=o),'[]'));
 foreach bucket in array array['branches','categories','products','presets','locations'] loop
  for item in select value from jsonb_array_elements(result->bucket) loop
   if public._setup_length(item->>'name')>120 then perform public._setup_invalid('catalog.'||bucket||'.name'); end if;
  end loop;
 end loop;
 return result;
end $$;
create function public._setup_reference(cat jsonb,bucket text,ident text,b uuid,path text,branch_scoped boolean default false) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare ref jsonb; reasons jsonb:='[]'; errors jsonb:='[]'; msg text;
begin
 if coalesce(ident,'')='' then reasons:=jsonb_build_array(path||': selection required');
 else
  select value into ref from jsonb_array_elements(cat->bucket) where value->>'id'=ident;
  if ref is null then msg:=path||': unknown reference'; reasons:=jsonb_build_array(msg); errors:=jsonb_build_array(msg);
  else
   if ref->>'org_id'<>cat->>'org_id' then msg:=path||': cross-organisation reference'; reasons:=reasons||jsonb_build_array(msg); errors:=errors||jsonb_build_array(msg); end if;
   if branch_scoped and ref->>'branch_id'<>b::text then msg:=path||': cross-branch reference'; reasons:=reasons||jsonb_build_array(msg); errors:=errors||jsonb_build_array(msg); end if;
   if ref->>'active'='false' then reasons:=reasons||jsonb_build_array(path||': reference is deactivated'); end if;
  end if;
 end if;
 return jsonb_build_object('ref',ref,'reasons',reasons,'errors',errors);
end $$;
create function public._setup_action_references(policy jsonb,cat jsonb,b uuid,path text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a jsonb; k text; result jsonb:='[]'; checked jsonb;
begin
 for a in select value from jsonb_array_elements(coalesce(policy->'actions','[]')) loop
  foreach k in array array['source_location_id','destination_location_id'] loop
   if coalesce(a->>k,'')<>'' then checked:=public._setup_reference(cat,'locations',a->>k,b,path||'.actions.'||coalesce(a->>'action','')||'.'||k,true); result:=result||(checked->'errors'); end if;
  end loop;
 end loop; return result;
end $$;
create function public._setup_date_complete(j jsonb) returns boolean language sql immutable security definer set search_path=pg_catalog,pg_temp as $$
 select coalesce((j->>'value')::numeric>0 and coalesce(j->>'unit','unknown')<>'unknown' and public._setup_trim(coalesce(j->>'policy_reference',''))<>'',false)
$$;
create function public._setup_readiness(cfg jsonb,cat jsonb,b uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare errors jsonb:='[]'; base jsonb:='[]'; products jsonb:='[]'; checked jsonb; k text; ident text;
 binding jsonb; reasons jsonb; version jsonb; versions jsonb:='{}'; binding_reasons jsonb:='{}'; product jsonb;
 category_id text; ref jsonb; inherited jsonb; overrides jsonb; policy jsonb; origins jsonb; unit jsonb;
 action_results jsonb; action jsonb; action_reasons jsonb; action_name text; relationship jsonb; destination_unit jsonb;
begin
 checked:=public._setup_reference(cat,'branches',b::text,b,'branch_id'); base:=base||(checked->'reasons'); errors:=errors||(checked->'errors');
 if coalesce(cfg#>>'{store,confirmed}','false')<>'true' then base:=base||jsonb_build_array('store.confirmed: explicit confirmation required'); end if;
 foreach k in array array['display_name','country','region','timezone'] loop
  if public._setup_trim(coalesce(cfg->'store'->>k,''))='' then base:=base||jsonb_build_array('store.'||k||': required'); end if;
 end loop;
 if jsonb_array_length(coalesce(cfg#>'{receiving,location_ids}','[]'))=0 then base:=base||jsonb_build_array('receiving.location_ids: receiving location required'); end if;
 for ident in select value from jsonb_array_elements_text(coalesce(cfg#>'{receiving,location_ids}','[]')) loop
  checked:=public._setup_reference(cat,'locations',ident,b,'receiving.location_ids',true); base:=base||(checked->'reasons'); errors:=errors||(checked->'errors');
 end loop;
 checked:=public._setup_reference(cat,'locations',cfg#>>'{receiving,hold_location_id}',b,'receiving.hold_location_id',true); base:=base||(checked->'reasons'); errors:=errors||(checked->'errors');
 if coalesce(cfg#>>'{receiving,exception_role}','unknown')='unknown' then base:=base||jsonb_build_array('receiving.exception_role: explicit routing required'); end if;
 for binding in select value from jsonb_array_elements(coalesce(cfg->'bindings','[]')) loop
  checked:=public._setup_reference(cat,'categories',binding->>'category_id',b,'bindings.category_id'); reasons:=checked->'reasons'; errors:=errors||(checked->'errors');
  select value into version from jsonb_array_elements(cat->'preset_versions') where value->>'id'=binding->>'preset_version_id';
  if coalesce(binding->>'preset_version_id','')='' then reasons:=reasons||jsonb_build_array('bindings.preset_version_id: selection required');
  elsif version is null then reasons:=reasons||jsonb_build_array('bindings.preset_version_id: unknown reference'); errors:=errors||jsonb_build_array('bindings.preset_version_id: unknown reference');
  else
   if version->>'org_id'<>cat->>'org_id' then reasons:=reasons||jsonb_build_array('bindings.preset_version_id: cross-organisation reference'); errors:=errors||jsonb_build_array('bindings.preset_version_id: cross-organisation reference'); end if;
   checked:=public._setup_reference(cat,'presets',version->>'preset_id',b,'bindings.preset_id'); reasons:=reasons||(checked->'reasons'); errors:=errors||(checked->'errors');
   versions:=versions||jsonb_build_object(coalesce(binding->>'category_id',''),version);
   errors:=errors||public._setup_action_references(version->'policy',cat,b,'bindings.'||coalesce(binding->>'category_id',''));
  end if;
  binding_reasons:=binding_reasons||jsonb_build_object(coalesce(binding->>'category_id',''),reasons);
 end loop;
 for product in select value from jsonb_array_elements(coalesce(cfg->'products','[]')) loop
  reasons:=base; checked:=public._setup_reference(cat,'products',product->>'product_id',b,'products.product_id');
  reasons:=reasons||(checked->'reasons'); errors:=errors||(checked->'errors'); ref:=nullif(checked->'ref','null'); category_id:=coalesce(ref->>'category_id','');
  if ref is not null then checked:=public._setup_reference(cat,'categories',category_id,b,'products.category_id'); reasons:=reasons||(checked->'reasons'); errors:=errors||(checked->'errors'); end if;
  version:=versions->category_id;
  reasons:=reasons||coalesce(binding_reasons->category_id,'["products.category_id: preset binding required"]');
  inherited:=coalesce(version->'policy','{}'); overrides:=coalesce(product->'overrides','{}'); policy:=inherited||overrides; origins:='{}';
  foreach k in array array['supplier_requirement','reference_requirement','lot_requirement','entry_modes','label_profile','expiry_mode','expiry_rule','actions'] loop
   origins:=origins||jsonb_build_object(k,case when overrides?k then 'product_override' when inherited?k then 'preset' else 'unknown' end);
  end loop;
  errors:=errors||public._setup_action_references(overrides,cat,b,'products.'||coalesce(product->>'product_id','')||'.overrides');
  select value into unit from jsonb_array_elements(coalesce(cfg->'units','[]')) where value->>'code'=product->>'stock_unit';
  if unit is null or coalesce(unit->>'code','')='' or not(unit?'precision') then reasons:=reasons||jsonb_build_array('products.stock_unit: enabled unit with precision required'); end if;
  if public._setup_trim(coalesce(product->>'pack_name',''))='' or coalesce((product->>'pack_count')::numeric,0)<=0 then reasons:=reasons||jsonb_build_array('products.pack: positive pack definition required'); end if;
  foreach k in array array['supplier_requirement','reference_requirement','lot_requirement'] loop
   if coalesce(policy->>k,'unknown')='unknown' then reasons:=reasons||jsonb_build_array('products.'||k||': explicit choice required'); end if;
  end loop;
  if not(coalesce(policy->'entry_modes','[]')?'manual') and not(coalesce(policy->>'label_profile','unknown')='standard_upc_ean' and (coalesce(policy->'entry_modes','[]')?|array['barcode','sku'])) then reasons:=reasons||jsonb_build_array('products.entry_modes: supported label or manual path required'); end if;
  if coalesce(policy->>'expiry_mode','unknown')='unknown' then reasons:=reasons||jsonb_build_array('products.expiry_mode: explicit choice required'); end if;
  if policy->>'expiry_mode'='calculated' and not public._setup_date_complete(policy->'expiry_rule') then reasons:=reasons||jsonb_build_array('products.expiry_rule: positive duration, unit and policy reference required'); end if;
  action_results:='{}';
  foreach action_name in array array['markdown','relabel','donation','discard','freeze','conversion'] loop
   select value into action from jsonb_array_elements(coalesce(policy->'actions','[]')) where value->>'action'=action_name;
   if action is null or coalesce(action->>'state','unknown')='unknown' then
    action_results:=action_results||jsonb_build_object(action_name,jsonb_build_object('reasons',jsonb_build_array('actions.'||action_name||': explicit choice required'),'not_used',false)); continue;
   end if;
   if action->>'state'='not_used' then action_results:=action_results||jsonb_build_object(action_name,jsonb_build_object('reasons','[]'::jsonb,'not_used',true)); continue; end if;
   action_reasons:=reasons;
   if public._setup_trim(coalesce(action->>'policy_reference',''))='' then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.policy_reference: required'); end if;
   if jsonb_array_length(coalesce(action->'prerequisites','[]'))=0 or exists(select 1 from jsonb_array_elements_text(coalesce(action->'prerequisites','[]')) x where public._setup_trim(x)='') then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.prerequisites: required'); end if;
   checked:=public._setup_reference(cat,'locations',action->>'source_location_id',b,'actions.'||action_name||'.source_location_id',true); action_reasons:=action_reasons||(checked->'reasons'); errors:=errors||(checked->'errors');
   if not(action?'label_required') then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.label_required: explicit choice required'); end if;
   if action->>'label_required'='true' and coalesce(policy->>'label_profile','unknown') not in ('standard_upc_ean','manual_only') then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.label_required: supported label profile required'); end if;
   if action_name in ('freeze','conversion') then
    checked:=public._setup_reference(cat,'locations',action->>'destination_location_id',b,'actions.'||action_name||'.destination_location_id',true); action_reasons:=action_reasons||(checked->'reasons'); errors:=errors||(checked->'errors');
    relationship:=action->'quantity_relationship';
    if product->>'stock_unit'='each' and coalesce((relationship->>'source_quantity')::numeric%1,0)<>0 then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.source_quantity: each requires a whole quantity'); end if;
    if coalesce((relationship->>'source_quantity')::numeric,0)<=0 or coalesce((relationship->>'destination_quantity')::numeric,0)<=0 or coalesce(relationship->>'destination_unit','')='' then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.quantity_relationship: explicit positive source/destination quantities and unit required'); end if;
    select value into destination_unit from jsonb_array_elements(coalesce(cfg->'units','[]')) where value->>'code'=relationship->>'destination_unit';
    if destination_unit is null or not(destination_unit?'precision') then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.destination_unit: enabled unit with precision required'); end if;
    if relationship->>'destination_unit'='each' and coalesce((relationship->>'destination_quantity')::numeric%1,0)<>0 then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.destination_quantity: each requires a whole quantity'); end if;
    if not public._setup_date_complete(action->'resulting_date_rule') then action_reasons:=action_reasons||jsonb_build_array('actions.'||action_name||'.resulting_date_rule: explicit positive duration, unit and policy reference required'); end if;
   elsif coalesce(action->>'destination_location_id','')<>'' then
    checked:=public._setup_reference(cat,'locations',action->>'destination_location_id',b,'actions.'||action_name||'.destination_location_id',true); action_reasons:=action_reasons||(checked->'reasons'); errors:=errors||(checked->'errors');
   end if;
   action_results:=action_results||jsonb_build_object(action_name,jsonb_build_object('reasons',action_reasons,'not_used',false));
  end loop;
  products:=products||jsonb_build_array(jsonb_build_object('product_id',coalesce(product->>'product_id',''),'effective',jsonb_build_object('policy',policy,'origins',origins),'receiving',jsonb_build_object('reasons',reasons,'not_used',false),'actions',action_results));
 end loop;
 select coalesce(jsonb_agg(value order by first_seen),'[]') into errors from (select value,min(ord) first_seen from jsonb_array_elements(errors) with ordinality e(value,ord) group by value) e;
 return jsonb_build_object('errors',errors,'products',products);
end $$;

create function public._setup_history(o uuid,b uuid default null) returns jsonb language sql security definer set search_path=pg_catalog,pg_temp as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'operation_id',operation_id,'actor_id',actor_id,'action',action,'target_id',target_id,'occurred_at',occurred_at,'reason',reason,'revision',revision) order by occurred_at,id),'[]')
 from (select * from public.setup_audit where org_id=o and (b is null or branch_id=b) order by occurred_at desc,id desc limit 100) recent
$$;
create function public._setup_state(o uuid,b uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare draft public.store_setup_drafts; active public.store_setup_versions; active_state record; rev integer; cat jsonb; readiness jsonb;
begin
 perform public._setup_branch(o,b);
 select * into draft from public.store_setup_drafts where org_id=o and branch_id=b;
 -- One statement snapshot keeps the version and pointer revision paired even
 -- when a concurrent first activation commits during this read-only RPC.
 select v as version_record,a.revision as pointer_revision into active_state
 from public.store_setup_active a join public.store_setup_versions v
  on v.id=a.version_id and v.branch_id=a.branch_id and v.org_id=a.org_id
 where a.org_id=o and a.branch_id=b;
 active:=active_state.version_record; rev:=active_state.pointer_revision;
 cat:=public._setup_catalog(o);
 if draft.id is not null then readiness:=public._setup_readiness(draft.configuration,cat,b); elsif active.id is not null then readiness:=active.readiness; end if;
 return jsonb_build_object('branch_id',b,'draft',case when draft.id is null then null else jsonb_build_object('id',draft.id,'branch_id',b,'revision',draft.revision,'configuration',draft.configuration,'saved_at',draft.saved_at) end,
 'active',case when active.id is null then null else jsonb_build_object('id',active.id,'branch_id',b,'version',active.version,'configuration',active.configuration,'activated_at',active.activated_at,'reason',active.reason) end,
 'active_revision',coalesce(rev,0),'catalog',cat,'history',public._setup_history(o,b),'readiness',readiness);
end $$;
create function public._setup_retry(o uuid,a uuid,op uuid,request jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare prior public.setup_operations;
begin
 if op is null then perform public._setup_invalid('operation_id'); end if;
 select * into prior from public.setup_operations where org_id=o and actor_id=a and operation_id=op;
 if found then
  if prior.fingerprint<>request then raise exception using errcode='PT409',message='Operation UUID reused with different action or payload'; end if;
  return prior.response;
 end if; return null;
end $$;
create function public._setup_audit(o uuid,b uuid,a uuid,op uuid,action_name text,target uuid,rev integer,reason_text text,snap jsonb) returns void language sql security definer set search_path=pg_catalog,pg_temp as $$
 insert into public.setup_audit(org_id,branch_id,actor_id,operation_id,action,target_id,revision,reason,snapshot) values(o,b,a,op,action_name,target,rev,reason_text,snap)
$$;
create function public._setup_reason(reason_text text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin if reason_text is null or public._setup_trim(reason_text)='' or public._setup_length(reason_text)>2000 then perform public._setup_invalid('reason'); end if; end $$;

create function public.get_admin_setup_context() returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles;
begin
 a:=public._setup_actor();
 return jsonb_build_object('admin_id',a.id,'org_id',a.org_id,'session_expires_at',to_timestamp((auth.jwt()->>'exp')::double precision),'catalog',public._setup_catalog(a.org_id));
end $$;
create function public.get_store_setup(p_branch_id uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles;
begin a:=public._setup_actor(); perform public._setup_branch(a.org_id,p_branch_id); return public._setup_state(a.org_id,p_branch_id); end $$;
create function public.save_store_setup(p_branch_id uuid,p_operation_id uuid,p_expected_revision integer,p_configuration jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles; request jsonb; result jsonb; draft public.store_setup_drafts; readiness jsonb;
begin
 a:=public._setup_lock(); perform public._setup_branch(a.org_id,p_branch_id);
 request:=jsonb_build_object('action','save_store_setup','branch_id',p_branch_id,'operation_id',p_operation_id,'expected_revision',p_expected_revision,'configuration',p_configuration);
 result:=public._setup_retry(a.org_id,a.id,p_operation_id,request); if result is not null then return result; end if;
 if p_expected_revision is null or p_expected_revision<0 then perform public._setup_invalid('expected_revision'); end if;
 perform public._setup_configuration(p_configuration);
 readiness:=public._setup_readiness(p_configuration,public._setup_catalog(a.org_id),p_branch_id);
 if jsonb_array_length(readiness->'errors')<>0 then raise exception using errcode='PT422',message='Invalid configuration references',detail=(readiness->'errors')::text; end if;
 select * into draft from public.store_setup_drafts where org_id=a.org_id and branch_id=p_branch_id for update;
 if coalesce(draft.revision,0)<>p_expected_revision then raise exception using errcode='PT409',message='Draft revision changed'; end if;
 if draft.id is null then
  insert into public.store_setup_drafts(org_id,branch_id,revision,configuration) values(a.org_id,p_branch_id,1,p_configuration) returning * into draft;
 else
  update public.store_setup_drafts set configuration=p_configuration,revision=revision+1,saved_at=clock_timestamp() where id=draft.id returning * into draft;
 end if;
 perform public._setup_audit(a.org_id,p_branch_id,a.id,p_operation_id,'save_store_setup',draft.id,draft.revision,'',jsonb_build_object('configuration',draft.configuration,'readiness',readiness));
 result:=public._setup_state(a.org_id,p_branch_id);
 insert into public.setup_operations(org_id,actor_id,operation_id,fingerprint,response) values(a.org_id,a.id,p_operation_id,request,result);
 return result;
end $$;
create function public.activate_store_setup(p_branch_id uuid,p_operation_id uuid,p_draft_id uuid,p_expected_draft_revision integer,p_expected_active_revision integer,p_reason text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles; request jsonb; result jsonb; draft public.store_setup_drafts; pointer public.store_setup_active; cat jsonb; readiness jsonb; version_id uuid; next_revision integer;
begin
 a:=public._setup_lock(); perform public._setup_branch(a.org_id,p_branch_id);
 request:=jsonb_build_object('action','activate_store_setup','branch_id',p_branch_id,'operation_id',p_operation_id,'draft_id',p_draft_id,'expected_draft_revision',p_expected_draft_revision,'expected_active_revision',p_expected_active_revision,'reason',p_reason);
 result:=public._setup_retry(a.org_id,a.id,p_operation_id,request); if result is not null then return result; end if;
 perform public._setup_reason(p_reason);
 if p_draft_id is null or p_expected_draft_revision is null or p_expected_draft_revision<0 or p_expected_active_revision is null or p_expected_active_revision<0 then perform public._setup_invalid('activation revisions'); end if;
 select * into draft from public.store_setup_drafts where org_id=a.org_id and branch_id=p_branch_id for update;
 select * into pointer from public.store_setup_active where org_id=a.org_id and branch_id=p_branch_id for update;
 if draft.id is distinct from p_draft_id or draft.revision is distinct from p_expected_draft_revision or coalesce(pointer.revision,0)<>p_expected_active_revision then raise exception using errcode='PT409',message='Draft or active revision changed'; end if;
 perform public._setup_configuration(draft.configuration); cat:=public._setup_catalog(a.org_id); readiness:=public._setup_readiness(draft.configuration,cat,p_branch_id);
 if jsonb_array_length(readiness->'errors')<>0 or not exists(
  select 1 from jsonb_array_elements(readiness->'products') p where p#>'{receiving,reasons}'='[]'::jsonb or exists(select 1 from jsonb_each(p->'actions') ac where ac.value->>'not_used'='false' and ac.value->'reasons'='[]'::jsonb)
 ) then raise exception using errcode='PT422',message='At least one capability must be configuration ready',detail=readiness::text; end if;
 next_revision:=coalesce(pointer.revision,0)+1;
 insert into public.store_setup_versions(org_id,branch_id,version,configuration,reference_snapshot,readiness,reason,actor_id)
 values(a.org_id,p_branch_id,next_revision,draft.configuration,jsonb_build_object('catalog',cat,'effective_products',readiness->'products',
  'preset_version_names',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'description',v.description) order by v.id) from public.setup_preset_versions v where v.org_id=a.org_id),'[]')),
  readiness,p_reason,a.id) returning id into version_id;
 insert into public.store_setup_active(branch_id,org_id,version_id,revision) values(p_branch_id,a.org_id,version_id,next_revision)
 on conflict(branch_id) do update set version_id=excluded.version_id,revision=excluded.revision;
 perform public._setup_audit(a.org_id,p_branch_id,a.id,p_operation_id,'activate_store_setup',version_id,next_revision,p_reason,jsonb_build_object('configuration',draft.configuration,'catalog',cat,'readiness',readiness));
 result:=public._setup_state(a.org_id,p_branch_id);
 insert into public.setup_operations(org_id,actor_id,operation_id,fingerprint,response) values(a.org_id,a.id,p_operation_id,request,result);
 return result;
end $$;

-- Validate only routing/authority fields before retry lookup. Other changed
-- payload fields must produce an operation conflict before content validation.
create function public._setup_mutation_scope(j jsonb,kind text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare k text;
begin
 if jsonb_typeof(j) is distinct from 'object' then perform public._setup_invalid('request'); end if;
 perform public._setup_text(j,'action','request',120,case when kind='preset' then array['create','edit','duplicate','deactivate'] else array['create','rename','deactivate'] end);
 if not(j?'action') then perform public._setup_invalid('request.action'); end if;
 foreach k in array array['operation_id',case when j->>'action'<>'create' then kind||'_id' else 'operation_id' end,case when kind='location' then 'branch_id' else 'operation_id' end] loop
  perform public._setup_text(j,k,'request',120,null,true);
  if coalesce(j->>k,'')='' then perform public._setup_invalid('request.'||k); end if;
 end loop;
end $$;
create function public._setup_mutation_request(j jsonb,kind text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare action_name text; id_key text:=kind||'_id'; k text;
begin
 perform public._setup_object(j,case when kind='preset' then array['operation_id','action','preset_id','expected_revision','name','description','policy','reason'] else array['operation_id','action','branch_id','location_id','expected_revision','name','reason'] end,'request');
 foreach k in array array['operation_id',id_key] loop perform public._setup_text(j,k,'request',120,null,true); end loop;
 perform public._setup_text(j,'action','request',120,case when kind='preset' then array['create','edit','duplicate','deactivate'] else array['create','rename','deactivate'] end);
 if not(j?'action') or coalesce(j->>'operation_id','')='' or not(j?'expected_revision') then perform public._setup_invalid('request required fields'); end if;
 perform public._setup_number(j,'expected_revision','request',true,2147483647);
 perform public._setup_text(j,'reason','request',2000); perform public._setup_reason(j->>'reason');
 perform public._setup_text(j,'name','request'); action_name:=j->>'action';
 if action_name='create' then
  if j?id_key or j->>'expected_revision'<>'0' then perform public._setup_invalid('create revision/id'); end if;
 elsif coalesce(j->>id_key,'')='' then perform public._setup_invalid(id_key); end if;
 if action_name='deactivate' then
  if j?'name' or j?'description' or j?'policy' then perform public._setup_invalid('deactivate edits'); end if;
 elsif public._setup_trim(coalesce(j->>'name',''))='' then perform public._setup_invalid('name'); end if;
 if kind='location' then
  perform public._setup_text(j,'branch_id','request',120,null,true);
  if coalesce(j->>'branch_id','')='' then perform public._setup_invalid('branch_id'); end if;
 else
  perform public._setup_text(j,'description','request',2000);
  if j?'policy' then perform public._setup_policy(j->'policy','policy'); end if;
  if action_name in ('create','edit') and not(j?'policy') then perform public._setup_invalid('policy'); end if;
 end if;
end $$;
create function public.mutate_setup_preset(p_request jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles; request jsonb; result jsonb; op uuid; action_name text; preset public.setup_presets; source_version public.setup_preset_versions; new_version public.setup_preset_versions; policy jsonb; target uuid; next_revision integer; desc_text text;
begin
 a:=public._setup_lock(); perform public._setup_mutation_scope(p_request,'preset');
 op:=(p_request->>'operation_id')::uuid; action_name:=p_request->>'action'; request:=jsonb_build_object('action','mutate_setup_preset','request',p_request);
 -- Scope authorization precedes retry lookup even when the response is cached.
 if action_name<>'create' then
  select * into preset from public.setup_presets where id=(p_request->>'preset_id')::uuid and org_id=a.org_id for update;
  if not found then raise exception using errcode='42501',message='Preset unavailable'; end if;
 end if;
 result:=public._setup_retry(a.org_id,a.id,op,request); if result is not null then return result; end if;
 perform public._setup_mutation_request(p_request,'preset');
 if action_name<>'create' and preset.revision<>(p_request->>'expected_revision')::integer then raise exception using errcode='PT409',message='Preset revision changed'; end if;
 if action_name<>'create' and not preset.active then raise exception using errcode='PT409',message='Preset deactivated'; end if;
 if action_name='deactivate' then
  update public.setup_presets set active=false,revision=revision+1 where id=preset.id returning * into preset; target:=preset.id; next_revision:=preset.revision;
 else
  if action_name='duplicate' then
   select * into strict source_version from public.setup_preset_versions where preset_id=preset.id order by version desc fetch first row only;
   policy:=coalesce(p_request->'policy',source_version.policy); desc_text:=coalesce(p_request->>'description',preset.description);
  else policy:=p_request->'policy'; desc_text:=coalesce(p_request->>'description',case when action_name='edit' then preset.description else '' end); end if;
  -- Preset locations may span the organisation; branch applicability is checked on binding/activation.
  if exists(select 1 from jsonb_array_elements(coalesce(policy->'actions','[]')) ac cross join lateral (values(ac->>'source_location_id'),(ac->>'destination_location_id')) refs(id)
   where coalesce(refs.id,'')<>'' and not exists(select 1 from public.setup_locations l where l.id::text=refs.id and l.org_id=a.org_id)) then perform public._setup_invalid('policy location reference'); end if;
  if action_name in ('create','duplicate') then
   insert into public.setup_presets(org_id,name,description,revision) values(a.org_id,p_request->>'name',desc_text,1) returning * into preset;
  else update public.setup_presets set name=p_request->>'name',description=desc_text,revision=revision+1 where id=preset.id returning * into preset; end if;
  target:=preset.id; next_revision:=preset.revision;
  insert into public.setup_preset_versions(preset_id,org_id,version,name,description,policy) values(target,a.org_id,next_revision,preset.name,preset.description,policy) returning * into new_version;
 end if;
 perform public._setup_audit(a.org_id,null,a.id,op,'preset_'||action_name,target,next_revision,p_request->>'reason',jsonb_build_object('preset',to_jsonb(preset),'version',to_jsonb(new_version)));
 result:=jsonb_build_object('catalog',public._setup_catalog(a.org_id),'history',public._setup_history(a.org_id));
 if new_version.id is not null then result:=result||jsonb_build_object('preset_version',jsonb_build_object('id',new_version.id,'preset_id',new_version.preset_id,'org_id',new_version.org_id,'version',new_version.version,'policy',new_version.policy)); end if;
 insert into public.setup_operations(org_id,actor_id,operation_id,fingerprint,response) values(a.org_id,a.id,op,request,result);
 return result;
end $$;
create function public.mutate_setup_location(p_request jsonb) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles; request jsonb; result jsonb; op uuid; action_name text; b uuid; location public.setup_locations;
begin
 a:=public._setup_lock(); perform public._setup_mutation_scope(p_request,'location');
 op:=(p_request->>'operation_id')::uuid; b:=(p_request->>'branch_id')::uuid; action_name:=p_request->>'action'; perform public._setup_branch(a.org_id,b);
 request:=jsonb_build_object('action','mutate_setup_location','request',p_request);
 if action_name<>'create' then
  select * into location from public.setup_locations where id=(p_request->>'location_id')::uuid and org_id=a.org_id and branch_id=b for update;
  if not found then raise exception using errcode='42501',message='Location unavailable'; end if;
 end if;
 result:=public._setup_retry(a.org_id,a.id,op,request); if result is not null then return result; end if;
 perform public._setup_mutation_request(p_request,'location');
 if action_name<>'create' and location.revision<>(p_request->>'expected_revision')::integer then raise exception using errcode='PT409',message='Location revision changed'; end if;
 if action_name<>'create' and not location.active then raise exception using errcode='PT409',message='Location deactivated'; end if;
 if action_name='create' then
  insert into public.setup_locations(org_id,branch_id,name,revision) values(a.org_id,b,p_request->>'name',1) returning * into location;
 elsif action_name='rename' then
  update public.setup_locations set name=p_request->>'name',revision=revision+1 where id=location.id returning * into location;
 else update public.setup_locations set active=false,revision=revision+1 where id=location.id returning * into location; end if;
 perform public._setup_audit(a.org_id,b,a.id,op,'location_'||action_name,location.id,location.revision,p_request->>'reason',to_jsonb(location));
 result:=jsonb_build_object('catalog',public._setup_catalog(a.org_id),'history',public._setup_history(a.org_id));
 insert into public.setup_operations(org_id,actor_id,operation_id,fingerprint,response) values(a.org_id,a.id,op,request,result);
 return result;
end $$;

do $$ declare f record; begin
 for f in select p.oid::regprocedure sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and (p.proname like '\_setup\_%' escape '\' or p.proname=any(array['get_admin_setup_context','get_store_setup','save_store_setup','activate_store_setup','mutate_setup_preset','mutate_setup_location'])) loop
  execute format('revoke all on function %s from public,anon,authenticated',f.sig);
 end loop;
end $$;
grant execute on function public.get_admin_setup_context(),public.get_store_setup(uuid),public.save_store_setup(uuid,uuid,integer,jsonb),public.activate_store_setup(uuid,uuid,uuid,integer,integer,text),public.mutate_setup_preset(jsonb),public.mutate_setup_location(jsonb) to authenticated;
