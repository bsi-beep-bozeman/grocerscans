import fs from 'node:fs';
import {randomBytes,randomUUID,randomInt} from 'node:crypto';
import {assert,inspect,sql,value,privatePath,record} from './target-check.mjs';
export const keys=JSON.parse(fs.readFileSync('.cache/ch06-validation/private/status.json','utf8'));
assert.equal(keys.API_URL,'http://127.0.0.1:55321');
export const q=v=>"'"+String(v).replaceAll("'","''")+"'";
export const j=v=>q(JSON.stringify(v))+'::jsonb';
export async function request(route,body,token=keys.ANON_KEY,method='POST'){
 assert.ok(route.startsWith('/rest/v1/')||route.startsWith('/auth/v1/'));
 const r=await fetch(keys.API_URL+route,{method,headers:{apikey:keys.ANON_KEY,Authorization:'Bearer '+token,'Content-Type':'application/json'},...(body===undefined?{}:{body:JSON.stringify(body)}),signal:AbortSignal.timeout(15000)});
 const text=await r.text();assert.ok(text.length<=1048576,'Unexpected API response size');
 let data;try{data=JSON.parse(text)}catch{data=null;}return {status:r.status,data};
}
export const rpc=(name,args,account)=>request('/rest/v1/rpc/'+name,args,account?.token??keys.ANON_KEY);
export function ok(r,label){assert.equal(r.status,200,label+': status '+r.status+' code '+(r.data?.code??r.data?.error_code??'unknown'));return r.data;}
export const readFixture=()=>JSON.parse(fs.readFileSync(privatePath('fixtures.json'),'utf8'));
export const saveFixture=f=>fs.writeFileSync(privatePath('fixtures.json'),JSON.stringify(f));
export async function login(a){const r=ok(await request('/auth/v1/token?grant_type=password',{email:a.email,password:a.password}),'password login');assert.equal(r.user.id,a.id);a.token=r.access_token;a.refresh=r.refresh_token;return a;}
const labels=['admin-a','admin-a2','admin-b','inactive-admin','viewer-a','manager-a','supplier-a','kiosk-a1','kiosk-a1b','kiosk-a2','kiosk-b1','kiosk-inactive','kiosk-mismatch','unlinked','staff-a1','lead-a1','replacement-a1','disabled-a1','staff-a2','lead-a2','staff-b1','lead-b1','duplicate-pin-a1','conflict-kiosk-staff','conflict-kiosk-supplier','conflict-admin-kiosk','conflict-admin-supplier','conflict-actor-supplier','conflict-actor-kiosk'];
if(process.argv[2]==='provision'){
 inspect();assert.equal(labels.length,29);assert.ok(!fs.existsSync(privatePath('fixtures.json')),'Do not reprovision over existing fixture records');
 const f={accounts:{},ids:{},pins:{}};const used=new Set();
 for(const label of ['org-a','org-b','branch-a1','branch-a2','branch-b1','category-a-printed','category-a-calculated','category-b-printed','supplier-a','supplier-b','product-a-zero','product-a-sku','product-a-missing-setup','product-a-foreign-category','product-a-foreign-supplier','product-b-zero'])f.ids[label]=randomUUID();
 for(const label of labels){
  const a={email:'s2a-c10-'+label+'@example.invalid',password:randomBytes(24).toString('base64url')};
  a.id=ok(await request('/auth/v1/admin/users',{email:a.email,password:a.password,email_confirm:true},keys.SERVICE_ROLE_KEY),'create '+label).id;
  assert.match(a.id,/^[a-f0-9-]{36}$/);f.accounts[label]=a;saveFixture(f);await login(a);
  let pin;do{pin=String(randomInt(100000,1000000));}while(used.has(pin));used.add(pin);f.pins[label]=pin;saveFixture(f);
 }
 const id=x=>q(f.ids[x]);let statements='begin;';
 for(const o of ['a','b'])statements+=`insert into public.orgs(id,name) values(${id('org-'+o)},'S2A C10 Synthetic org ${o}');`;
 for(const b of ['a1','a2','b1'])statements+=`insert into public.branches(id,org_id,name,timezone) values(${id('branch-'+b)},${id('org-'+b[0])},'S2A C10 Synthetic branch ${b}','Australia/Perth');`;
 for(const label of labels){
  const a=f.accounts[label],org=label==='admin-b'||label.endsWith('-b1')?'b':'a',branch=label.endsWith('-a2')?'a2':org==='b'?'b1':'a1';
  const kiosk=label.startsWith('kiosk-')||['conflict-kiosk-staff','conflict-kiosk-supplier','conflict-admin-kiosk','conflict-actor-kiosk'].includes(label);
  const supplier=['supplier-a','conflict-kiosk-supplier','conflict-admin-supplier','conflict-actor-supplier'].includes(label);
  const admin=label.startsWith('admin-')||['inactive-admin','conflict-admin-kiosk','conflict-admin-supplier'].includes(label);
  const staff=label.startsWith('staff-')||label.startsWith('lead-')||['replacement-a1','disabled-a1','duplicate-pin-a1','conflict-kiosk-staff','conflict-actor-supplier','conflict-actor-kiosk'].includes(label);
  if(kiosk){const d=randomUUID();f.ids['device-'+label]=d;statements+=`insert into public.kiosk_devices(id,org_id,branch_id,device_auth_user_id,label,active) values(${q(d)},${id('org-'+org)},${id('branch-'+(label==='kiosk-mismatch'?'b1':branch))},${q(a.id)},${q('S2A C10 '+label)},${label!=='kiosk-inactive'});`;}
  if(admin||staff||['viewer-a','manager-a'].includes(label)){
   const role=admin?'admin':staff?'staff':label==='viewer-a'?'viewer':'manager';
   statements+=`insert into public.staff_profiles(id,org_id,branch_id,display_name,role,is_shift_lead,active,pin_hash,pin_last_changed_at) values(${q(a.id)},${id('org-'+org)},${id('branch-'+branch)},${q('S2A C10 '+label)},${q(role)},${label.startsWith('lead-')},${!['inactive-admin','duplicate-pin-a1'].includes(label)},${staff?`private.receiving_crypt(${q(f.pins[label])},'$2a$08$abcdefghijklmnopqrstuu')`:'null'},clock_timestamp());`;
  }
  a.expectedContext=admin&&!kiosk&&!supplier&&label!=='inactive-admin'?'admin_setup':kiosk&&!staff&&!admin&&!supplier&&!['kiosk-inactive','kiosk-mismatch'].includes(label)?'kiosk':'unavailable';
 }
 for(const o of ['a','b'])statements+=`insert into public.suppliers(id,org_id,name) values(${id('supplier-'+o)},${id('org-'+o)},'S2A C10 supplier ${o}');`;
 for(const label of ['supplier-a','conflict-kiosk-supplier','conflict-admin-supplier','conflict-actor-supplier'])statements+=`insert into public.supplier_profiles(id,org_id,supplier_id,display_name) values(${q(f.accounts[label].id)},${id('org-a')},${id('supplier-a')},${q('S2A C10 '+label)});`;
 for(const label of ['category-a-printed','category-a-calculated','category-b-printed'])statements+=`insert into public.categories(id,org_id,name,expiry_mode,default_shelf_life_days) values(${id(label)},${id(label.includes('-b-')?'org-b':'org-a')},${q('S2A C10 '+label)},${label.endsWith('calculated')?"'computed',7":"'printed',null"});`;
 for(const [i,label]of ['product-a-zero','product-a-sku','product-a-missing-setup','product-a-foreign-category','product-a-foreign-supplier','product-b-zero'].entries()){
  const org=label.includes('-b-')?'b':'a';statements+=`insert into public.products(id,org_id,category_id,default_supplier_id,name,upc,sku,unit_cost_cents,unit_price_cents) values(${id(label)},${id('org-'+org)},${id('category-'+org+'-printed')},${id('supplier-'+org)},${q('S2A C10 '+label)},${q(label.endsWith('zero')?'001234':'99100'+i)},${q(label==='product-a-sku'?'000SKU':'SKU'+i)},999,1999);`;
 }
 for(let i=0;i<101;i++)statements+=`insert into public.products(id,org_id,category_id,name,upc) values(${q(randomUUID())},${id('org-a')},${id('category-a-printed')},${q('S2A C10 pagination '+i)},${q('998'+String(i).padStart(5,'0'))});`;
 statements+='commit;';sql(statements);saveFixture(f);
 record('FIXTURE_PROVISION',{status:'PASS',authAccounts:labels.map(label=>({label,id:f.accounts[label].id,expectedContext:f.accounts[label].expectedContext})),ids:f.ids,counts:value("select jsonb_build_object('users',(select count(*) from auth.users),'orgs',(select count(*) from public.orgs),'branches',(select count(*) from public.branches),'products',(select count(*) from public.products));")});
 fs.writeFileSync(privatePath('web-defines.json'),JSON.stringify({SUPABASE_URL:keys.API_URL,SUPABASE_ANON_KEY:keys.ANON_KEY}));
 console.log('PASS29 local password sign-ins; synthetic identity/catalog fixtures and private build defines prepared');
}
