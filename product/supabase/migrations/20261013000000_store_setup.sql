-- Administrator setup source. Additive; no inventory writes or default activation.
create table public.store_setup_drafts (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.orgs(id),
 branch_id uuid not null unique references public.branches(id), revision integer not null check(revision>0),
 configuration jsonb not null, saved_at timestamptz not null default clock_timestamp()
);
create table public.store_setup_versions (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.orgs(id),
 branch_id uuid not null references public.branches(id), version integer not null check(version>0),
 configuration jsonb not null, reference_snapshot jsonb not null, readiness jsonb not null,
 activated_at timestamptz not null default clock_timestamp(), reason text not null, actor_id uuid not null references auth.users(id),
 unique(branch_id,version), unique(branch_id,id)
);
create table public.store_setup_active (
 branch_id uuid primary key references public.branches(id), org_id uuid not null references public.orgs(id),
 version_id uuid not null, revision integer not null check(revision>0),
 foreign key(branch_id,version_id) references public.store_setup_versions(branch_id,id)
);
create table public.setup_presets (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.orgs(id),
 name text not null, description text not null default '', active boolean not null default true,
 revision integer not null check(revision>0)
);
create table public.setup_preset_versions (
 id uuid primary key default gen_random_uuid(), preset_id uuid not null references public.setup_presets(id),
 org_id uuid not null references public.orgs(id), version integer not null check(version>0),
 name text not null, description text not null, policy jsonb not null,
 created_at timestamptz not null default clock_timestamp(), unique(preset_id,version)
);
create table public.setup_locations (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.orgs(id),
 branch_id uuid not null references public.branches(id), name text not null,
 active boolean not null default true, revision integer not null check(revision>0)
);
create table public.setup_operations (
 org_id uuid not null references public.orgs(id), actor_id uuid not null references auth.users(id), operation_id uuid not null,
 fingerprint jsonb not null, response jsonb not null, created_at timestamptz not null default clock_timestamp(),
 primary key(org_id,actor_id,operation_id)
);
create table public.setup_audit (
 id uuid primary key default gen_random_uuid(), org_id uuid not null references public.orgs(id), branch_id uuid references public.branches(id),
 operation_id uuid not null, actor_id uuid not null references auth.users(id), action text not null, target_id uuid not null,
 occurred_at timestamptz not null default clock_timestamp(), reason text not null, revision integer not null,
 snapshot jsonb not null
);
create index setup_audit_scope on public.setup_audit(org_id,branch_id,occurred_at);
create index setup_presets_scope on public.setup_presets(org_id);
create index setup_locations_scope on public.setup_locations(org_id,branch_id);
create index setup_preset_versions_scope on public.setup_preset_versions(org_id);

create function public._setup_immutable() returns trigger language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin raise exception using errcode='42501',message='Setup history is append-only'; end $$;
create trigger setup_versions_immutable before update or delete on public.store_setup_versions for each row execute function public._setup_immutable();
create trigger setup_preset_versions_immutable before update or delete on public.setup_preset_versions for each row execute function public._setup_immutable();
create trigger setup_operations_immutable before update or delete on public.setup_operations for each row execute function public._setup_immutable();
create trigger setup_audit_immutable before update or delete on public.setup_audit for each row execute function public._setup_immutable();

do $$ declare t text; begin
 foreach t in array array['store_setup_drafts','store_setup_versions','store_setup_active','setup_presets','setup_preset_versions','setup_locations','setup_operations','setup_audit'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on table public.%I from public, anon, authenticated',t);
 end loop;
end $$;
revoke all on function public._setup_immutable() from public,anon,authenticated;

-- All authority comes from auth.uid(); JWT role/organisation claims are never trusted.
create function public._setup_actor() returns public.staff_profiles language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare u uuid:=auth.uid(); a public.staff_profiles; n integer; exp_value numeric;
begin
 if u is null then raise exception using errcode='42501',message='Administrator required'; end if;
 if jsonb_typeof(auth.jwt()->'exp') is distinct from 'number' then raise exception using errcode='PT401',message='Session expiry required'; end if;
 exp_value:=(auth.jwt()->>'exp')::numeric;
 if exp_value<=extract(epoch from clock_timestamp()) or exp_value>253402300799 then raise exception using errcode='PT401',message='Session expired or invalid'; end if;
 select count(*) into n from public.staff_profiles where id=u and active and role='admin';
 if n<>1 or exists(select 1 from public.supplier_profiles where id=u and active) or exists(select 1 from public.kiosk_devices where device_auth_user_id=u and active) then
  raise exception using errcode='42501',message='Unambiguous active administrator required';
 end if;
 select * into strict a from public.staff_profiles where id=u and active and role='admin';
 return a;
end $$;
create function public._setup_lock() returns public.staff_profiles language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare a public.staff_profiles; checked public.staff_profiles;
begin
 a:=public._setup_actor();
 perform 1 from public.orgs where id=a.org_id for update;
 if not found then raise exception using errcode='42501',message='Organisation unavailable'; end if;
 -- Waiting for a competing mutation cannot preserve an expired/revoked session.
 checked:=public._setup_actor();
 if checked.org_id<>a.org_id then raise exception using errcode='42501',message='Organisation changed'; end if;
 return checked;
end $$;
create function public._setup_branch(o uuid,b uuid) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin if b is null or not exists(select 1 from public.branches where id=b and org_id=o) then raise exception using errcode='42501',message='Branch unavailable'; end if; end $$;
create function public._setup_invalid(path text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin raise exception using errcode='PT422',message='Invalid setup field: '||path; end $$;
-- Dart counts UTF-16 code units, whereas PostgreSQL length counts code points.
create function public._setup_length(s text) returns integer language sql immutable security definer set search_path=pg_catalog,pg_temp as $$
 select coalesce(sum(case when ascii(substr(s,i,1))>65535 then 2 else 1 end),0)::integer from generate_series(1,length(s)) i
$$;
-- Match Dart String.trim for readiness and required mutation text.
create function public._setup_trim(s text) returns text language sql immutable security definer set search_path=pg_catalog,pg_temp as $$
 select btrim(s, chr(9)||chr(10)||chr(11)||chr(12)||chr(13)||chr(32)||chr(133)||chr(160)||chr(5760)||
  chr(8192)||chr(8193)||chr(8194)||chr(8195)||chr(8196)||chr(8197)||chr(8198)||chr(8199)||chr(8200)||chr(8201)||chr(8202)||
  chr(8232)||chr(8233)||chr(8239)||chr(8287)||chr(12288)||chr(65279))
$$;
create function public._setup_object(j jsonb, allowed text[], path text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if jsonb_typeof(j) is distinct from 'object' then perform public._setup_invalid(path); end if;
 if exists(select 1 from jsonb_object_keys(j) k where not(k=any(allowed))) then perform public._setup_invalid(path||': unknown field'); end if;
end $$;
create function public._setup_text(j jsonb,k text,path text,maxlen integer default 120,choices text[] default null,is_uuid boolean default false) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare s text;
begin
 if not(j?k) then return; end if; s:=j->>k;
 if jsonb_typeof(j->k)<>'string' or public._setup_length(s)>maxlen or (choices is not null and not(s=any(choices))) or
 (is_uuid and s<>'' and s!~'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') then perform public._setup_invalid(path||'.'||k); end if;
end $$;
create function public._setup_number(j jsonb,k text,path text,integral boolean default false,hi numeric default null) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if not(j?k) then return; end if;
 if jsonb_typeof(j->k)<>'number' then perform public._setup_invalid(path||'.'||k); end if;
 if (j->>k)::numeric<0 or (j->>k)::numeric>1.7976931348623157e308::numeric or (hi is not null and (j->>k)::numeric>hi) or (integral and (j->>k)!~'^[0-9]+$') then perform public._setup_invalid(path||'.'||k); end if;
end $$;
create function public._setup_bool(j jsonb,k text,path text,fixed boolean default null) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin if j?k and (jsonb_typeof(j->k)<>'boolean' or (fixed is not null and j->k<>to_jsonb(fixed))) then perform public._setup_invalid(path||'.'||k); end if; end $$;
create function public._setup_array(j jsonb,k text,path text) returns jsonb language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 if not(j?k) then return '[]'; end if;
 if jsonb_typeof(j->k)<>'array' then perform public._setup_invalid(path||'.'||k); end if;
 return j->k;
end $$;
create function public._setup_strings(j jsonb,k text,path text,choices text[] default null,is_uuid boolean default false,maxlen integer default 120) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare arr jsonb:=public._setup_array(j,k,path); x jsonb;
begin
 for x in select value from jsonb_array_elements(arr) loop perform public._setup_text(jsonb_build_object(k,x),k,path,maxlen,choices,is_uuid); end loop;
 if (select count(*)<>count(distinct value) from jsonb_array_elements(arr)) then perform public._setup_invalid(path||'.'||k||': duplicate'); end if;
end $$;
create function public._setup_unique(arr jsonb,k text,path text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin if exists(select 1 from jsonb_array_elements(arr) x where coalesce(x->>k,'')<>'' group by x->>k having count(*)>1) then perform public._setup_invalid(path||': duplicate'); end if; end $$;
create function public._setup_date(j jsonb,path text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
begin
 perform public._setup_object(j,array['value','unit','policy_reference'],path);
 perform public._setup_number(j,'value',path);
 perform public._setup_text(j,'unit',path,120,array['unknown','hours','days','weeks','months']);
 perform public._setup_text(j,'policy_reference',path,2000);
end $$;
create function public._setup_policy(j jsonb,path text) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare k text; a jsonb; r jsonb;
begin
 perform public._setup_object(j,array['supplier_requirement','reference_requirement','lot_requirement','entry_modes','label_profile','expiry_mode','expiry_rule','actions'],path);
 foreach k in array array['supplier_requirement','reference_requirement','lot_requirement'] loop perform public._setup_text(j,k,path,120,array['unknown','required','optional']); end loop;
 perform public._setup_strings(j,'entry_modes',path,array['manual','sku','barcode']);
 perform public._setup_text(j,'label_profile',path,120,array['unknown','manual_only','standard_upc_ean']);
 perform public._setup_text(j,'expiry_mode',path,120,array['unknown','printed','calculated']);
 if j?'expiry_rule' then perform public._setup_date(j->'expiry_rule',path||'.expiry_rule'); end if;
 for a in select value from jsonb_array_elements(public._setup_array(j,'actions',path)) loop
  perform public._setup_object(a,array['action','state','policy_reference','prerequisites','source_location_id','destination_location_id','quantity_relationship','resulting_date_rule','label_required'],path||'.actions');
  perform public._setup_text(a,'action',path,120,array['markdown','relabel','donation','discard','freeze','conversion']);
  perform public._setup_text(a,'state',path,120,array['unknown','not_used','configured']);
  perform public._setup_text(a,'policy_reference',path,2000);
  perform public._setup_strings(a,'prerequisites',path,null,false,2000);
  perform public._setup_text(a,'source_location_id',path,120,null,true);
  perform public._setup_text(a,'destination_location_id',path,120,null,true);
  perform public._setup_bool(a,'label_required',path);
  if a?'resulting_date_rule' then perform public._setup_date(a->'resulting_date_rule',path||'.resulting_date_rule'); end if;
  if a?'quantity_relationship' then
   r:=a->'quantity_relationship';
   perform public._setup_object(r,array['source_quantity','destination_quantity','destination_unit'],path||'.quantity_relationship');
   perform public._setup_number(r,'source_quantity',path); perform public._setup_number(r,'destination_quantity',path);
   perform public._setup_text(r,'destination_unit',path,120,array['each','kg','g','lb','oz','L','mL']);
  end if;
 end loop;
 perform public._setup_unique(coalesce(j->'actions','[]'),'action',path||'.actions');
end $$;
-- Compact size is computed recursively without removing whitespace INSIDE strings.
create function public._setup_compact(j jsonb) returns text language plpgsql immutable security definer set search_path=pg_catalog,pg_temp as $$
declare s text;
begin
 case jsonb_typeof(j)
 when 'object' then select '{'||coalesce(string_agg(to_jsonb(key)::text||':'||public._setup_compact(value),',' order by key),'')||'}' into s from jsonb_each(j);
 when 'array' then select '['||coalesce(string_agg(public._setup_compact(value),',' order by ord),'')||']' into s from jsonb_array_elements(j) with ordinality e(value,ord);
 else s:=j::text; end case; return s;
end $$;
create function public._setup_configuration(j jsonb) returns void language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare x jsonb; k text;
begin
 perform public._setup_object(j,array['schema_version','store','units','receiving','bindings','products','restrictions'],'configuration');
 if j->>'schema_version' is distinct from '1' or jsonb_typeof(j->'schema_version') is distinct from 'number' or octet_length(public._setup_compact(j))>262144 then perform public._setup_invalid('configuration'); end if;
 if j?'store' then
  x:=j->'store'; perform public._setup_object(x,array['display_name','country','region','timezone','confirmed'],'store');
  foreach k in array array['display_name','country','region','timezone'] loop perform public._setup_text(x,k,'store'); end loop;
  perform public._setup_bool(x,'confirmed','store');
 end if;
 if j?'receiving' then
  x:=j->'receiving'; perform public._setup_object(x,array['location_ids','hold_location_id','exception_role'],'receiving');
  perform public._setup_strings(x,'location_ids','receiving',null,true);
  perform public._setup_text(x,'hold_location_id','receiving',120,null,true);
  perform public._setup_text(x,'exception_role','receiving',120,array['unknown','lead','admin']);
 end if;
 for x in select value from jsonb_array_elements(public._setup_array(j,'units','configuration')) loop
  perform public._setup_object(x,array['code','precision'],'units');
  perform public._setup_text(x,'code','units',120,array['each','kg','g','lb','oz','L','mL']);
  perform public._setup_number(x,'precision','units',true,3);
  if x->>'code'='each' and x?'precision' and x->>'precision'<>'0' then perform public._setup_invalid('units.precision'); end if;
 end loop;
 perform public._setup_unique(coalesce(j->'units','[]'),'code','units');
 for x in select value from jsonb_array_elements(public._setup_array(j,'bindings','configuration')) loop
  perform public._setup_object(x,array['category_id','preset_version_id'],'bindings');
  perform public._setup_text(x,'category_id','bindings',120,null,true); perform public._setup_text(x,'preset_version_id','bindings',120,null,true);
 end loop;
 perform public._setup_unique(coalesce(j->'bindings','[]'),'category_id','bindings');
 for x in select value from jsonb_array_elements(public._setup_array(j,'products','configuration')) loop
  perform public._setup_object(x,array['product_id','stock_unit','pack_name','pack_count','overrides'],'products');
  perform public._setup_text(x,'product_id','products',120,null,true);
  perform public._setup_text(x,'stock_unit','products',120,array['each','kg','g','lb','oz','L','mL']);
  perform public._setup_text(x,'pack_name','products'); perform public._setup_number(x,'pack_count','products');
  if x->>'stock_unit'='each' and x?'pack_count' and (x->>'pack_count')::numeric%1<>0 then perform public._setup_invalid('products.pack_count'); end if;
  if x?'overrides' then perform public._setup_policy(x->'overrides','products.overrides'); end if;
 end loop;
 perform public._setup_unique(coalesce(j->'products','[]'),'product_id','products');
 if j?'restrictions' then
  x:=j->'restrictions'; perform public._setup_object(x,array['past_date_markdown_allowed','past_date_donation_allowed','action_confirmation_required'],'restrictions');
  perform public._setup_bool(x,'past_date_markdown_allowed','restrictions',false); perform public._setup_bool(x,'past_date_donation_allowed','restrictions',false); perform public._setup_bool(x,'action_confirmation_required','restrictions',true);
 end if;
end $$;

-- No helper is an RPC entry point.
do $$ declare f record; begin
 for f in select p.oid::regprocedure sig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like '\_setup\_%' escape '\' loop
  execute format('revoke all on function %s from public,anon,authenticated',f.sig);
 end loop;
end $$;
