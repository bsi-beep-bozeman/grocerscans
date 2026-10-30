import fs from 'node:fs';
import {spawn,execFileSync} from 'node:child_process';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
export {assert,randomUUID};
export const target='supabase_db_shelflife-ch06-validation';
export const evidence=process.env.CH06_EVIDENCE??'handoffs/2026-10-15/ch06-admin-setup-validation';
export const privateDir='.cache/ch06-validation/private';
export const quote=v=>"'"+String(v).replaceAll("'","''")+"'";
export const json=v=>quote(JSON.stringify(v))+'::jsonb';
export const sleep=ms=>new Promise(r=>setTimeout(r,ms));
export const docker=(...args)=>execFileSync('docker',['--context','desktop-linux',...args],{encoding:'utf8',maxBuffer:16*1024*1024});
export class Session {
 constructor(name) {
  this.name=name; this.buffer=''; this.errors=''; this.pending=null;
  this.proc=spawn('docker',['--context','desktop-linux','exec','-i',target,'psql','-U','postgres','-d','postgres','-X','-qAt','-v','ON_ERROR_STOP=1'],{stdio:['pipe','pipe','pipe']});
  this.proc.stdout.setEncoding('utf8');
  this.proc.stdout.on('data',c=>{this.buffer+=c;this.consume();});
  this.proc.stderr.setEncoding('utf8'); this.proc.stderr.on('data',c=>this.errors+=c);
  this.proc.on('exit',code=>{this.closed=true;if(this.pending){clearTimeout(this.pending.timeout);this.pending.reject(Error('SQL session exited '+code+': '+this.errors));this.pending=null;}});
  this.proc.on('error',e=>this.pending?.reject(e));
 }
 consume(){
  if(!this.pending)return;
  const end=this.buffer.indexOf(this.pending.marker+'\n'); if(end<0)return;
  const result=this.buffer.slice(0,end).trim(); this.buffer=this.buffer.slice(end+this.pending.marker.length+1);
  const p=this.pending;this.pending=null;clearTimeout(p.timeout);p.resolve(result);
 }
 raw(sql){
  if(this.closed)throw Error('SQL session already closed');
  if(this.pending)throw Error('Concurrent query on one SQL session');
  return new Promise((resolve,reject)=>{
   const marker='END_'+randomUUID().replaceAll('-','');
   const timeout=setTimeout(()=>{this.proc.kill();reject(Error('SQL harness timeout'));},20000);
   this.pending={marker,resolve,reject,timeout};
   this.proc.stdin.write(sql+'\n\\echo '+marker+'\n');
  });
 }
 async init(){
  await this.raw(`set application_name=${quote(this.name)}; set statement_timeout='15s'; set lock_timeout='5s';
   create function pg_temp.attempt(q text) returns jsonb language plpgsql as $$ declare v jsonb; begin execute q into v; return jsonb_build_object('ok',true,'value',v); exception when others then return jsonb_build_object('ok',false,'code',sqlstate,'message',sqlerrm); end $$;`);
  this.pid=JSON.parse(await this.raw('select to_jsonb(pg_backend_pid());'));return this;
 }
 async q(sql){return JSON.parse(await this.raw('select pg_temp.attempt('+quote(sql)+');'));}
 async value(sql){const r=await this.q(sql);assert.equal(r.ok,true,JSON.stringify(r));return r.value;}
 async identity(id,seconds=3600){await this.raw(`set request.jwt.claims=${quote(JSON.stringify({sub:id,exp:Date.now()/1000+seconds,role:'authenticated'}))};`);}
 async begin(){await this.raw('begin;');}
 async commit(){await this.raw('commit;');}
 async rollback(){await this.raw('rollback;');}
 async close(){if(this.closed)return;try{if(!this.pending)await this.raw('rollback;');}finally{this.proc.stdin.end('\\q\n');}}
}
export const policy={supplier_requirement:'optional',reference_requirement:'optional',lot_requirement:'optional',entry_modes:['manual'],label_profile:'manual_only',expiry_mode:'printed'};
export async function fixture(db,label,{adminId=randomUUID(),authUser=true}={}){
 const f={org:randomUUID(),branch:randomUUID(),branch2:randomUUID(),category:randomUUID(),product:randomUUID(),admin:adminId};
 await db.raw(`begin;
 ${authUser?`insert into auth.users(id) values(${quote(f.admin)});`:''}
 insert into public.orgs(id,name) values(${quote(f.org)},${quote(label)});
 insert into public.branches(id,org_id,name,timezone) values(${quote(f.branch)},${quote(f.org)},'A1','Australia/Perth'),(${quote(f.branch2)},${quote(f.org)},'A2','Australia/Perth');
 insert into public.staff_profiles(id,org_id,branch_id,display_name,role) values(${quote(f.admin)},${quote(f.org)},${quote(f.branch)},'Synthetic admin','admin');
 insert into public.categories(id,org_id,name,expiry_mode) values(${quote(f.category)},${quote(f.org)},'Synthetic category','printed');
 insert into public.products(id,org_id,name,category_id) values(${quote(f.product)},${quote(f.org)},'Synthetic product',${quote(f.category)}); commit;`);
 await db.identity(f.admin);
 const l=await db.value(`select public.mutate_setup_location(${json({operation_id:randomUUID(),action:'create',branch_id:f.branch,expected_revision:0,name:'Receiving',reason:'Synthetic fixture'})})`);
 f.location=l.catalog.locations.find(x=>x.branch_id===f.branch).id;
 const p=await db.value(`select public.mutate_setup_preset(${json({operation_id:randomUUID(),action:'create',expected_revision:0,name:'Synthetic preset',reason:'Synthetic fixture',policy})})`);
 f.preset=p.preset_version.preset_id;f.presetVersion=p.preset_version.id;
 f.cfg={schema_version:1,store:{display_name:'Synthetic store',country:'AU',region:'WA',timezone:'Australia/Perth',confirmed:true},units:[{code:'each',precision:0}],receiving:{location_ids:[f.location],hold_location_id:f.location,exception_role:'admin'},bindings:[{category_id:f.category,preset_version_id:f.presetVersion}],products:[{product_id:f.product,stock_unit:'each',pack_name:'Single',pack_count:1}]};
 f.saved=await db.value(save(f,0,f.cfg));return f;
}
export const save=(f,rev,cfg=f.cfg,op=randomUUID(),branch=f.branch)=>`select public.save_store_setup(${quote(branch)},${quote(op)},${rev},${json(cfg)})`;
export const activate=(f,rev=1,active=0,op=randomUUID())=>`select public.activate_store_setup(${quote(f.branch)},${quote(op)},${quote(f.saved.draft.id)},${rev},${active},'Synthetic activation')`;
export const mutate=(kind,request)=>`select public.mutate_setup_${kind}(${json(request)})`;
export async function blocked(observer,session){
 const deadline=Date.now()+3500;
 while(Date.now()<deadline){
  const row=await observer.value(`select to_jsonb(x) from (select pid,wait_event_type,wait_event,pg_blocking_pids(pid) as blockers from pg_stat_activity where pid=${session.pid}) x`);
  if(row?.wait_event_type==='Lock'&&row.blockers.length)return row;
  await sleep(40);
 }
 throw Error('Expected lock wait not observed');
}
export async function inventory(db){
 const out={};
 for(const t of ['batches','alerts','receiving_events','rounds','round_items','audit_log'])out[t]=await db.value(`select jsonb_build_object('count',count(*),'sha',md5(coalesce(string_agg(to_jsonb(t)::text,E'\\n' order by id),''))) from public.${t} t`);
 return out;
}
export async function sentinels(db,f){
 const batch=randomUUID(),round=randomUUID();
 await db.raw(`begin;
 insert into public.batches(id,org_id,branch_id,product_id,quantity_received,quantity_remaining,expiry_date,expiry_source,notes) values(${quote(batch)},${quote(f.org)},${quote(f.branch)},${quote(f.product)},3,2,'2030-01-01','printed','Synthetic sentinel');
 insert into public.receiving_events(org_id,branch_id,notes) values(${quote(f.org)},${quote(f.branch)},'Synthetic sentinel');
 insert into public.alerts(org_id,branch_id,batch_id,threshold_days,notes) values(${quote(f.org)},${quote(f.branch)},${quote(batch)},7,'Synthetic sentinel');
 insert into public.rounds(id,org_id,branch_id,shift,notes) values(${quote(round)},${quote(f.org)},${quote(f.branch)},'opening','Synthetic sentinel');
 insert into public.round_items(round_id,batch_id,status,notes) values(${quote(round)},${quote(batch)},'ok','Synthetic sentinel');
 insert into public.audit_log(org_id,branch_id,actor_channel,action,metadata) values(${quote(f.org)},${quote(f.branch)},'web','synthetic_sentinel','{"sentinel":true}'); commit;`);
}
export function record(file,results){fs.writeFileSync(evidence+'/'+file,JSON.stringify(results,null,2));}
