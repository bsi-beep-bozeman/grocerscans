import fs from 'node:fs';
import {Session,docker,inventory,assert,record,privateDir,sleep} from './common.mjs';
const expected=JSON.parse(fs.readFileSync(privateDir+'/restart-expectations.json','utf8'));
const accounts=JSON.parse(fs.readFileSync(privateDir+'/accounts.json','utf8'));
const admin=accounts.find(x=>x.id===expected.adminId);
const keys=JSON.parse(fs.readFileSync(privateDir+'/status.json','utf8'));
const containers=['db','auth','rest','inbucket','kong'].map(x=>'supabase_'+x+'_shelflife-ch06-validation');
const tables=['store_setup_drafts','store_setup_versions','store_setup_active','setup_presets','setup_preset_versions','setup_locations','setup_operations','setup_audit'];
async function fingerprints(db){const out={};for(const t of tables)out[t]=await db.value(`select jsonb_build_object('count',count(*),'md5',md5(coalesce(string_agg(to_jsonb(t)::text,E'\\n' order by to_jsonb(t)::text),''))) from public.${t} t`);return out;}
let db=await new Session('ch06-before-restart').init();
const before=await fingerprints(db),beforeInventory=await inventory(db);await db.close();
docker('restart','--timeout','10',...containers);
for(let i=0;i<50;i++){
 try{const r=await fetch('http://127.0.0.1:55321/auth/v1/health',{signal:AbortSignal.timeout(1500)});if(r.ok)break;}catch{}
 if(i===49)throw Error('Auth did not recover after scoped restart');await sleep(400);
}
db=await new Session('ch06-after-restart').init();
try{
 assert.deepEqual(await fingerprints(db),before);assert.deepEqual(await inventory(db),beforeInventory);
 const login=await fetch('http://127.0.0.1:55321/auth/v1/token?grant_type=password',{method:'POST',headers:{apikey:keys.ANON_KEY,'Content-Type':'application/json'},body:JSON.stringify({email:admin.email,password:admin.password}),signal:AbortSignal.timeout(10000)});
 assert.equal(login.status,200,'Password sign-in after restart failed');const session=await login.json();
 const read=await fetch('http://127.0.0.1:55321/rest/v1/rpc/get_store_setup',{method:'POST',headers:{apikey:keys.ANON_KEY,Authorization:'Bearer '+session.access_token,'Content-Type':'application/json'},body:JSON.stringify({p_branch_id:expected.branch}),signal:AbortSignal.timeout(10000)});
 assert.equal(read.status,200);assert.deepEqual(await read.json(),expected.state);
 const bindings=[];
 for(const c of containers){const i=JSON.parse(docker('inspect',c))[0];for(const entries of Object.values(i.NetworkSettings.Ports))for(const p of entries??[]){assert.equal(p.HostIp,'127.0.0.1');bindings.push(p);}}
 record('RESTART.json',{status:'PASS',containers,setupTableFingerprints:before,inventory:beforeInventory,freshPasswordSignIn:true,exactStatePreserved:true,bindings});
 console.log('PASS restart: eight setup tables, six inventory tables, fresh sign-in and exact RPC state preserved; loopback bindings retained');
}finally{await db.close();}
