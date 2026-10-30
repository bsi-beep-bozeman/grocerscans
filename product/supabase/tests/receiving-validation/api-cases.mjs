import {randomUUID} from 'node:crypto';
import {assert,inspect,sql,value,record} from './target-check.mjs';
import {readFixture,saveFixture,rpc,request,ok,q,j,login} from './fixtures.mjs';
inspect();const f=readFixture(),a=f.accounts,id=f.ids,results=[];
const check=(condition,label)=>{if(!condition)throw Error(label);};
const pattern=process.env.S2A_CASE_PATTERN?new RegExp(process.env.S2A_CASE_PATTERN):null;
const report=pattern?'API_CASES_RECHECK':'API_CASES';
async function test(label,fn){if(pattern&&!pattern.test(label))return;try{await fn();results.push({label,status:'PASS'});console.log('PASS '+label);}catch(e){results.push({label,status:'FAIL',reason:String(e.message).slice(0,200)});console.log('FAIL '+label);}record(report,{results,passed:results.filter(x=>x.status==='PASS').length,failed:results.filter(x=>x.status==='FAIL').length});}
const begin=async(label='staff-a1',device='kiosk-a1')=>{const r=ok(await rpc('begin_staff_session_v1',{p_pin:f.pins[label]},a[device]),'begin');check(r.ok===true,'expected successful synthetic PIN');return r;};
const args=s=>({p_session_id:s.session.id,p_session_secret:s.session.secret});
const catalog=(s,device='kiosk-a1',extra={})=>rpc('get_receiving_catalog_v1',{...args(s),p_query:{kind:'all',value:''},p_limit:50,...extra},a[device]);
const deny=r=>check([401,403,404].includes(r.status),'Expected denied status, received '+r.status);
const inventory=()=>value("select jsonb_object_agg(t,d) from (select 'batches' t,md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) d from public.batches x union all select 'alerts',md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) from public.alerts x union all select 'receiving',md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) from public.receiving_events x union all select 'rounds',md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) from public.rounds x union all select 'round_items',md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) from public.round_items x union all select 'audit',md5(coalesce(jsonb_agg(to_jsonb(x) order by id)::text,'')) from public.audit_log x) s;");
await test('A01: all29 actual Auth identity contexts',async()=>{for(const [label,user]of Object.entries(a)){const r=ok(await rpc('get_receiving_context_v1',{},user),label);check(r.kind===user.expectedContext,'Context mismatch '+label);}});
await test('A01: inactive conflicting profiles still deny receiving',async()=>{
 for(const label of ['conflict-kiosk-staff','conflict-kiosk-supplier','conflict-admin-kiosk','conflict-admin-supplier']){
  const table=label.endsWith('supplier')?'supplier_profiles':label==='conflict-admin-kiosk'?'kiosk_devices':'staff_profiles',column=table==='kiosk_devices'?'device_auth_user_id':'id';
  sql(`update public.${table} set active=false where ${column}=${q(a[label].id)};`);
  try{check(ok(await rpc('get_receiving_context_v1',{},a[label]),label).kind==='unavailable','Inactive conflict bypass');}finally{sql(`update public.${table} set active=true where ${column}=${q(a[label].id)};`);}
 }
});
await test('A03: cross-device and tenant replay, forged secret, predecessor revocation',async()=>{
 const s=await begin();for(const device of ['kiosk-a1b','kiosk-a2','kiosk-b1'])deny(await catalog(s,device));
 deny(await catalog(s,'kiosk-a1',{p_session_secret:'x'.repeat(44)}));const next=await begin();deny(await catalog(s));check((await catalog(next)).status===200,'new session failed');
 check(value(`select to_jsonb(expires_at-issued_at=interval '8 hours' and octet_length(secret_digest)=32) from private.receiving_staff_sessions where id=${q(next.session.id)};`)===true,'Lifetime/digest constraint');
});
await test('A03: current PIN, actor, device, lead and session revocation checks',async()=>{
 for(const mutation of ['actor','pin','device','lead','revocation','expiry']){
  const s=await begin();const actor=q(a['staff-a1'].id),device=q(id['device-kiosk-a1']);
  let undo='';
  if(mutation==='actor'){sql(`update public.staff_profiles set active=false where id=${actor};`);undo=`update public.staff_profiles set active=true where id=${actor};`;}
  if(mutation==='pin'){sql(`update public.staff_profiles set pin_last_changed_at=clock_timestamp() where id=${actor};`);}
  if(mutation==='device'){sql(`update public.kiosk_devices set active=false where id=${device};`);undo=`update public.kiosk_devices set active=true where id=${device};`;}
  if(mutation==='lead'){sql(`update public.staff_profiles set is_shift_lead=true where id=${actor};`);undo=`update public.staff_profiles set is_shift_lead=false where id=${actor};`;}
  if(mutation==='revocation')sql(`update private.receiving_staff_sessions set revoked_at=clock_timestamp() where id=${q(s.session.id)};`);
  if(mutation==='expiry')sql(`update private.receiving_staff_sessions set issued_at=current_timestamp-interval '9 hours',expires_at=current_timestamp-interval '1 hour' where id=${q(s.session.id)};`);
  try{deny(await catalog(s));}finally{if(undo)sql(undo);}
 }
});
await test('A04: effective legacy/private/S1 helper privileges and owned audit sequence',async()=>{
 const t=['orgs','branches','staff_profiles','kiosk_devices','categories','suppliers','products','batches','purchase_orders','po_lines','receiving_events','alerts','rounds','round_items','temp_logs','audit_log','supplier_profiles','v_upcoming_shipments','v_stock_by_product','v_supplier_scorecard','v_waste_recovery','v_alert_response_times'];
 for(const role of ['anon','authenticated'])for(const table of t){check(value(`select to_jsonb(has_table_privilege(${q(role)},${q('public.'+table)},'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') or has_any_column_privilege(${q(role)},${q('public.'+table)},'SELECT,INSERT,UPDATE,REFERENCES'));`)===false,'Legacy privilege '+role+' '+table);}
 const state=value("select jsonb_build_object('schema',has_schema_privilege('authenticated','private','USAGE'),'sequence',has_sequence_privilege('authenticated','public.audit_log_id_seq','USAGE,SELECT,UPDATE'),'helpers',(select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where (n.nspname='private' or (n.nspname='public' and p.proname like '\\_setup\\_%')) and (has_function_privilege('authenticated',p.oid,'EXECUTE') or has_function_privilege('anon',p.oid,'EXECUTE'))));");
 check(!state.schema&&!state.sequence&&state.helpers===0,'Private/helper/sequence grant');record('EFFECTIVE_ACL',{status:'PASS',legacyObjects:t.length,roles:['anon','authenticated'],...state,privateDefaultPrivilegeStatement:'ABSENT in source; future-object default contract remains unresolved',realtimeTransport:'NOT RUN: service not approved'});
});
await test('A04: real API direct tables, views, joins and helper requests denied',async()=>{
 for(const label of ['kiosk-a1','admin-a','viewer-a','supplier-a','staff-a1']){
  for(const table of ['staff_profiles','products','batches','audit_log','v_stock_by_product','v_supplier_scorecard','store_setup_drafts'])deny(await request('/rest/v1/'+table+'?select=*',undefined,a[label].token,'GET'));
  deny(await request('/rest/v1/products?select=id,unit_cost_cents,categories(*)',undefined,a[label].token,'GET'));
  for(const name of ['current_staff','refresh_alerts','_setup_actor'])deny(await rpc(name,{},a[label]));
 }
 deny(await request('/rest/v1/products?select=*',undefined,undefined,'GET'));
});
await test('A05: exact safe catalog projection, leading zeros and pagination',async()=>{
 const s=await begin();const one=ok(await catalog(s,'kiosk-a1',{p_query:{kind:'upc',value:'001234'}}),'UPC');check(one.items.length===1&&one.items[0].upc==='001234','leading zero');
 check(Object.keys(one.items[0]).sort().join(',')==='category_id,category_name,default_supplier_id,id,name,sku,upc','exact safe field allowlist');
 const ids=[];let after=null;do{const r=ok(await catalog(s,'kiosk-a1',{p_after_id:after}),'page');ids.push(...r.items.map(x=>x.id));after=r.next_after_id;}while(after);
 check(ids.length===106&&new Set(ids).size===106,'pagination completeness');check(!ids.includes(id['product-b-zero']),'cross tenant leak');
 for(const limit of [0,101])check((await catalog(s,'kiosk-a1',{p_limit:limit})).status===422,'invalid limit');
 for(const limit of [1,100])check(ok(await catalog(s,'kiosk-a1',{p_limit:limit}),'limit').items.length===limit,'valid limit');
 check((await catalog(s,'kiosk-a1',{p_query:{kind:'all',value:'',extra:true}})).status===422,'extra query field');
 const p=ok(await rpc('get_receiving_policy_v1',{...args(s),p_product_id:id['product-a-zero']},a['kiosk-a1']),'missing policy');check(p.setup===null&&!p.readiness.can_confirm&&p.readiness.blocking_codes.includes('setup_missing'),'missing policy not disclosed');
});
await test('A02: ambiguous PIN counts as denial',async()=>{
 sql(`update public.staff_profiles set active=true,pin_hash=(select pin_hash from public.staff_profiles where id=${q(a['staff-a1'].id)}) where id=${q(a['duplicate-pin-a1'].id)};`);
 try{const r=ok(await rpc('begin_staff_session_v1',{p_pin:f.pins['staff-a1']},a['kiosk-a1']),'ambiguous');check(r.ok===false&&r.error.code==='verification_failed','ambiguous PIN accepted');}
 finally{sql(`update public.staff_profiles set active=false where id=${q(a['duplicate-pin-a1'].id)};`);}
 await begin();
});
await test('A10: recovery denies ordinary/foreign actors and audits disabled-owner recovery',async()=>{
 const original=await begin();deny(await rpc('recover_receiving_partition_v1',{...args(original),p_original_actor_id:a['staff-a1'].id,p_reason:'Synthetic reason'},a['kiosk-a1']));
 const lead=await begin('lead-a1');sql(`update public.staff_profiles set active=false where id=${q(a['staff-a1'].id)};`);
 try{
  const recovered=ok(await rpc('recover_receiving_partition_v1',{...args(lead),p_original_actor_id:a['staff-a1'].id,p_reason:'Synthetic connected recovery'},a['kiosk-a1']),'recovery');
  check(recovered.key_b64===original.vault.key_b64,'wrong recovered key');check(recovered.original_actor_id===a['staff-a1'].id&&recovered.recovering_actor_id===a['lead-a1'].id,'recovery attribution');
  check(value(`select to_jsonb(count(*)=1) from private.receiving_identity_audit where recovery_id=${q(recovered.recovery_id)};`),'recovery audit missing');
  deny(await rpc('recover_receiving_partition_v1',{...args(lead),p_original_actor_id:a['staff-b1'].id,p_reason:'Synthetic denied'},a['kiosk-a1']));
 }finally{sql(`update public.staff_profiles set active=true where id=${q(a['staff-a1'].id)};`);}
});
await test('S1: six retained endpoints, ready configuration, exact retry and stale conflict',async()=>{
 const admin=a['admin-a'];ok(await rpc('get_admin_setup_context',{},admin),'admin context');
 const loc=ok(await rpc('mutate_setup_location',{p_request:{operation_id:randomUUID(),action:'create',branch_id:id['branch-a1'],expected_revision:0,name:'S2A C10 receiving',reason:'Synthetic connected validation'}},admin),'location');f.location=loc.catalog.locations.find(x=>x.branch_id===id['branch-a1']).id;
 const hold=ok(await rpc('mutate_setup_location',{p_request:{operation_id:randomUUID(),action:'create',branch_id:id['branch-a1'],expected_revision:0,name:'S2A C10 hold',reason:'Synthetic connected validation'}},admin),'hold');f.hold=hold.catalog.locations.find(x=>x.name==='S2A C10 hold').id;
 const policy={supplier_requirement:'optional',reference_requirement:'optional',lot_requirement:'optional',entry_modes:['manual'],label_profile:'manual_only',expiry_mode:'printed'};
 const preset=ok(await rpc('mutate_setup_preset',{p_request:{operation_id:randomUUID(),action:'create',expected_revision:0,name:'S2A C10 printed',reason:'Synthetic connected validation',policy}},admin),'preset');f.preset=preset.preset_version;
 f.cfg={schema_version:1,store:{display_name:'S2A C10 Synthetic',country:'AU',region:'WA',timezone:'Australia/Perth',confirmed:true},units:[{code:'each',precision:0}],receiving:{location_ids:[f.location],hold_location_id:f.hold,exception_role:'lead'},bindings:[{category_id:id['category-a-printed'],preset_version_id:f.preset.id}],products:[{product_id:id['product-a-zero'],stock_unit:'each',pack_name:'Single',pack_count:1}],restrictions:{past_date_markdown_allowed:false,past_date_donation_allowed:false,action_confirmation_required:true}};
 const payload={p_branch_id:id['branch-a1'],p_operation_id:randomUUID(),p_expected_revision:0,p_configuration:f.cfg};
 const saved=ok(await rpc('save_store_setup',payload,admin),'save');const retry=ok(await rpc('save_store_setup',payload,admin),'retry');check(JSON.stringify(saved)===JSON.stringify(retry),'exact retry');
 check((await rpc('save_store_setup',{...payload,p_operation_id:randomUUID()},a['admin-a2'])).status===409,'stale conflict');
 f.active=ok(await rpc('activate_store_setup',{p_branch_id:id['branch-a1'],p_operation_id:randomUUID(),p_draft_id:saved.draft.id,p_expected_draft_revision:1,p_expected_active_revision:0,p_reason:'Synthetic connected validation'},admin),'activate');
 check(ok(await rpc('get_store_setup',{p_branch_id:id['branch-a1']},admin),'load').active_revision===1,'active pointer');saveFixture(f);
});
await test('S1: all six endpoints deny non-admin roles, cross-tenant reads denied',async()=>{
 const calls=[['get_admin_setup_context',{}],['get_store_setup',{p_branch_id:id['branch-a1']}],['save_store_setup',{p_branch_id:id['branch-a1'],p_operation_id:randomUUID(),p_expected_revision:1,p_configuration:f.cfg}],['activate_store_setup',{p_branch_id:id['branch-a1'],p_operation_id:randomUUID(),p_draft_id:randomUUID(),p_expected_draft_revision:1,p_expected_active_revision:1,p_reason:'Synthetic'}],['mutate_setup_preset',{p_request:{}}],['mutate_setup_location',{p_request:{}}]];
 for(const label of ['staff-a1','lead-a1','viewer-a','manager-a','supplier-a','inactive-admin','conflict-admin-kiosk','conflict-admin-supplier'])for(const [name,args]of calls)deny(await rpc(name,args,a[label]));
 deny(await rpc('get_store_setup',{p_branch_id:id['branch-b1']},a['admin-a']));
});
await test('A05: actual ready policy remains draft-only',async()=>{const s=await begin();const r=ok(await rpc('get_receiving_policy_v1',{...args(s),p_product_id:id['product-a-zero']},a['kiosk-a1']),'ready policy');check(r.setup.revision===1&&r.unit.code==='each'&&r.pack.count==='1','ready setup projection');check(r.readiness.can_capture_draft===true&&r.readiness.can_confirm===false,'confirmation unexpectedly enabled');});
record(report,{results,passed:results.filter(x=>x.status==='PASS').length,failed:results.filter(x=>x.status==='FAIL').length});
if(results.some(x=>x.status==='FAIL'))process.exitCode=1;
