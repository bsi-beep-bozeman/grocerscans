import {Session,fixture,save,activate,mutate,blocked,inventory,sentinels,policy,quote,json,randomUUID,assert,sleep,record} from './common.mjs';
const results=[];const sessions=[];
const make=async n=>{const s=await new Session('ch06-'+n).init();sessions.push(s);return s;};
const db=await make('observer'),a=await make('A'),b=await make('B');
let checks=0;
const pass=(label,details={})=>{results.push({label,status:'PASS',...details});checks++;record('CONCURRENCY.json',{checks,results});console.log('PASS '+label);};
const expect=(r,code)=>assert.equal(r.code,code,JSON.stringify(r));
const counts=f=>db.value(`select jsonb_build_object('audit',(select count(*) from public.setup_audit where org_id=${quote(f.org)}),'operations',(select count(*) from public.setup_operations where org_id=${quote(f.org)}),'versions',(select count(*) from public.store_setup_versions where org_id=${quote(f.org)}))`);
async function race(f,qa,qb,expected='PT409'){
 await a.identity(f.admin);await b.identity(f.admin);await a.begin();await b.begin();
 const before=await counts(f),ra=await a.q(qa);assert.equal(ra.ok,true,JSON.stringify(ra));
 const pending=b.q(qb),wait=await blocked(db,b);await a.commit();const rb=await pending;
 if(expected==='same'){assert.deepEqual(rb,ra);await b.commit();}else{expect(rb,expected);await b.rollback();}
 const after=await counts(f);assert.equal(after.audit,before.audit+1);assert.equal(after.operations,before.operations+1);
 return {ra,rb,wait,after};
}
try {
 const sentinel=await fixture(db,'Concurrency sentinels');await sentinels(db,sentinel);const beforeInventory=await inventory(db);
 for(const t of Object.values(beforeInventory))assert.ok(t.count>0);
 let f=await fixture(db,'Different saves');let r=await race(f,save(f,1),save(f,1,{...f.cfg,store:{...f.cfg.store,display_name:'Other'}}));
 pass('1a competing saves: observed lock, one success, PT409, one audit/operation',{lock:r.wait});
 f=await fixture(db,'Identical saves');let op=randomUUID();let query=save(f,1,f.cfg,op);r=await race(f,query,query,'same');
 pass('1b identical concurrent retry returns exact committed response once',{lock:r.wait});
 await b.identity(f.admin);expect(await b.q(save(f,1,{schema_version:1},op)),'PT409');expect(await b.q(activate(f,2,0,op)),'PT409');
 pass('1c changed payload/action with same operation is rejected');
 f=await fixture(db,'Lock timeout');await a.identity(f.admin);await b.identity(f.admin);await a.begin();await b.begin();await a.value(save(f,1));
 const timeoutPending=b.q(save(f,1));const timeoutWait=await blocked(db,b);expect(await timeoutPending,'55P03');await b.rollback();await a.commit();expect(await b.q(save(f,1)),'PT409');
 pass('1d bounded five-second lock timeout, rollback, retry conflict',{lock:timeoutWait});
 f=await fixture(db,'Activation race');op=randomUUID();r=await race(f,activate(f,1,0,op),activate(f));assert.equal(r.after.versions,1);
 assert.deepEqual(await b.q(activate(f,1,0,op)),r.ra);pass('2 competing activation yields one immutable version; exact retry is stable',{lock:r.wait});
 f=await fixture(db,'Save wins');await race(f,save(f,1),activate(f));assert.equal((await counts(f)).versions,0);pass('3a save wins: stale draft activation denied');
 f=await fixture(db,'Activation wins');await a.identity(f.admin);await b.identity(f.admin);await a.begin();await b.begin();
 const published=await a.value(activate(f));const savePending=b.q(save(f,1,{...f.cfg,store:{...f.cfg.store,display_name:'Later'}}));await blocked(db,b);await a.commit();assert.equal((await savePending).ok,true);await b.commit();
 const stored=await db.value(`select configuration from public.store_setup_versions where id=${quote(published.active.id)}`);assert.deepEqual(stored,f.cfg);pass('3b activation wins: later draft save leaves frozen snapshot unchanged');
 for(const kind of ['preset','location']){
  f=await fixture(db,'Deactivation wins '+kind);
  const req={operation_id:randomUUID(),action:'deactivate',expected_revision:1,reason:'Synthetic deactivation',[kind+'_id']:f[kind],...(kind==='location'?{branch_id:f.branch}:{})};
  await race(f,mutate(kind,req),activate(f),'PT422');pass('4a '+kind+' deactivation wins and prevents activation');
 }
 f=await fixture(db,'Activation before reference edit');await a.identity(f.admin);await b.identity(f.admin);await a.begin();await b.begin();
 const frozen=await a.value(activate(f));const refPending=b.q(mutate('location',{operation_id:randomUUID(),action:'rename',branch_id:f.branch,location_id:f.location,expected_revision:1,name:'Renamed after activation',reason:'Synthetic'}));
 await blocked(db,b);await a.commit();const frozenRecord=await db.value(`select to_jsonb(v) from public.store_setup_versions v where id=${quote(frozen.active.id)}`);assert.equal((await refPending).ok,true);await b.commit();
 await b.value(mutate('preset',{operation_id:randomUUID(),action:'edit',preset_id:f.preset,expected_revision:1,name:'Edited later',reason:'Synthetic',policy:{...policy,lot_requirement:'required'}}));
 assert.deepEqual(await db.value(`select to_jsonb(v) from public.store_setup_versions v where id=${quote(frozen.active.id)}`),frozenRecord);pass('4b activation wins: later location/preset edits preserve full immutable snapshot');
 for(const kind of ['preset','location']){
  f=await fixture(db,'Reference edit race '+kind);
  const request={operation_id:randomUUID(),action:kind==='preset'?'edit':'rename',expected_revision:1,reason:'Synthetic',name:'Changed',[kind+'_id']:f[kind],...(kind==='location'?{branch_id:f.branch}:{policy})};
  await race(f,mutate(kind,request),mutate(kind,{...request,operation_id:randomUUID(),name:'Other'}));pass('5a competing '+kind+' edit: one revision succeeds');
 }
 f=await fixture(db,'Same org branches');await a.identity(f.admin);await b.identity(f.admin);await a.begin();await b.begin();await a.value(save(f,1));
 const otherBranch=b.q(save(f,0,{schema_version:1},randomUUID(),f.branch2));await blocked(db,b);await a.commit();assert.equal((await otherBranch).ok,true);await b.commit();pass('5b same organisation different branches serialize');
 const f2=await fixture(db,'Different org');await a.identity(f.admin);await b.identity(f2.admin);await a.begin();await b.begin();await a.value(save(f,2));
 const independent=await b.q(save(f2,1));assert.equal(independent.ok,true);await b.commit();await a.commit();pass('5c distinct organisations make progress while other org lock is held');
 for(const retry of [false,true]){
  f=await fixture(db,'Revoked waiter '+retry);op=randomUUID();query=save(f,1,f.cfg,op);if(retry){await db.identity(f.admin);await db.value(query);}
  await a.begin();await a.raw(`select id from public.orgs where id=${quote(f.org)} for update;`);await b.identity(f.admin);await b.begin();
  const before=await counts(f),pending=b.q(query);await blocked(db,b);await db.raw(`update public.staff_profiles set active=false where id=${quote(f.admin)};`);await a.commit();expect(await pending,'42501');await b.rollback();assert.deepEqual(await counts(f),before);
  pass('6a revoked admin after lock wait denied '+(retry?'even for recorded retry':'for fresh operation'));
 }
 f=await fixture(db,'Expiry waiter');await a.begin();await a.raw(`select id from public.orgs where id=${quote(f.org)} for update;`);await b.identity(f.admin,1.5);await b.begin();
 const beforeExpiry=await counts(f),expiryPending=b.q(save(f,1));await blocked(db,b);await sleep(1700);await a.commit();expect(await expiryPending,'PT401');await b.rollback();assert.deepEqual(await counts(f),beforeExpiry);pass('6b JWT expiring while blocked is rechecked, no side effects');
 f=await fixture(db,'Active pair reads');await a.identity(f.admin);await b.identity(f.admin);
 const pairs=[],pairResponses=[];
 for(const current of [0,1]){
  await a.begin();await a.value(activate(f,1,current));
  for(let i=0;i<25;i++){
   const read=b.value(`select public.get_store_setup(${quote(f.branch)})`);
   if(i===10)await a.commit();
   const state=await read;
   assert.equal(state.active?.version??0,state.active_revision);pairs.push({revision:state.active_revision,version:state.active?.version??null});
   pairResponses.push({type:'state',name:'get_store_setup_concurrent',data:state});
  }
 }
 assert.ok(pairs.some(p=>p.revision===0)&&pairs.some(p=>p.revision===1)&&pairs.some(p=>p.revision===2));
 pass('7 first and subsequent activation: 50 read responses have consistent version/revision pairs',{pairs});
 record('CONCURRENT_RPC_RESPONSES.json',pairResponses);
 assert.deepEqual(await inventory(db),beforeInventory);pass('Inventory and operational audit counts AND row checksums unchanged',{inventory:beforeInventory});
 record('CONCURRENCY.json',{status:'PASS',checks,results});
} catch(e){record('CONCURRENCY.json',{status:'FAIL',checks,results,error:e.message});throw e;}
finally{for(const s of sessions)await s.close();}
