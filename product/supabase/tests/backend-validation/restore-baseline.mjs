// Destructive ONLY to the explicitly approved disposable database. Requires backups.
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {docker,target,privateDir,evidence,assert,record} from './common.mjs';
const baseline=privateDir+'/before-setup.dump',tested=privateDir+'/tested-20261016.dump';
const sha=p=>createHash('sha256').update(fs.readFileSync(p)).digest('hex');
assert.equal(sha(baseline),'587ce15fbbd00fa7fda99c953e691f1926c628283a285d2073e7ecabc0d73b83');
assert.ok(fs.statSync(tested).size>0);
const info=JSON.parse(docker('inspect',target))[0];
assert.equal(info.Name,'/'+target);
assert.equal(Object.keys(info.NetworkSettings.Networks).join(),'shelflife-ch06-validation');
assert.ok(info.Mounts.some(m=>m.Name===target&&m.Destination==='/var/lib/postgresql/data'));
const bindings=info.HostConfig.PortBindings['5432/tcp'];
assert.deepEqual(bindings,[{HostIp:'127.0.0.1',HostPort:'55322'}]);
const services=['auth','rest','inbucket','kong'].map(x=>'supabase_'+x+'_shelflife-ch06-validation');
docker('stop','--timeout','10',...services);
docker('cp',baseline,target+':/tmp/ch06-baseline-restore.dump');
docker('exec',target,'pg_restore','--list','/tmp/ch06-baseline-restore.dump');
const query=sql=>docker('exec',target,'psql','-U','postgres','-d','template1','-X','-At','-v','ON_ERROR_STOP=1','-c',sql);
const database=JSON.parse(query("select jsonb_build_object('name',datname,'owner',pg_get_userbyid(datdba),'encoding',pg_encoding_to_char(encoding),'collation',datcollate,'ctype',datctype) from pg_database where datname='postgres';"));
assert.equal(database.name,'postgres');
assert.match(database.owner,/^[a-z_]+$/);
const log=[];
try{
 log.push(docker('exec',target,'dropdb','-U','postgres','--maintenance-db=template1','--force','postgres'));
 log.push(docker('exec',target,'createdb','-U','postgres','--maintenance-db=template1','--template=template0','--owner='+database.owner,'--encoding='+database.encoding,'--lc-collate='+database.collation,'--lc-ctype='+database.ctype,'postgres'));
 // Built-in postgres is not a superuser in Supabase; restoring original schema
 // owners requires the existing supabase_admin role. No role/grant changes.
 log.push(docker('exec',target,'pg_restore','-U','supabase_admin','-d','postgres','--exit-on-error','/tmp/ch06-baseline-restore.dump'));
 const result=JSON.parse(docker('exec',target,'psql','-U','postgres','-d','postgres','-X','-At','-v','ON_ERROR_STOP=1','-c',"select jsonb_build_object('migrations',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations),'orgs',(select count(*) from public.orgs),'auth_users',(select count(*) from auth.users),'setup_table',to_regclass('public.store_setup_drafts'));"));
 assert.deepEqual(result.migrations,['20260924030000','20260924030001','20260924030002','20260925000000','20260925000001']);assert.equal(result.orgs,0);assert.equal(result.auth_users,0);assert.equal(result.setup_table,null);
 record('RESTORE.json',{status:'PASS',target,database,baselineSha256:sha(baseline),testedSnapshotSha256:sha(tested),result});
 console.log('PASS baseline restored: five retained migrations, zero organisations/users, setup schema absent');
}catch(e){record('RESTORE.json',{status:'FAIL',target,error:e.message});throw e;}
finally{fs.writeFileSync(evidence+'/RESTORE.log',log.join('\n'));}
