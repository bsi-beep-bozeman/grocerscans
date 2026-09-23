-- ShelfLife seed: 1 org, 2 branches, 4 kiosks, 1 admin, 1 viewer, 12 staff.
-- Passwords + PINs are DEV DEFAULTS — rotate before any production use.

-- ─────────────────────────────────────────────────────────────
-- Helper: create an email/password user in auth.users.
-- Wrapped in a temp function so the seed stays declarative below.
-- ─────────────────────────────────────────────────────────────

create or replace function pg_temp.seed_user(p_email text, p_password text)
returns uuid language plpgsql as $$
declare new_id uuid;
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, confirmation_token, recovery_token,
    email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(), 'authenticated', 'authenticated',
    lower(p_email), crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    false, '', '', '', ''
  ) returning id into new_id;
  return new_id;
end $$;

-- ─────────────────────────────────────────────────────────────
-- Org + branches
-- ─────────────────────────────────────────────────────────────

with new_org as (
  insert into orgs (name) values ('Al Safa Market') returning id
)
insert into branches (org_id, name, address)
select id, unnest(array['Branch A', 'Branch B']),
       unnest(array['— set address —', '— set address —'])
  from new_org;

-- ─────────────────────────────────────────────────────────────
-- Users
--   admin  : admin@alsafa.local     / shelflife-admin
--   viewer : viewer@alsafa.local    / shelflife-view
--   kiosks : kiosk-a1..b2@alsafa.local / shelflife-kiosk
--   staff  : staff-a1..b6@alsafa.local / shelflife-staff (PIN below)
-- ─────────────────────────────────────────────────────────────

do $$
declare
  v_org_id uuid := (select id from orgs where name = 'Al Safa Market');
  v_branch_a uuid := (select id from branches where org_id = v_org_id and name = 'Branch A');
  v_branch_b uuid := (select id from branches where org_id = v_org_id and name = 'Branch B');
  v_admin_id uuid;
  v_viewer_id uuid;
  v_kiosk_id uuid;
  v_staff_id uuid;
  branch_letter text;
  branch_uuid uuid;
  i int;
begin
  -- Admin
  v_admin_id := pg_temp.seed_user('admin@alsafa.local', 'shelflife-admin');
  insert into staff_profiles (id, org_id, branch_id, display_name, role, email)
  values (v_admin_id, v_org_id, null, 'Admin', 'admin', 'admin@alsafa.local');

  -- Viewer
  v_viewer_id := pg_temp.seed_user('viewer@alsafa.local', 'shelflife-view');
  insert into staff_profiles (id, org_id, branch_id, display_name, role, email)
  values (v_viewer_id, v_org_id, null, 'Viewer', 'viewer', 'viewer@alsafa.local');

  -- Kiosks (2 per branch) + staff (6 per branch)
  foreach branch_letter in array array['a', 'b'] loop
    branch_uuid := case branch_letter when 'a' then v_branch_a else v_branch_b end;

    for i in 1..2 loop
      v_kiosk_id := pg_temp.seed_user(
        format('kiosk-%s%s@alsafa.local', branch_letter, i),
        'shelflife-kiosk'
      );
      insert into kiosk_devices (org_id, branch_id, device_auth_user_id, label)
      values (v_org_id, branch_uuid, v_kiosk_id,
              format('Branch %s Device %s', upper(branch_letter), i));
    end loop;

    for i in 1..6 loop
      v_staff_id := pg_temp.seed_user(
        format('staff-%s%s@alsafa.local', branch_letter, i),
        'shelflife-staff'
      );
      insert into staff_profiles (id, org_id, branch_id, display_name, role,
                                  is_shift_lead, pin_hash, pin_last_changed_at, email)
      values (v_staff_id, v_org_id, branch_uuid,
              format('Staff %s%s', upper(branch_letter), i), 'staff',
              i = 1,  -- staff #1 in each branch is the default shift lead
              crypt(format('%s%s%s%s', i, i, i, i), gen_salt('bf', 8)),  -- PIN 1111, 2222, 3333, 4444, 5555, 6666
              now(),
              format('staff-%s%s@alsafa.local', branch_letter, i));
    end loop;
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────
-- Categories (conservative defaults — donation/markdown flags stay
-- false until the store's state date-label rules are confirmed)
-- ─────────────────────────────────────────────────────────────

insert into categories (org_id, name, expiry_mode, default_shelf_life_days,
                        alert_thresholds, is_ftl, requires_relabel_on_freeze)
select o.id, c.name, c.expiry_mode::expiry_mode, c.days, c.thresh, c.is_ftl, c.relabel
  from orgs o cross join (values
    ('Dry / canned',       'printed',  null, array[30, 7], false, false),
    ('Frozen',             'printed',  null, array[30, 7], false, false),
    ('Dairy',              'printed',  null, array[7, 2],  false, false),
    ('Beverages',          'printed',  null, array[30, 7], false, false),
    ('Fresh meat',         'computed', 3,    array[2, 1],  false, true),
    ('Fresh fish',         'computed', 2,    array[1],     true,  true),
    ('Produce',            'computed', 5,    array[2, 1],  true,  false),
    ('Bakery (in-store)',  'computed', 2,    array[1],     false, false),
    ('Deli / prepared',    'computed', 3,    array[1],     true,  false),
    ('Store-packed',       'computed', 3,    array[1],     false, false),
    ('Pharmacy / OTC',     'printed',  null, array[120, 30, 7], false, false)
  ) as c(name, expiry_mode, days, thresh, is_ftl, relabel)
 where o.name = 'Al Safa Market';

-- ─────────────────────────────────────────────────────────────
-- Suppliers + a handful of demo products so end-to-end works
-- ─────────────────────────────────────────────────────────────

insert into suppliers (org_id, name)
select id, unnest(array['Del Monte', 'Local Farms Co.', 'US Foods', 'MedSupply Rx'])
  from orgs where name = 'Al Safa Market';

insert into products (org_id, upc, name, category_id, default_supplier_id, unit_cost_cents, unit_price_cents)
select o.id, p.upc, p.name,
       (select id from categories where org_id = o.id and name = p.cat),
       (select id from suppliers where org_id = o.id and name = p.sup),
       p.cost, p.price
  from orgs o cross join (values
    ('0002200000019', 'Ground beef 1lb',    'Fresh meat',        'US Foods',       450,  699),
    ('0071068201075', 'Whole milk 1 gal',   'Dairy',             'Local Farms Co.', 320,  429),
    ('0024000162512', 'Canned corn 15oz',   'Dry / canned',      'Del Monte',       89,  149),
    ('0300650540016', 'Tylenol 24ct',       'Pharmacy / OTC',    'MedSupply Rx',   399,  799),
    ('0000000000101', 'Sourdough loaf',     'Bakery (in-store)', null,             150,  399)
  ) as p(upc, name, cat, sup, cost, price)
 where o.name = 'Al Safa Market';
