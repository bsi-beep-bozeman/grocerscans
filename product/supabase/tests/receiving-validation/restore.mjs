import fs from 'node:fs';
import path from 'node:path';
import {assert,inspect,docker,target,services,hash,privatePath,record,requireBaseline,fingerprints,sql,value} from './target-check.mjs';
const action=process.argv[2];assert.ok(['capture','prove','final'].includes(action));
inspect();
assert.equal(hash('.cache/ch06-validation/private/before-setup.dump'),'587CE15FBBD00FA7FDA99C953E691F1926C628283A285D2073E7ECABC0D73B83');
const dump=privatePath('before-run.dump'), fingerprint=privatePath('baseline-fingerprint.json');
if(action==='capture'){
 assert.ok(!fs.existsSync(dump)&&!fs.existsSync(fingerprint),'Never overwrite pre-run recovery material');
 const baseline=requireBaseline();const fp=fingerprints();
 fs.writeFileSync(fingerprint,JSON.stringify(fp));
 docker('exec',target,'pg_dump','-U','supabase_admin','-d','postgres','-Fc','-f','/tmp/ch10-before-run.dump');
 docker('cp',target+':/tmp/ch10-before-run.dump',dump);
 record('BASELINE_CAPTURE',{status:'PASS',baseline,sha256:hash(dump),tableFingerprints:fp.data});
 console.log('PASS empty baseline and fresh private backup captured');
}else{
 const mark=privatePath(action==='prove'?'pre-restore-started.json':'final-restore-started.json');
 assert.ok(!fs.existsSync(mark),'Destructive restore already attempted; a retry requires separate approval');
 assert.ok(fs.existsSync(dump)&&fs.existsSync(fingerprint));
 const cap=JSON.parse(fs.readFileSync(path.resolve('handoffs/2026-10-28/ch10-connected-validation-scope/BASELINE_CAPTURE.json'),'utf8'));
 assert.equal(hash(dump),cap.sha256);
 fs.writeFileSync(mark,JSON.stringify({startedAt:new Date().toISOString(),sha256:hash(dump)}));
 docker('stop','--timeout','10',...services.filter(x=>x!==target));
 if(action==='final'){
  const tested=privatePath('tested-run.dump');assert.ok(!fs.existsSync(tested));
  docker('exec',target,'pg_dump','-U','supabase_admin','-d','postgres','-Fc','-f','/tmp/ch10-tested-run.dump');docker('cp',target+':/tmp/ch10-tested-run.dump',tested);
  record('TESTED_SNAPSHOT',{sha256:hash(tested),restoreTested:false});
 }
 const db=JSON.parse(sql("select jsonb_build_object('name',datname,'owner',pg_get_userbyid(datdba),'encoding',pg_encoding_to_char(encoding),'collation',datcollate,'ctype',datctype) from pg_database where datname='postgres';",{database:'template1'}));
 assert.deepEqual(db,{name:'postgres',owner:'postgres',encoding:'UTF8',collation:'en_US.UTF-8',ctype:'en_US.UTF-8'});
 docker('cp',dump,target+':/tmp/ch10-restore.dump');
 try{
  docker('exec',target,'dropdb','-U','postgres','--maintenance-db=template1','--force','postgres');
  docker('exec',target,'createdb','-U','postgres','--maintenance-db=template1','--template=template0','--owner=postgres','--encoding=UTF8','--lc-collate=en_US.UTF-8','--lc-ctype=en_US.UTF-8','postgres');
  docker('exec',target,'pg_restore','-U','supabase_admin','-d','postgres','--exit-on-error','/tmp/ch10-restore.dump');
  const after=fingerprints(),before=JSON.parse(fs.readFileSync(fingerprint,'utf8'));assert.deepEqual(after,before,'Restored baseline metadata/data differs');
  const baseline=requireBaseline();
  const privileges=value("select jsonb_build_object('legacy_view',has_table_privilege('authenticated','public.v_stock_by_product','SELECT'),'legacy_pin',has_function_privilege('authenticated','public.kiosk_verify_pin(text)','EXECUTE'));");
  assert.equal(privileges.legacy_view,true);assert.equal(privileges.legacy_pin,true);
  record(action==='prove'?'PRE_RESTORE_PROOF':'FINAL_RESTORE',{status:'PASS',sha256:hash(dump),baseline,metadataAndDataEqual:true,privileges});
  console.log('PASS '+action+' restore: full baseline fingerprints and effective legacy privileges match');
 }catch(e){record(action==='prove'?'PRE_RESTORE_PROOF':'FINAL_RESTORE',{status:'FAIL',reason:'Restore or fingerprint assertion failed; private material retained; no retry authorized'});throw e;}
}
