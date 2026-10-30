import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {assert,inspect,docker,target,services,evidence,hash,record,requireBaseline} from './target-check.mjs';
const action=process.argv[2];assert.ok(['apply','start-api','sql-cases','stop'].includes(action));
inspect();
if(action==='apply'){
 assert.equal(JSON.parse(fs.readFileSync(path.join(evidence,'PRE_RESTORE_PROOF.json'),'utf8')).status,'PASS');
 requireBaseline();
 const manifest=JSON.parse(fs.readFileSync(path.join(evidence,'MIGRATION_MANIFEST.json'),'utf8').replace(/^\uFEFF/,''));
 for(const entry of manifest)assert.equal(hash(entry.path),entry.sha256,'Reviewed migration changed');
 const results=[];
 for(const entry of manifest.filter(x=>!x.baseline)){
  const file=path.basename(entry.path),version=file.split('_')[0],name=file.slice(15,-4);
  assert.match(version,/^\d{14}$/);assert.match(name,/^[a-z_]+$/);
  const migration=fs.readFileSync(entry.path,'utf8');
  const history=`\ninsert into supabase_migrations.schema_migrations(version,name,statements) values ('${version}','${name}',array[]::text[]);\n`;
  const r=spawnSync('docker',['--context','desktop-linux','exec','-i',target,'psql','-U','postgres','-d','postgres','-X','-v','ON_ERROR_STOP=1','-1'],{input:migration+history,encoding:'utf8'});
  // Migration source contains no test/runtime credentials; preserve exact compile errors.
  fs.writeFileSync(path.join(evidence,file+'.log'),r.stdout+r.stderr);
  results.push({file,sha256:entry.sha256,exitCode:r.status});record('MIGRATION_EXECUTION',results);
  console.log(JSON.stringify(results.at(-1)));
  if(r.status!==0)throw Error('Migration failed: stop for reviewed source amendment; no automatic repair');
 }
}else if(action==='start-api'){
 const log=JSON.parse(fs.readFileSync(path.join(evidence,'MIGRATION_EXECUTION.json'),'utf8'));assert.equal(log.length,5);assert.ok(log.every(x=>x.exitCode===0));
 docker('start',...services.filter(x=>x!==target));console.log('Started only four approved dependent services');
}else if(action==='sql-cases'){
 // Expand only the four reviewed local harness files; transaction rolls back.
 const dir='product/supabase/tests';let source=fs.readFileSync(path.join(dir,'receiving_auth_harness.sql'),'utf8');
 source=source.replace(/^\\ir (receiving_(?:identity|reads|recovery)\.sql)\r?$/gm,(_,name)=>fs.readFileSync(path.join(dir,name),'utf8'));
 assert.ok(!source.includes('\\ir '));
 const r=spawnSync('docker',['--context','desktop-linux','exec','-i',target,'psql','-U','postgres','-d','postgres','-X','-v','ON_ERROR_STOP=1'],{input:source,encoding:'utf8'});
 fs.writeFileSync(path.join(evidence,'SQL_HARNESS.log'),r.stdout+r.stderr);
 record('SQL_HARNESS',{status:r.status===0?'PASS':'FAIL',exitCode:r.status,layer:'SQL connection with synthetic JWT claims; not actual Auth/API grants'});
 if(r.status!==0)throw Error('SQL harness failed; see source-only sanitized log');console.log('PASS original transactional SQL harness');
}else{docker('stop','--timeout','10',...services);record('OWNED_STOP',{containers:inspect()});console.log('Stopped only five owned services; backups remain stopped');}
