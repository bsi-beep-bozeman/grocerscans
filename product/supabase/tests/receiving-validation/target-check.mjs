import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync,spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
export {assert};
export const root=process.cwd();
assert.equal(path.basename(root).toLowerCase(),'shelflife');
export const evidence=path.resolve('handoffs/2026-10-28/ch10-connected-validation-scope');
export const privateDir=path.resolve('.cache/ch10-receiving-validation/private');
export const expected=JSON.parse(fs.readFileSync(path.join(evidence,'EXPECTED_TARGET.json'),'utf8').replace(/^\uFEFF/,''));
export const target='supabase_db_shelflife-ch06-validation';
export const services=expected.containers.map(x=>x.name);
export const hash=p=>createHash('sha256').update(fs.readFileSync(p)).digest('hex').toUpperCase();
export function privatePath(name){
 assert.match(name,/^[a-z0-9-]+\.(dump|json)$/);
 fs.mkdirSync(privateDir,{recursive:true});
 assert.ok(fs.realpathSync(privateDir).toLowerCase().startsWith(fs.realpathSync(root).toLowerCase()+path.sep));
 return path.join(privateDir,name);
}
export function record(name,data){if(!name.endsWith('.json'))name+='.json';assert.match(name,/^[A-Z0-9_-]+\.json$/);fs.writeFileSync(path.join(evidence,name),JSON.stringify(data,null,2)+'\n');}
export const docker=(...args)=>execFileSync('docker',['--context','desktop-linux',...args],{encoding:'utf8',stdio:['pipe','pipe','pipe'],maxBuffer:32*1024*1024});
export function inspect(){
 const rows=[];
 for(const ex of expected.containers){
  const r=JSON.parse(docker('inspect',ex.name))[0];
  assert.equal(r.Id,ex.id,'container identity');assert.equal(r.Image,ex.imageId,'image identity');
  assert.deepEqual(r.HostConfig.PortBindings??{},ex.bindings,'host bindings');
  assert.deepEqual(Object.keys(r.NetworkSettings.Networks),[expected.network],'network');
  assert.deepEqual(r.Mounts.map(m=>({name:m.Name,destination:m.Destination})),ex.volumes,'mounts');
  assert.ok(r.Mounts.every(m=>m.Type==='volume'&&m.RW===true));
  rows.push({name:ex.name,id:r.Id,state:r.State.Status,image:r.Image,bindings:r.HostConfig.PortBindings});
 }
 for(const name of expected.backupContainers){const r=JSON.parse(docker('inspect',name))[0];assert.equal(r.State.Running,false,'binding backup must stay stopped');}
 return rows;
}
export function sql(query,{database='postgres',user='postgres'}={}){
 const r=spawnSync('docker',['--context','desktop-linux','exec','-i',target,'psql','-U',user,'-d',database,'-X','-qAt','-v','ON_ERROR_STOP=1'],{input:query,encoding:'utf8',maxBuffer:32*1024*1024});
 if(r.status!==0)throw new Error('SQL failed (details withheld; use a sanitized assertion log)');
 return r.stdout.trim();
}
export const value=q=>JSON.parse(sql(q));
export function baselineState(){
 return value(`select jsonb_build_object('migrations',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations),'users',(select count(*) from auth.users),'orgs',(select count(*) from public.orgs),'setup',to_regclass('public.store_setup_drafts'),'receiving',to_regclass('private.receiving_staff_sessions'));`);
}
export function requireBaseline(){const b=baselineState();assert.deepEqual(b,{migrations:['20260924030000','20260924030001','20260924030002','20260925000000','20260925000001'],users:0,orgs:0,setup:null,receiving:null});return b;}
export function fingerprints(){
 const schemas="('public','private','auth','supabase_migrations')";
 const metadata=value(`select jsonb_build_object(
 'schemas',(select jsonb_agg(jsonb_build_array(nspname,pg_get_userbyid(nspowner),nspacl) order by nspname) from pg_namespace where nspname in ${schemas}),
 'relations',(select jsonb_agg(jsonb_build_array(n.nspname,c.relname,c.relkind,pg_get_userbyid(c.relowner),c.relacl,c.relrowsecurity,c.relforcerowsecurity) order by n.nspname,c.relname) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ${schemas} and c.relkind in ('r','v','S','m','p')),
 'columns',(select jsonb_agg(jsonb_build_array(n.nspname,c.relname,a.attname,a.attacl,format_type(a.atttypid,a.atttypmod),a.attnotnull) order by n.nspname,c.relname,a.attnum) from pg_attribute a join pg_class c on c.oid=a.attrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname in ${schemas} and c.relkind in ('r','v','p') and a.attnum>0 and not a.attisdropped),
 'functions',(select jsonb_agg(jsonb_build_array(n.nspname,p.proname,pg_get_function_identity_arguments(p.oid),pg_get_userbyid(p.proowner),p.proacl,p.prosecdef,p.proconfig,md5(pg_get_functiondef(p.oid))) order by n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ${schemas} and p.prokind='f'),
 'defaults',(select jsonb_agg(jsonb_build_array(pg_get_userbyid(d.defaclrole),coalesce(n.nspname,''),d.defaclobjtype,d.defaclacl) order by pg_get_userbyid(d.defaclrole),coalesce(n.nspname,''),d.defaclobjtype) from pg_default_acl d left join pg_namespace n on n.oid=d.defaclnamespace),
 'policies',(select jsonb_agg(to_jsonb(p) order by schemaname,tablename,policyname) from pg_policies p where schemaname in ${schemas}),
 'memberships',(select jsonb_agg(jsonb_build_array(pg_get_userbyid(roleid),pg_get_userbyid(member),admin_option) order by pg_get_userbyid(roleid),pg_get_userbyid(member)) from pg_auth_members),
 'publications',(select jsonb_agg(jsonb_build_array(pubname,pg_get_userbyid(pubowner),puballtables,pubinsert,pubupdate,pubdelete,pubtruncate) order by pubname) from pg_publication)
 );`);
 const tables=value(`select coalesce(jsonb_agg(jsonb_build_array(n.nspname,c.relname) order by n.nspname,c.relname),'[]') from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ${schemas} and c.relkind='r';`);
 const data={};for(const [s,t]of tables){assert.match(s,/^[a-z0-9_]+$/);assert.match(t,/^[a-z0-9_]+$/);data[s+'.'+t]=value(`select jsonb_build_object('count',count(*),'digest',md5(coalesce(string_agg(to_jsonb(r)::text,E'\\n' order by to_jsonb(r)::text),''))) from "${s}"."${t}" r;`);}
 return {metadata,data};
}
export function stopOwned(){inspect();docker('stop','--timeout','10',...services);return inspect();}
if(process.argv[1]===new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/,'$1'))console.log(JSON.stringify(inspect()));
