import fs from 'node:fs';
import {randomBytes} from 'node:crypto';
import {Session,fixture,sentinels,inventory,quote,randomUUID,assert,privateDir} from './common.mjs';
const keys=JSON.parse(fs.readFileSync(privateDir+'/status.json','utf8'));
assert.equal(keys.API_URL,'http://127.0.0.1:55321');
const users={};
for(const label of ['admin','secondAdmin','viewer','staff','otherAdmin']){
 const a={email:`browser-${randomUUID()}@example.invalid`,password:randomBytes(24).toString('base64url')};
 const r=await fetch(keys.API_URL+'/auth/v1/admin/users',{method:'POST',headers:{apikey:keys.ANON_KEY,Authorization:'Bearer '+keys.SERVICE_ROLE_KEY,'Content-Type':'application/json'},body:JSON.stringify({...a,email_confirm:true})});
 assert.equal(r.status,200);a.id=(await r.json()).id;users[label]=a;
 fs.writeFileSync(privateDir+'/browser-accounts.json',JSON.stringify(users));
}
const db=await new Session('ch06-browser-fixtures').init();
try{
 const f=await fixture(db,'Chrome synthetic store',{adminId:users.admin.id,authUser:false});
 const g=await fixture(db,'Chrome other organisation',{adminId:users.otherAdmin.id,authUser:false});
 for(const [label,role]of [['secondAdmin','admin'],['viewer','viewer'],['staff','staff']])await db.raw(`insert into public.staff_profiles(id,org_id,branch_id,display_name,role,pin_hash) values(${quote(users[label].id)},${quote(f.org)},${quote(f.branch)},${quote('Chrome '+label)},${quote(role)},'fixture-not-a-login');`);
 await sentinels(db,f);
 fs.writeFileSync(privateDir+'/browser-fixtures.json',JSON.stringify({f,g,beforeInventory:await inventory(db)},null,2));
 fs.writeFileSync(privateDir+'/web-defines.json',JSON.stringify({SUPABASE_URL:keys.API_URL,SUPABASE_ANON_KEY:keys.ANON_KEY}));
 console.log('PASS five synthetic Auth users, two organisations, ready and empty branches, inventory sentinels; private configuration saved.');
}finally{await db.close();}
