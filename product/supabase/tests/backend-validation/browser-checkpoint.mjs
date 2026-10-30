// Read-only verification of the preserved, explicitly approved R05 fixture.
import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {Session,inventory,privateDir,evidence,assert,quote,record} from './common.mjs';
const fixture=JSON.parse(fs.readFileSync(privateDir+'/browser-fixtures.json'));
const op='a27c5c56-f0c4-4aef-b97b-ce8e8e8914d4';
const db=await new Session('ch06_browser_checkpoint_readonly').init();
try {
 const after=await inventory(db);
 assert.deepEqual(after,fixture.beforeInventory);
 const operation=await db.value(`select jsonb_build_object('operations',(select count(*) from public.setup_operations where operation_id=${quote(op)}),'audits',(select count(*) from public.setup_audit where operation_id=${quote(op)}),'saved_revision',(select (response->'draft'->>'revision')::int from public.setup_operations where operation_id=${quote(op)}))`);
 assert.equal(operation.operations,1);assert.equal(operation.audits,1);assert.equal(operation.saved_revision,6);
 const state=await db.value(`select jsonb_build_object('draft_revision',d.revision,'store_name',d.configuration->'store'->>'display_name','active_revision',a.revision,'version_count',(select count(*) from public.store_setup_versions where branch_id=d.branch_id),'active_store_name',v.configuration->'store'->>'display_name','reason',v.reason) from public.store_setup_drafts d join public.store_setup_active a using(branch_id) join public.store_setup_versions v on v.id=a.version_id where d.branch_id=${quote(fixture.f.branch)}`);
 assert.equal(state.draft_revision,6);assert.equal(state.store_name,'Recovered response loss');assert.equal(state.active_revision,1);assert.equal(state.version_count,1);assert.equal(state.reason,'October26 verified UI activation');assert.notEqual(state.active_store_name,state.store_name);
 const baseline=JSON.parse(fs.readFileSync('handoffs/2026-10-15/ch06-admin-setup-validation/SOURCE_HASHES_BEFORE.json'));
 const hashes=baseline.map(x=>({path:x.Path,sha256:createHash('sha256').update(fs.readFileSync(x.Path)).digest('hex'),expected:x.Hash.toLowerCase()}));
 for(const h of hashes)assert.equal(h.sha256,h.expected);
 record('DATABASE_CHECKPOINT.json',{status:'PASS',inventory:after,lostResponseOperation:{id:op,...operation},state,migrations:hashes});
 console.log('PASS: six inventory fingerprints unchanged, one retry operation/audit, draft6/active1, seven migration hashes unchanged');
} finally {await db.close();}
