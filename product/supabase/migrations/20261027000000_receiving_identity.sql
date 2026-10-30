-- S2-A source only. Applying this migration needs exact-target R03 approval.
create schema if not exists private;
revoke all on schema private from public,anon,authenticated;

-- pgcrypto may be installed in public or extensions. Resolve its trusted schema
-- from pg_extension at migration time rather than assuming a target layout.
do $bootstrap$ declare ns text; begin
 select n.nspname into strict ns from pg_extension e join pg_namespace n on n.oid=e.extnamespace where e.extname='pgcrypto';
 execute format('create function private.receiving_random(n integer) returns bytea language sql security definer set search_path=pg_catalog,pg_temp as %L',format('select %I.gen_random_bytes(n)',ns));
 execute format('create function private.receiving_digest(s text) returns bytea language sql security definer set search_path=pg_catalog,pg_temp as %L',format('select %I.digest(s,''sha256'')',ns));
 execute format('create function private.receiving_crypt(s text,h text) returns text language sql security definer set search_path=pg_catalog,pg_temp as %L',format('select %I.crypt(s,h)',ns));
end $bootstrap$;
revoke all on function private.receiving_random(integer),private.receiving_digest(text),private.receiving_crypt(text,text) from public,anon,authenticated;

create table private.receiving_device_attempts (
 device_id uuid primary key references public.kiosk_devices(id),
 failed_count integer not null default 0 check(failed_count between 0 and 5),
 blocked_until timestamptz
);
create table private.receiving_staff_sessions (
 id uuid primary key default gen_random_uuid(), secret_digest bytea not null check(octet_length(secret_digest)=32),
 subject_id uuid not null references auth.users(id), org_id uuid not null references public.orgs(id),
 branch_id uuid not null references public.branches(id), device_id uuid not null references public.kiosk_devices(id),
 actor_id uuid not null references public.staff_profiles(id), pin_changed_at timestamptz,
 is_shift_lead boolean not null, issued_at timestamptz not null, expires_at timestamptz not null,
 revoked_at timestamptz, check(expires_at=issued_at+interval '8 hours')
);
create unique index receiving_one_live_session on private.receiving_staff_sessions(device_id) where revoked_at is null;
create table private.receiving_vault_keys (
 id uuid primary key default gen_random_uuid(),org_id uuid not null references public.orgs(id),
 branch_id uuid not null references public.branches(id),device_id uuid not null references public.kiosk_devices(id),
 original_actor_id uuid not null references public.staff_profiles(id), key_version integer not null default 1 check(key_version>0),
 key_material bytea not null check(octet_length(key_material)=32),created_at timestamptz not null default clock_timestamp(),retired_at timestamptz,
 unique(org_id,branch_id,device_id,original_actor_id,key_version)
);
create table private.receiving_recovery_grants (
 id uuid primary key default gen_random_uuid(),vault_id uuid not null references private.receiving_vault_keys(id),
 session_id uuid not null references private.receiving_staff_sessions(id),original_actor_id uuid not null references public.staff_profiles(id),
 recovering_actor_id uuid not null references public.staff_profiles(id), reason text not null,
 issued_at timestamptz not null,expires_at timestamptz not null,
 check(expires_at>issued_at and expires_at<=issued_at+interval '5 minutes'),
 check(public._setup_length(reason) between 1 and 1000 and public._setup_trim(reason)<>'')
);
create table private.receiving_identity_audit (
 id uuid primary key default gen_random_uuid(),device_id uuid not null references public.kiosk_devices(id),
 actor_id uuid references public.staff_profiles(id),session_id uuid references private.receiving_staff_sessions(id),
 recovery_id uuid references private.receiving_recovery_grants(id),
 action text not null check(action in ('session_started','session_ended','partition_recovered')),
 occurred_at timestamptz not null default clock_timestamp()
);
create trigger receiving_audit_immutable before update or delete on private.receiving_identity_audit for each row execute function public._setup_immutable();
create trigger receiving_recovery_immutable before update or delete on private.receiving_recovery_grants for each row execute function public._setup_immutable();
do $$ declare t text; begin
 foreach t in array array['receiving_device_attempts','receiving_staff_sessions','receiving_vault_keys','receiving_recovery_grants','receiving_identity_audit'] loop
  execute format('alter table private.%I enable row level security',t);
  execute format('revoke all on table private.%I from public,anon,authenticated',t);
 end loop;
end $$;

create function private.receiving_auth() returns uuid language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare u uuid:=auth.uid(); expiry numeric;
begin
 if u is null or jsonb_typeof(auth.jwt()->'exp') is distinct from 'number' then raise exception using errcode='PT401',message='unauthenticated'; end if;
 expiry:=(auth.jwt()->>'exp')::numeric;
 if expiry<=extract(epoch from clock_timestamp()) or expiry>253402300799 then raise exception using errcode='PT401',message='unauthenticated'; end if;
 return u;
end $$;
create function private.receiving_device() returns public.kiosk_devices language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare u uuid:=private.receiving_auth(); d public.kiosk_devices;
begin
 if exists(select 1 from public.staff_profiles where id=u) or exists(select 1 from public.supplier_profiles where id=u) or
  (select count(*) from public.kiosk_devices where device_auth_user_id=u)<>1 then raise exception using errcode='42501',message='unavailable'; end if;
 select * into d from public.kiosk_devices where device_auth_user_id=u and active;
 if d.id is null or not exists(select 1 from public.branches b join public.orgs o on o.id=b.org_id where b.id=d.branch_id and b.org_id=d.org_id) then raise exception using errcode='42501',message='unavailable'; end if;
 return d;
end $$;
create function private.receiving_actor_valid(a public.staff_profiles,d public.kiosk_devices) returns boolean language sql security definer set search_path=pg_catalog,pg_temp as $$
 select a.id is not null and a.active and a.role='staff' and a.org_id=d.org_id and a.branch_id=d.branch_id
  and not exists(select 1 from public.kiosk_devices where device_auth_user_id=a.id)
  and not exists(select 1 from public.supplier_profiles where id=a.id)
$$;
create function private.receiving_session(p_id uuid,p_secret text,p_recovery_actor uuid default null) returns private.receiving_staff_sessions language plpgsql security definer set search_path=pg_catalog,pg_temp as $$
declare d public.kiosk_devices; again public.kiosk_devices; s private.receiving_staff_sessions; a public.staff_profiles;
begin
 d:=private.receiving_device();
 -- Common lock order: permanent attempt row, device, ordered actors, session/vault.
 perform 1 from private.receiving_device_attempts where device_id=d.id for update;
 if not found then raise exception using errcode='42501',message='session_revoked'; end if;
 perform 1 from public.kiosk_devices where id=d.id for share;
 select * into s from private.receiving_staff_sessions where id=p_id and device_id=d.id;
 if s.id is null then raise exception using errcode='42501',message='session_revoked'; end if;
 perform 1 from public.staff_profiles where id=s.actor_id or id=p_recovery_actor order by id for share;
 select * into s from private.receiving_staff_sessions where id=p_id for update;
 again:=private.receiving_device();
 select * into a from public.staff_profiles where id=s.actor_id;
 if p_secret is null or length(p_secret)<>44 or p_secret!~'^[A-Za-z0-9+/]{43}=$' or
  s.secret_digest<>private.receiving_digest(p_secret) or s.revoked_at is not null or
  s.subject_id<>private.receiving_auth() or s.org_id<>again.org_id or s.branch_id<>again.branch_id or s.device_id<>again.id or
  not private.receiving_actor_valid(a,again) or s.pin_changed_at is distinct from a.pin_last_changed_at or s.is_shift_lead<>a.is_shift_lead
 then raise exception using errcode='42501',message='session_revoked'; end if;
 if s.expires_at<=clock_timestamp() then raise exception using errcode='42501',message='session_expired'; end if;
 return s;
end $$;
revoke all on function private.receiving_auth(),private.receiving_device(),private.receiving_actor_valid(public.staff_profiles,public.kiosk_devices),private.receiving_session(uuid,text,uuid) from public,anon,authenticated;
