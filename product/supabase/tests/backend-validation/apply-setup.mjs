import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const container='supabase_db_shelflife-ch06-validation';
const evidence=process.env.CH06_EVIDENCE??'handoffs/2026-10-15/ch06-admin-setup-validation';
for(const file of ['20261013000000_store_setup.sql','20261013000001_store_setup_api.sql']) {
  const version=file.split('_')[0], name=file.slice(15,-4);
  const sql=fs.readFileSync(path.join('product/supabase/migrations',file),'utf8');
  const history=`\ninsert into supabase_migrations.schema_migrations(version,name,statements) values ('${version}','${name}',array[]::text[]);\n`;
  const r=spawnSync('docker',['--context','desktop-linux','exec','-i',container,'psql','-U','postgres','-d','postgres','-X','-v','ON_ERROR_STOP=1','-1'],{input:sql+history,encoding:'utf8'});
  fs.writeFileSync(path.join(evidence,file+'.log'),r.stdout+r.stderr);
  console.log(JSON.stringify({migration:file,exitCode:r.status,output:(r.stdout+r.stderr).slice(-1200)}));
  if(r.status!==0) process.exit(1);
}
