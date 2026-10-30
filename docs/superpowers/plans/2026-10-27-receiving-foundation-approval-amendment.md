# S2-A implementation, dependency and test approval amendment

2026-10-27 Australia/Perth. Owner: [ShelfLife — Receiving Foundation Contract…](codex://threads/01a17814-e94a-74a1-80fa-d1027c7eff88). Supplements the [Chapter07 packet](2026-10-26-receiving-identity-queue-scope.md) without changing that dated record. Technical scope is the [foundation contract](../specs/2026-10-27-receiving-foundation-contract.md).

## Authority at this checkpoint

Human approval in this chat: “Approved Receiving Foundation Contract and Storage Decision” and “then continue the chapter cycle.” C08-DOC and one C08-TRANSITION are granted. Documentation/source/package metadata review, local documentation checks and closeout are in scope. S2 source implementation, installation, application checks, runtime tests and applied grants are not granted by that named documentation approval. All rows below are proposals. New-chat start remains subject to the exact standing gate.

Selected choices for acceptance with implementation: eight-hour non-sliding staff proof; five-minute local inactivity and five-failure/five-minute durable cooldown; no cold offline unlock; encrypted local records with server-held private partition keys; lead-only partition recovery in A; all legacy direct client access closed on an approved disposable target; existing S1 public RPCs retained. Admin recovery is explicitly unavailable in A until its recent-authentication proof is separately specified. This is a bounded delivery decision, not silently completed admin-recovery coverage.

## S2A-R01: exact local source scope

Authorize only the following new/modified source families. Author tests and migrations but do not execute/apply them under R01. All new paths are proposed, not current evidence. Preserve the seven existing migration files, inherited dirty checkout and S1 behavior.

| Responsibility | Exact proposed files |
|---|---|
| Identity models/API | `app_flutter/lib/identity/identity_models.dart`, `identity_repository.dart`, `supabase_identity_repository.dart`, `staff_session_controller.dart`, `staff_session_gate.dart`, `pin_screen.dart`, `workspace_gate.dart` |
| Draft model and shell | `app_flutter/lib/receiving/receiving_draft.dart`, `receiving_policy.dart`, `receiving_repository.dart`, `supabase_receiving_repository.dart`, `draft_workspace.dart`, `draft_recovery_screen.dart` (foundation editing/saving only, no complete receipt wizard) |
| Storage and state | `app_flutter/lib/sync/draft_store.dart`, `draft_store_factory.dart`, `draft_store_unsupported.dart`, `draft_store_web.dart`, `draft_store_android.dart`, `draft_crypto.dart`, `draft_migrations.dart`, `draft_queue.dart`, `workspace_lifecycle.dart`, `workspace_lifecycle_web.dart`, `workspace_lifecycle_stub.dart` |
| Existing integration | `app_flutter/lib/main.dart`, `app_flutter/lib/supa.dart`; preserve S1 gate via composition. No unrelated S1 refactor, preview change or generic login wording fix. |
| Android backup exclusions | `app_flutter/android/app/src/main/AndroidManifest.xml`, new `app_flutter/android/app/src/main/res/xml/receiving_backup_rules.xml`, `receiving_data_extraction_rules.xml`; scoped exclusions for receiving DB plus journal/WAL family only. No camera/network permission expansion or target-SDK upgrade. |
| Tests authored | New `app_flutter/test/identity/`, `test/sync/`, `test/receiving/`; platform integration sources in `app_flutter/integration_test/receiving_storage_test.dart`; additive assertions in existing setup/widget tests only if integration warrants them. |
| Server schema | New `product/supabase/migrations/20261027000000_receiving_identity.sql`: private schema, permanent device attempts, sessions, vault keys, append-only recovery/session audit, unique constraints, no client table/schema access. No stock schema mutation. |
| Server APIs | New `product/supabase/migrations/20261027000001_receiving_foundation_api.sql`: context, begin/end session, safe catalog/policy and lead partition recovery; private authorization helpers; explicit RPC allowlist. |
| Legacy access closure | New `product/supabase/migrations/20261027000002_receiving_access_boundary.sql`: exact contract table/view/function revocations; retain S1 public RPC grants. No default privileges across unrelated schemas or new role credentials. |
| Backend test source | `product/supabase/tests/receiving_identity.sql`, `receiving_reads.sql`, `receiving_recovery.sql`, and narrowly named concurrency/Auth harness files alongside them. Synthetic fixtures only; no credentials embedded. |
| Records | `docs/testing/2026-10-27-receiving-foundation-acceptance.md` (or implementation-day dated successor), dated handoff and current navigation files. |

If proposed timestamps collide by implementation time, stop and select new monotonic filenames in the review record. Shared PostgreSQL auth roles mean table revocations affect all authenticated consumers; this fact must stay visible in the resulting diff. Do not rewrite prior migrations to hide it. New helpers must reauthorize after waits, limit JSON and ensure counter failures commit while unauthorized key release never does.

## S2A-R06: exact dependency and manifest request

Proposed exact direct additions to `app_flutter/pubspec.yaml`, without caret ranges:

```yaml
sqflite: 2.4.5
idb_shim: 2.10.1+1
cryptography: 2.9.0
web: 1.1.1
```

Allow the corresponding `app_flutter/pubspec.lock` and generated local dependency metadata changes. `web1.1.1` is already locked/cached; the other three versions are not in the inspected cache. Package source is the public pub.dev registry; archive SHA-256 values and direct constraints are recorded in [registry evidence](../../../handoffs/2026-10-27/ch08-receiving-foundation-contract/PACKAGE_METADATA.json). Metadata reads have already occurred; package source download/install has not.

R06 means one narrowly scoped `flutter pub get` using existing tooling to resolve/fetch these direct pins and their required transitive packages, plus generated plugin metadata. It is not `pub upgrade`, SDK installation, Gradle build, native emulator setup, global cache repair, optional cryptography_flutter, drift/Wasm/codegen, or sqflite FFI download authority. No new path_provider package is needed: sqflite supplies the Android database path. Use existing locked path1.9.1 only if imported, making it direct with an explicit amendment rather than relying on an undeclared transitive import.

Known new transitive families from direct package metadata: sqflite_android/darwin/platform_interface/common; sembast and synchronized; existing collection/path/meta/web/crypto/ffi/typed_data constraints. Exact solver closure is **not yet known**. R06 approval must explicitly include resolution of those necessary transitive dependencies and retaining existing versions wherever compatible. Save the before manifest/lock; review the complete resulting graph, hashes, licenses and advisories before declaring success. A solver demand to change existing unrelated packages, toolchain or min SDK stops work for a concrete amendment. No wildcard update. Network retrieval of public metadata/package archives is distinct from network/backend tests. Restore only this action's manifest/lock diff if rejected; do not clean a shared cache or revert inherited source changes.

Suggested human approval text (not an instruction to execute here):

> Accept the S2-A contract choices and approve S2A-R01 source work, S2A-R06 exact direct dependencies plus necessary transitive resolution, and S2A-R02 offline checks for Receiving Foundation Implementation and Local Checks. Preserve inherited work. No backend application, browser/device integration, hosted change or delivery is approved.

## S2A-R02: local checks after source/dependencies exist

From `app_flutter`, using installed SDK and the approved resolved packages:

1. `flutter analyze --no-pub`.
2. `flutter test --no-pub test/identity test/sync test/receiving` once these directories contain the new tests.
3. `flutter test --no-pub test/setup test/widget_test.dart` for S1 and preview regressions.
4. Dart format check on only the changed Dart files; documentation/preservation checks and `git diff --check`.

No runtime/tool version or these commands were executed in C08. Unit tests can establish model/crypto/state behavior, not real browser persistence or Android crash safety. SQL source is unexecuted under R02. Browser test runner, native plugin integration and Gradle downloads are not smuggled into these offline commands. If tests require a missing dependency/download, stop at R06 amendment. No new in-memory mock may be labelled durable production storage evidence.

## S2A-R03 and R05: connected sequence, still unapproved

R03 candidate target is Chapter06's disposable `shelflife-ch06-validation` project/network/volume and its five owned services, loopback DB55322/API55321/mail55324. Before any activation obtain exact reviewed migration/grant diff, complete synthetic fixture manifest, backup/restore scope and explicit approval. Preflight after that approval must verify container IDs/images/mounts/port bindings against the original Chapter06 evidence; defaults are not authority. Never start `_binding_backup` services, use54321 as fallback, alter shared product/Onyx/Windows PostgreSQL, prune Docker, or print private files. The last recorded baseline is empty/five migrations, not the browser fixture. Fixtures must be seeded under new authority; existing credential files do not prove they exist.

R03 execution proposal: apply retained seven plus the three reviewed A migrations; inspect effective ACLs/default ACLs/pg_proc/views/exposed schemas; seed only named synthetic orgs/branches/kiosks/staff/lead/viewer/supplier/conflicting identities; run SQL and actual Auth/API tests; run concurrency/expiry/recovery/audit-failure tests; verify baseline restore and stop only owned services. Explicit grant-change permission is required. A final dump archive listing is not restore proof. Source-only rollback is not a substitute for validating the disposable baseline restoration.

R05-WEB proposal: installed Chrome, a dedicated synthetic profile, actual Flutter app at `127.0.0.1:8136` against approved API55321; record browser/build versions and hashes. Any required web build command needs approval in this row, with `--no-pub`, existing build assets only. Test the real IndexedDB adapter, actual auth and network faults; close server/profile afterward. A browser fake can run independently under a separate approval but cannot stand in for these API checks. No camera or public hosting.

R05-ANDROID is not execution-ready: device/emulator identifier, OS, app/build hash, installation scope, SDK/Gradle/cache/download needs, backend transport and recovery method are unspecified. Approve those before build/install/force-stop/storage or backup tests. Do not widen loopback backend bindings to make a phone work. Desktop native persistence is not selected by this two-platform contract; unsupported platforms must fail clearly, not silently use memory.

Keep any subsequently approved connected migration/backend/browser/device sequence in its owning implementation chat through evidence, baseline restoration and service cleanup. Do not create a new chat merely because tests take time. If action approval is missing, finish unaffected local work and request only that concrete action.

## Acceptance matrix — future tests, not results

| ID / layer | Required observable result |
|---|---|
| A01 source/unit + API | Kiosk uniqueness, conflicting inactive/active identities, missing/foreign branch, unsupported roles fail closed; S1 admin route and same-account token refresh behavior remain correct. |
| A02 SQL/API concurrency | Five wrong/malformed/ambiguous attempts produce one durable cooldown; concurrent calls serialize; attempts during cooldown neither check PIN nor extend timer; client restart/sign-out cannot reset; denial commits counter. Boundary at300 seconds uses server clock. |
| A03 API | Cross-subject/device/tenant token replay, expired JWT/session, PIN change, disabled actor/device, lost lead status and revocation after waiting deny. Fresh PIN revokes predecessor; secret digest only persisted; no raw secret logs. |
| A04 API ACL | Direct table/column/view/legacy/helper RPC/joins/Realtime attempts cannot expose finance, PIN hashes, other tenant or sealed records. Six S1 setup endpoints still pass their original scope tests. Effective grants match reviewed delta. |
| A05 unit/API | Exact DTO field allowlists, leading-zero identifiers, tenant references, missing setup, unsupported unit/policy, response limits, pages and stale setup revision. No arbitrary JSON leaks or fabricated active flags. |
| A06 crypto/unit | Round-trip and standard AES-GCM known-answer vectors, wrong key/context/nonce/tag/ciphertext rejection, fresh nonces and distinct partitions; every persistent record and exception scanned for prohibited fields. |
| A07 native browser/Android | Fault immediately before and after native commit, actual reload/process restart, concurrent stale revision, quota/disk-full and blocked upgrade: saved record survives within platform guarantee or failure is accurately reported. Unit fake is insufficient. |
| A08 browser/device | Background/blur/pagehide/person switch/300-second idle/absolute expiry conceal nested routes; late responses cannot unlock. Offline active drafts work; cold offline/restart/lock cannot reopen. Browser second tab blocked. Native OS/app events separately recorded. |
| A09 storage integration | Ciphertext migration interruption, unknown newer schema, corruption/tag failure and full quota retain last good state without reset; cache eviction never drops drafts. App update and backup exclusions verified on approved Android target. |
| A10 API/UI recovery | Ordinary staff denied; current same-branch lead with recent PIN can deliberately open the disclosed full partition; other device/tenant denied; injected audit failure returns no key; original actor/recoverer/reason retained. Admin recovery remains visibly unavailable. |
| A11 unit/integration | Save is not sync/receipt. A cannot invoke stock mutations; timeout model keeps immutable key/payload; future production transport remains disabled. Catalog approval never creates stock. |
| A12 UI | Empty/loading/stale/failure/not-saved states, original actor/branch,390/1440 widths,200% text, required primary controls>=56px, keyboard/focus. Real assistive technology and device checks are separately reported, not inferred. |

Trace: A01–05 cover foundation portions AC01–03/22–23; A06–11 cover AC21–24/26–27; A12 covers AC26–27. AC04–20 and receipt/catalog/round portions remain with S2-B/C/S3/S4. S1 gaps remain recorded separately. No summed or invented pass count.

## Checkpoint and next bounded step

Next owning step: **Receiving Foundation Implementation and Local Checks**. Its initial opening carries the mandatory start gate. After explicit human start approval there, review this contract and obtain the concrete R01/R06/R02 bundle before those actions. A mere transition approval activates none of them. If only document review is approved, review and request the bundle; do not implement. No second documentation-only design loop is required when the human approves that exact bundle.

R04 hosted target/key custody, R07 staging/commit/push/merge, R08 publication/access and R09 rollout remain unapproved. No target device, production key-management system, admin recovery extension or new legal/store policy is implied. S1-GAPS execution retains its separate action approvals.
