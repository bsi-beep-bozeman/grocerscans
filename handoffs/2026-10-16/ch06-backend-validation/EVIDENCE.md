# Evidence and limitations — 2026-10-16

Original inputs/outputs: [owning Chapter 06 chat](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). Preserve dated October 15 records unchanged. This record adds the successful backend results and subsequent restore failure, superseding earlier interim unknown statements without erasing them.

| Observation | Result and evidence | Limit |
|---|---|---|
| R03/R06 authority | Explicit human approval, [receipt](../../2026-10-15/ch06-admin-setup-validation/APPROVAL_RECEIPT.md). Scoped Docker repair later approved in chat. | R05/delivery separate. |
| CLI | Official 2.118.0 Windows amd64 ZIP checksum verified; executable version checked. [Manifest](../../2026-10-15/ch06-admin-setup-validation/TOOL_MANIFEST.json). | Manifest's runtime-image unknown statement was true before startup; see current runtime record. |
| Runtime | PostgreSQL17.6; Docker Engine29.8.1/Desktop4.93.0. Official service image IDs/digests and stopped states in [RUNTIME.json](RUNTIME.json). | Existing shared Docker workloads exist and were left alone. |
| First five migrations | CLI applied retained September migrations, migration history read back in order, zero organisations before fixtures. | Isolated backend only, not hosted history. |
| Two setup migrations | Both applied with exit0 under individual transactions. [Schema log](../../2026-10-15/ch06-admin-setup-validation/20261013000000_store_setup.sql.log), [API log](../../2026-10-15/ch06-admin-setup-validation/20261013000001_store_setup_api.sql.log). | Migration-history names/versions recorded; statements arrays are empty for these two manual applications. Source hashes provide provenance. |
| Transaction assertions | Exit0, final ROLLBACK. [Log](../../2026-10-15/ch06-admin-setup-validation/TRANSACTION_01.log). | Fixture claims here are SQL session claims; real Auth tested separately. |
| Concurrency | Fresh October16 rerun: 19 groups PASS, explicit blocking PIDs, conflict/retry/timeout, save/activation order, reference history, same/different-org serialization, revocation/expiry after wait. [Results](CONCURRENCY.json). | Groups are acceptance scenarios, not a unit-test count. |
| Active reads | 50 responses around first and subsequent activation; reads dispatched before commit, including overlap at the commit boundary; all version/revision pairs consistent. [Responses](CONCURRENT_RPC_RESPONSES.json). | Finite race sampling, not a proof of all interleavings. |
| Real Auth/API | October15 final run: 23 groups PASS. All six RPCs tested with real sign-in sessions, nine disallowed identity variants, anonymous, cross-org, retry, expiry/tampering, revoked admin and refresh. [Results](../../2026-10-15/ch06-admin-setup-validation/API.json). | Authenticated GUI/SDK adapter flow still R05. Expired/spoofed-token probes use locally signed synthetic JWTs. |
| Lost response | Client deliberately destroyed response-body connection after success headers; exact retry recovered one committed mutation/audit/operation. | This tests known committed response loss; not arbitrary network fault injection. |
| Inventory safety | Nonempty synthetic sentinel rows; counts and deterministic full-row MD5 fingerprints unchanged for batches, alerts, receiving_events, rounds, round_items, audit_log. | Fingerprints are change detection, not security hashes. No live inventory accessed. |
| Dart contract | 61 captured responses: 1 context, 57 state, 3 reference. Production parsers and stable DTO round trips PASS. [Result](DTO_CHECK.json), [inputs](ALL_RPC_RESPONSES.json). | Pure Dart headless decoding; not browser rendering or the Supabase Flutter adapter. |
| Restart | Five target containers restarted; all eight setup table fingerprints and six inventory fingerprints unchanged, fresh password login and exact API response preserved. [Record](../../2026-10-15/ch06-admin-setup-validation/RESTART.json). | Backend restart only; browser/device restart not tested. |
| Backup | Before-setup and tested-state custom-format dumps exist privately and archive lists are readable. Hashes in handoff. | Readable archive does not alone prove restoration. |
| Restore | FAILED restoring `auth` schema owner with limited postgres account. [Failure](RESTORE.json). Corrected harness not executed. | R03 cannot be called complete; disposable DB is partial and stopped. |

## Harness corrections and runtime deviations

1. Docker socket startup error prevented the first launch. Engine was healthy on the next human-approved repair turn, so no socket repair, global stop or reset was performed. [Recovery observation](../../2026-10-15/ch06-admin-setup-validation/DOCKER_RECOVERY.md).
2. Per-network host_binding_ipv4 was insufficient in this runtime. Initial ports55321/55322/55324 appeared as wildcard bindings. Stopped all five target containers on observation. Recreated only db/kong/inbucket with explicit 127.0.0.1 HostIp, retained original stopped containers. Subsequent container and Windows listener checks confirmed loopback-only. No incoming-access audit was captured for the initial interval; do not claim that interval was isolated from LAN.
3. Gateway configuration directory initially copied one level too deep during recreation; startup log identified missing localhost.crt. Copied directory contents to the intended path and restarted only gateway. Corrected rebind harness; gateway became healthy before API tests.
4. API attempt01 duplicated a synthetic supplier name. [Retained failure](../../2026-10-15/ch06-admin-setup-validation/API_ATTEMPT_01.json). Corrected unique fixture names and harness session-close timeout handling.
5. API attempt02's unfiltered DELETE was rejected by an API safeguard before permissions were evaluated. [Retained failure](../../2026-10-15/ch06-admin-setup-validation/API_ATTEMPT_02.json). Added org filter and final full API run passed.
6. The strengthened concurrency rerun was blocked on October15 by automatic approval-review usage exhaustion. The command did not execute; this was not an unsafe-action determination. Resumed under original approval October16, retaining prior evidence and writing fresh results here.
7. Restore harness account choice was wrong for original schema ownership. Confirmed built-in supabase_admin superuser/login and postgres non-superuser via read-only queries. Prepared correction; stopped for the explicitly required retry approval.

## Current boundaries

All target and original binding-backup containers are stopped; no listeners on55321/55322/55324. Proposed browser port8136 had no listener at inspection. Existing product/Onyx workloads remained running (the existing product vector service is restarting; no repair was attempted). No R05 UI action, hosted resource mutation, install beyond approved CLI/runtime, publication, branch change, commit or push.

Seven migration source hashes still match the pre-execution baseline. [Current hashes](MIGRATION_HASHES.json). Earlier Chapter05 local test results are historical and were not rerun. The exact application bundle and physical-device behavior remain unknown.

## Documentation verification

Navigation and acceptance records were reconciled without changing the prior 57 ledger event rows. The initial preservation comparison encountered a CRLF/LF normalization mismatch; the ledger's original CRLF convention was restored. Local references, seven migration hashes, syntax of seven JavaScript harnesses and the durable-file JWT scan passed. `git diff --check` passed with line-ending warnings for inherited tracked files. The machine-readable result is [DOCUMENTATION_CHECK.json](DOCUMENTATION_CHECK.json). These are documentation/source checks; the corrected restore and R05 remain unexecuted.
