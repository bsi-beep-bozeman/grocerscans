import fs from 'node:fs';
import http from 'node:http';
import {createHmac,randomBytes} from 'node:crypto';
import {Session,fixture,sentinels,inventory,quote,json,policy,randomUUID,assert,record,privateDir,sleep} from './common.mjs';
const keys=JSON.parse(fs.readFileSync(privateDir+'/status.json','utf8'));
const base='http://127.0.0.1:55321';
assert.equal(new URL(keys.API_URL).port,'55321');
const db=await new Session('ch06-api-fixtures').init();
const results=[],responses=[],accounts=[];let checks=0;
const pass=(label,details={})=>{results.push({label,status:'PASS',...details});checks++;record('API.json',{checks,results});console.log('PASS '+label);};
const saveAccounts=()=>fs.writeFileSync(privateDir+'/accounts.json',JSON.stringify(accounts));
async function request(route,body,token=keys.ANON_KEY,method='POST'){
 const r=await fetch(base+route,{method,headers:{apikey:keys.ANON_KEY,Authorization:'Bearer '+token,'Content-Type':'application/json'},...(body===undefined?{}:{body:JSON.stringify(body)}),signal:AbortSignal.timeout(10000)});
 const data=await r.json().catch(()=>null);return {status:r.status,data};
}
const safe=r=>JSON.stringify({status:r.status,code:r.data?.code??r.data?.error_code,message:r.data?.message??r.data?.msg});
async function createAccount(label){
 const account={label,email:`ch06-${randomUUID()}@example.invalid`,password:randomBytes(24).toString('base64url')};
 const created=await request('/auth/v1/admin/users',{email:account.email,password:account.password,email_confirm:true},keys.SERVICE_ROLE_KEY);
 assert.equal(created.status,200,safe(created));account.id=created.data.id;accounts.push(account);saveAccounts();
 const signed=await request('/auth/v1/token?grant_type=password',{email:account.email,password:account.password});assert.equal(signed.status,200,safe(signed));
 assert.equal(signed.data.user.id,account.id);assert.ok(signed.data.access_token);account.token=signed.data.access_token;account.refresh=signed.data.refresh_token;saveAccounts();return account;
}
async function rpc(name,args,account,type){
 const r=await request('/rest/v1/rpc/'+name,args,account?.token??keys.ANON_KEY);
 if(type&&r.status===200)responses.push({type,name,data:r.data});return r;
}
const tables=['store_setup_drafts','store_setup_versions','store_setup_active','setup_presets','setup_preset_versions','setup_locations','setup_operations','setup_audit'];
try{
 for(let i=0;i<30;i++){try{const r=await fetch(base+'/auth/v1/health',{signal:AbortSignal.timeout(1000)});if(r.ok)break;}catch{} await sleep(200);if(i===29)throw Error('Local Auth not healthy');}
 const admin=await createAccount('admin');const f=await fixture(db,'API synthetic A',{adminId:admin.id,authUser:false});
 const other=await createAccount('other-org-admin');const g=await fixture(db,'API synthetic B',{adminId:other.id,authUser:false});
 await sentinels(db,f);const beforeInventory=await inventory(db);
 const beforeCounts=()=>db.value(`select jsonb_build_object('audit',(select count(*) from public.setup_audit),'ops',(select count(*) from public.setup_operations),'versions',(select count(*) from public.store_setup_versions))`);
 pass('Real Auth admin creation and password sign-in for two isolated organisations');
 const context=await rpc('get_admin_setup_context',{},admin,'context');assert.equal(context.status,200,safe(context));assert.equal(context.data.admin_id,admin.id);assert.equal(context.data.org_id,f.org);
 assert.ok(context.data.catalog.branches.every(x=>x.org_id===f.org));pass('Context derives admin/org and scoped catalog from real issued JWT');
 const load=await rpc('get_store_setup',{p_branch_id:f.branch},admin,'state');assert.equal(load.status,200,safe(load));assert.equal(load.data.draft.revision,1);
 const saveArgs={p_branch_id:f.branch,p_operation_id:randomUUID(),p_expected_revision:1,p_configuration:f.cfg};
 const saved=await rpc('save_store_setup',saveArgs,admin,'state');assert.equal(saved.status,200,safe(saved));assert.equal(saved.data.draft.revision,2);
 assert.deepEqual((await rpc('save_store_setup',saveArgs,admin,'state')).data,saved.data);
 const stale=await rpc('save_store_setup',{...saveArgs,p_operation_id:randomUUID()},admin);assert.equal(stale.status,409,safe(stale));assert.equal(stale.data.code,'PT409');
 const invalidBefore=await beforeCounts();const invalid=await rpc('save_store_setup',{...saveArgs,p_operation_id:randomUUID(),p_expected_revision:2,p_configuration:{schema_version:1,unexpected:true}},admin);assert.equal(invalid.status,422,safe(invalid));assert.equal(invalid.data.code,'PT422');assert.deepEqual(await beforeCounts(),invalidBefore);
 pass('API save/retry/conflict/invalid contract and invalid-request atomicity');
 const activateArgs={p_branch_id:f.branch,p_operation_id:randomUUID(),p_draft_id:saved.data.draft.id,p_expected_draft_revision:2,p_expected_active_revision:0,p_reason:'Synthetic API activation'};
 const active=await rpc('activate_store_setup',activateArgs,admin,'state');assert.equal(active.status,200,safe(active));assert.equal(active.data.active.version,1);assert.equal(active.data.active_revision,1);assert.deepEqual(active.data.active.configuration,f.cfg);
 assert.deepEqual((await rpc('activate_store_setup',activateArgs,admin,'state')).data,active.data);pass('API activation snapshot and exact retry');
 const locReq={operation_id:randomUUID(),action:'create',branch_id:f.branch,expected_revision:0,name:'API location',reason:'Synthetic API'};
 const loc=await rpc('mutate_setup_location',{p_request:locReq},admin,'reference');assert.equal(loc.status,200,safe(loc));
 const preReq={operation_id:randomUUID(),action:'create',expected_revision:0,name:'API preset',reason:'Synthetic API',policy};
 const preset=await rpc('mutate_setup_preset',{p_request:preReq},admin,'reference');assert.equal(preset.status,200,safe(preset));
 assert.deepEqual((await rpc('mutate_setup_preset',{p_request:preReq},admin,'reference')).data,preset.data);
 pass('API location/preset mutations and recorded retry');
 const endpoints=[['get_admin_setup_context',{}],['get_store_setup',{p_branch_id:f.branch}],['save_store_setup',saveArgs],['activate_store_setup',activateArgs],['mutate_setup_preset',{p_request:preReq}],['mutate_setup_location',{p_request:locReq}]];
 const denied=[];
 for(const label of ['manager','staff','viewer','inactive-admin','supplier','kiosk','admin-supplier-conflict','admin-kiosk-conflict','unprovisioned']){
  const acc=await createAccount(label);denied.push(acc);
  if(['manager','staff','viewer','inactive-admin','admin-supplier-conflict','admin-kiosk-conflict'].includes(label))await db.raw(`insert into public.staff_profiles(id,org_id,branch_id,display_name,role,pin_hash,active) values(${quote(acc.id)},${quote(f.org)},${quote(f.branch)},${quote(label)},${quote(['manager','staff','viewer'].includes(label)?label:'admin')},'fixture-not-a-login',${label!=='inactive-admin'});`);
  if(label==='supplier'||label==='admin-supplier-conflict'){
   const sid=randomUUID();await db.raw(`insert into public.suppliers(id,org_id,name) values(${quote(sid)},${quote(f.org)},${quote('Synthetic '+label)});insert into public.supplier_profiles(id,org_id,supplier_id,display_name) values(${quote(acc.id)},${quote(f.org)},${quote(sid)},'Synthetic supplier user');`);
  }
  if(label==='kiosk'||label==='admin-kiosk-conflict')await db.raw(`insert into public.kiosk_devices(org_id,branch_id,device_auth_user_id,label) values(${quote(f.org)},${quote(f.branch)},${quote(acc.id)},${quote(label)});`);
  const before=await beforeCounts();
  for(const [name,args]of endpoints){const r=await rpc(name,args,acc);assert.equal(r.status,403,label+' '+name+' '+safe(r));assert.equal(r.data.code,'42501');}
  assert.deepEqual(await beforeCounts(),before);pass('All six RPCs deny '+label+' with no side effects');
 }
 for(const [name,args]of endpoints){const r=await rpc(name,args,null);assert.ok([401,403].includes(r.status),name+' '+safe(r));}
 pass('All six RPCs deny anonymous access');
 for(const account of [admin,null])for(const table of tables){
  for(const method of ['GET','DELETE']){const r=await request('/rest/v1/'+table+'?org_id=eq.'+f.org+'&select=*',undefined,account?.token??keys.ANON_KEY,method);assert.ok([401,403].includes(r.status),table+' '+safe(r));}
 }
 const helper=await rpc('_setup_actor',{},admin);assert.ok([403,404].includes(helper.status),safe(helper));
 const grants=await db.value(`select to_jsonb(count(*)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like '\\_setup\\_%' and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'))`);assert.equal(grants,0);
 pass('All eight setup tables deny direct read/delete; private helper grants denied');
 for(const [name,args]of [['get_store_setup',{p_branch_id:g.branch}],['save_store_setup',{...saveArgs,p_branch_id:g.branch}],['activate_store_setup',{...activateArgs,p_branch_id:g.branch}],['mutate_setup_location',{p_request:{...locReq,branch_id:g.branch}}],['mutate_setup_preset',{p_request:{operation_id:randomUUID(),action:'edit',preset_id:g.preset,expected_revision:1,name:'Cross org',policy,reason:'Synthetic'}}]]){
  const r=await rpc(name,args,admin);assert.equal(r.status,403,safe(r));
 }
 pass('Cross-organisation reads and every mutation family denied');
 const beforeRevoke=await beforeCounts();await db.raw(`update public.staff_profiles set active=false where id=${quote(admin.id)};`);
 for(const [name,args]of endpoints){const r=await rpc(name,args,admin);assert.equal(r.status,403,name+' '+safe(r));}
 assert.deepEqual(await beforeCounts(),beforeRevoke);await db.raw(`update public.staff_profiles set active=true where id=${quote(admin.id)};`);
 pass('Existing real JWT and recorded retries denied after administrator revocation');
 const sign=claims=>{const h=Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url'),p=Buffer.from(JSON.stringify(claims)).toString('base64url');return h+'.'+p+'.'+createHmac('sha256',keys.JWT_SECRET).update(h+'.'+p).digest('base64url');};
 const claims={sub:admin.id,role:'authenticated',aud:'authenticated',exp:Math.floor(Date.now()/1000)-60};
 const expired=await rpc('get_admin_setup_context',{}, {token:sign(claims)});assert.equal(expired.status,401,safe(expired));
 const tampered=await rpc('get_admin_setup_context',{}, {token:admin.token.slice(0,-8)+'AAAAAAAA'});assert.equal(tampered.status,401,safe(tampered));
 pass('API rejects locally signed expired JWT and tampered issued JWT');
 const spoof=await rpc('get_admin_setup_context',{}, {token:sign({...claims,sub:denied.find(x=>x.label==='staff').id,exp:Math.floor(Date.now()/1000)+3600,org_id:g.org,app_role:'admin'})});assert.equal(spoof.status,403,safe(spoof));
 pass('Forged organisation/app-role claims do not elevate a staff identity');
 const lostArgs={...saveArgs,p_expected_revision:2,p_operation_id:randomUUID()};
 await new Promise((resolve,reject)=>{
  const req=http.request(base+'/rest/v1/rpc/save_store_setup',{method:'POST',headers:{apikey:keys.ANON_KEY,Authorization:'Bearer '+admin.token,'Content-Type':'application/json'}},res=>{if(res.statusCode!==200){res.resume();reject(Error('Unexpected lost-response HTTP status '+res.statusCode));return;}res.destroy();req.destroy();resolve();});
  req.on('error',e=>{if(e.code!=='ECONNRESET')reject(e);});req.end(JSON.stringify(lostArgs));
 });
 const recovered=await rpc('save_store_setup',lostArgs,admin,'state');assert.equal(recovered.status,200,safe(recovered));assert.equal(recovered.data.draft.revision,3);
 assert.equal(await db.value(`select to_jsonb(count(*)) from public.setup_operations where operation_id=${quote(lostArgs.p_operation_id)}`),1);
 assert.equal(await db.value(`select to_jsonb(count(*)) from public.setup_audit where operation_id=${quote(lostArgs.p_operation_id)}`),1);
 pass('Response body connection deliberately discarded; exact retry recovers one committed mutation');
 const refreshed=await request('/auth/v1/token?grant_type=refresh_token',{refresh_token:admin.refresh});assert.equal(refreshed.status,200,safe(refreshed));admin.token=refreshed.data.access_token;admin.refresh=refreshed.data.refresh_token;saveAccounts();
 const afterRefresh=await rpc('get_store_setup',{p_branch_id:f.branch},admin,'state');assert.equal(afterRefresh.status,200,safe(afterRefresh));assert.equal(afterRefresh.data.draft.revision,3);pass('Real session refresh preserves backend setup state');
 const activeRecord=await db.value(`select to_jsonb(v) from public.store_setup_versions v where id=${quote(active.data.active.id)}`);assert.deepEqual(activeRecord.configuration,f.cfg);
 assert.deepEqual(await inventory(db),beforeInventory);pass('API operations preserve nonempty inventory/operational audit checksums');
 record('RPC_RESPONSES.json',responses);
 fs.writeFileSync(privateDir+'/restart-expectations.json',JSON.stringify({adminId:admin.id,branch:f.branch,state:afterRefresh.data,inventory:beforeInventory,activeRecord}));
 record('API.json',{status:'PASS',checks,results});
}catch(e){record('API.json',{status:'FAIL',checks,results,error:e.message});throw e;}
finally{await db.close();}
