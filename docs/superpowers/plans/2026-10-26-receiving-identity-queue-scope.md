# S2 receiving, identity and durable queue — bounded scope and approval packet

2026-10-26 Australia/Perth. Owner: [ShelfLife — Admin Setup Acceptance Review…](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d), named step **Admin Setup Acceptance Review and Receiving Scope**. **Proposal only; no S2 implementation, dependency or runtime authority granted.**

Sources: [accepted design](../specs/2026-10-10-staff-workflow-design.md), [accepted decisions](../specs/2026-10-10-staff-workflow-decisions-addendum.md), [whole-design coverage](2026-10-12-staff-workflow-scope-acceptance.md), [S1 evidence review](../../testing/2026-10-26-admin-setup-acceptance-review.md). Existing design decisions stay fixed; storage mechanics and server-session contracts below are implementation proposals.

## Outcome and boundaries

S2's eventual outcome is an attributed, policy-valid receipt confirmed exactly once, with recoverable staff drafts and unknown-product requests. A stock receipt is never inferred from catalog approval, a local save, or a successful lookup. Before that full outcome, use three bounded implementation slices:

| Slice | Included result | Explicit boundary and exit |
|---|---|---|
| S2-A Identity and durable draft foundation | Unique online kiosk/staff verification; server five-failure/five-minute cooldown; lock/reverify; minimal safe catalog/config reads; partitioned durable receiving drafts; queue and retry/recovery state model | No stock mutation, catalog approval UI, camera or release. Exit requires chosen storage/session contracts and local tests; runtime acceptance requires separately approved backend/browser/device checks. An in-memory fake cannot satisfy durable storage. |
| S2-B Known-product receiving | Manual UPC/SKU/catalog selection; printed-date receipt review; explicit units/required fields; policy/config version revalidation; atomic receipt/batch/audit/idempotency; safe product/batch detail; changed-policy review | Initially printed-date known products only; calculated receiving remains visibly unavailable until its own tests. No stock correction, removal, transformation or rounds. Full S2 is not complete at this exit. |
| S2-C Catalog requests and remaining capture | Unknown-product request/admin approve-or-link; explicit later receipt confirmation; computed expiry using supplied rules; existing scanner/manual fallback after camera approval | Admin catalog decision never produces stock. Covers full receiving AC set only after identity, durability, camera/device and dependency evidence exists. External lookup/OCR/scale-format guessing remain excluded. |

The next recommended chapter is **Receiving Foundation Contract and Storage Decision**, documentation only: finalize S2-A session/read/storage contracts and exact implementation/test approval text. This resolves a concrete prerequisite before adding dependencies or claiming durable drafts. It must wait for explicit human start approval in that chat. It must not create another chapter without a fresh transition approval at its own checkpoint.

S2 does not enable S3/S4 actions. Retain lead/admin confirmation for discard/donation/corrections/freeze/conversion/markdown/relabel; ordinary staff may receive/check/pull aside in their eventual authorized slices. Lead status is not a catalog-admin role. Past-date markdown/donation flags remain false. Paired rounds still require two distinct same-branch staff, all checks/uploads accounted for and owned exceptions. Unknown store policies keep affected paths unavailable.

## Fresh source observations

Read locally in Chapter07; not a runtime/security certification:

- `app_flutter/lib/main.dart` now routes to `SupabaseAdminSetupGate`. The old signed-in-stub observation is historical; do not repeat it as current. `supa.dart` still has kiosk-first resolution and a staff query without an active filter or supplier branch. Do not use that helper as proof of unambiguous authorized staff identity.
- The retained `kiosk_verify_pin` returns matching active branch staff; its body has no five-attempt cooldown/session issuance. `_assert_kiosk_actor` takes a raw PIN on writes. `kiosk_log_batch` lacks operation-key/config-version/receipt-date contract fields. S2 must not route new workflows through those legacy signatures.
- `products` includes financial columns; batches do not implement the full proposed receipt/unit/config lineage. Safe response DTOs alone do not cure legacy broad SELECT permissions. Inventory all direct-table/view/RPC grants before enabling operational access; propose exact restrictions for review, without applying them here.
- `pubspec.yaml` declares Flutter, Supabase Flutter and mobile scanner, with no declared dedicated durable queue adapter. Transitive packages are not a selected durability design. No package/tool version was checked remotely or installed in this review.

## S2-A contract to finalize before code approval

| Boundary | Required contract / invariant | Still to finalize |
|---|---|---|
| Account context | Derive organization/branch/device from authenticated subject; reject inactive, conflicting, unknown and legacy-manager identities; admin selects an allowed branch explicitly | Exact context endpoint and safe response schema; keep existing S1 admin route regression-safe |
| Staff PIN | Online masked 4–6 digits; exactly one active same-branch match; generic wrong/ambiguous error; serialize attempts per device; five failed attempts cause five-minute server cooldown | Durable attempt record/transaction design, clock source and reset semantics; concurrent attempts and restart must not bypass cooldown |
| Actor session | Bind authenticated device + staff + org + branch; server checks expiry/revocation on each mutation; raw PIN never stored, queued, logged or included in audit | Opaque server session vs equivalent proof, absolute lifetime/renewal, multi-tab behavior and revocation. No arbitrary lifetime adopted here |
| Lock/reopen | Five-minute inactivity, background and person switch conceal working data. Restart/lock/person switch require online verification. Offline capture only in an already verified active session | Exact platform lifecycle signals, sealed-data/key handling and memory clearing; UI concealment alone is not storage confidentiality |
| Safe reads | Return only explicit operational catalog/location/config fields; no costs/prices/margin/PIN hashes/tokens, no another-branch drafts | Exact minimal DTO plus direct-access permission inventory and source migration proposal. All applied permission changes separately approved |
| Durable store | Atomic persisted draft + operation identity + queue state before “Saved on this device”; survive crash/reload; isolate org/branch/device/actor; sealed after lock; preserve across sign-out/update | Platform adapter and version, encryption/key strategy, schema upgrades, quota/corruption recovery, browser data-loss limits and testable failure modes |
| Recovery | Original actor preserved; authorized lead/admin recovery adds recovering actor/reason; no impersonation or automatic cross-actor exposure | Exact recovery authorization and UI; until implemented, another actor cannot open/replay a sealed draft |

Storage decision must compare browser and Android behavior using current primary documentation after that review is approved. Compare platform-native transactional storage through maintained adapters with a shared cross-platform database option; record exact packages/versions, already-cached status, license, crash atomicity, key access, browser restart/quota behavior and migration recovery. No library recommendation or compatibility claim is made in this packet. Do not select preferences-only storage or an in-memory queue as evidence of durability. A temporary fake store is for unit tests only.

Draft envelope: schema version, draft ID, stable client operation UUID, org/branch/device, original actor, recovery actor/reason where authorized, capture timestamp, operation kind, payload, known config/base revision, dependencies and last server outcome/reference. No PIN, reusable session proof, auth token or financial fields. Capture time is evidence, not server authority. Editing after a known rejection/conflict creates a reviewed successor operation; an uncertain committed request retains its original immutable payload/key until reconciled.

States: Editing → Local saved → Waiting for sign-in / Waiting for dependency → Ready / Sending → Confirmed; explicit Retryable failure, Conflict, Rejected and Storage failure. “Confirmed” requires a durable server reference. Timeout retains the same operation/key; reconcile before retransmission, bounded retry, no infinite rejected replay. Save failure retains the form and says “Not saved”. A device/browser data clear can destroy local-only records; no unsynced remote-backup promise.

## Receipt and catalog contract boundaries for S2-B/C

- Manual identifiers remain strings, including leading zeroes. Exact UPC/SKU first, explicit choice for ambiguity, no same-name merge. Camera frames never increment quantity. Unsupported labels use manual entry; no guessed weight/date.
- Use an explicitly configured stock unit; positive quantity with configured precision 0–3 and integer each. No silent rounding/conversion. Printed expiry starts blank per delivery; calculated expiry uses receipt date and supplied applicable rule. Receipt date uses branch calendar, future date rejects, earlier date requires reason. Past-date delivery remains draft/hold for review, not ordinary available stock; broader hold accounting belongs to S3.
- Required supplier/reference/lot/location/exception policy comes from effective active setup, not an old default. Missing or deactivated references block confirmation while preserving draft. Revalidate actor and config on replay; show changes and require renewed review. Preserve confirmed date basis/config version prospectively.
- Proposed server families: resolve receiving context, verify/end staff session, read safe catalog/config, submit/review catalog request, reconcile receipt operation, confirm receipt. These are proposed names/responsibilities, not existing endpoints.
- Confirmation transaction derives tenant, authorizes actor, locks/rechecks dependencies and versions, validates unit/date/reference policy, and writes receipt + new batch + operation result + audit atomically. Same operation/payload returns original result; changed payload with same key conflicts. Reauthorization still applies to recorded retries. Legitimate later identical deliveries may use a new reviewed operation; similarity warnings do not prohibit them.
- Proposed new records: staff attempt/session state; catalog request/review history; receipt and receipt operation/audit records. Extend batch linkage/unit/date/config provenance additively. Local unsynced drafts are not stock or a server receipt. Restrict direct writes and include grants/RLS/source changes in the reviewed migration diff. Never rewrite the seven retained migrations.
- Catalog approval/linking resolves a dependency only. Staff explicitly reviews a complete receiving draft and confirms separately. Concurrent duplicate identifiers link after review, never silently create duplicates. Read-only details distinguish lots/dates/locations and pending local vs confirmed estimated stock.

## Exact source ownership proposed for approval

Paths are repository-relative. New paths below are proposals; they do not exist merely because listed. Final filenames and monotonic migration timestamps must be reconciled before authoring.

| Slice | Proposed source/test paths | Limits |
|---|---|---|
| S2-A | New `app_flutter/lib/identity/`, `app_flutter/lib/receiving/receiving_draft.dart`, `app_flutter/lib/sync/`; matching `app_flutter/test/identity/`, `test/sync/`, `test/receiving/`; modify `app_flutter/lib/main.dart` and, if replaced, `supa.dart`; new additive `product/supabase/migrations/*_staff_session.sql`, `*_receiving_reads.sql`; `product/supabase/tests/staff_session.sql` | Preserve setup gate/tests and preview. Pin session/storage contracts first. Pubspec/lock changes only under a named dependency approval. No scanner changes in A. |
| S2-B | `app_flutter/lib/receiving/`, safe detail widgets in `lib/stock/`, `test/receiving/`, `test/stock/`; additive `*_receiving.sql`/`*_receiving_api.sql`; `product/supabase/tests/receiving.sql` | Printed known products first. Receipt/batch history and operation atomicity; no stock actions. |
| S2-C | `app_flutter/lib/catalog/`, receiving scanner adapter, matching tests; additive catalog-request API/migration and tests | No external catalog integration. No supplier operational dashboard, staff/PIN provisioning UI or full round/Today shell. |
| Evidence | `docs/testing/` procedures, approved fixture-specific local harnesses under `product/supabase/tests/`, dated handoffs/current navigation | Never include private dumps, credential storage or browser auth state. |

Current root is dirty `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. Preserve inherited work; no automatic reset, cleanup, branch creation, staging or commit.

## Acceptance and sequencing

| Slice/check group | Required observable result | Trace to accepted criteria |
|---|---|---|
| A identity | Unique active actor; wrong/ambiguous PIN denial; five-failure cooldown holds across concurrent calls/device restart; inactive/revoked/expired proof denied; safe reads and cross-context isolation | AC01–03, AC22–23 |
| A durability | Atomic write interrupted before/after commit; reload/crash retains saved draft or honestly reports not saved; quota/corruption/migration failure preserves recoverable state; lock/restart/person switch seals data and requires online verification | AC21–24, AC26–27 |
| A recovery | Wrong actor cannot open/replay; permitted recovery keeps original actor plus recovery reason; no PIN/auth material or finance in persistent draft/response | AC02–03, AC22–23 |
| B receipt | Leading-zero/manual lookup, separate lots/batches, explicit printed date/unit/policy; no available stock from incomplete draft; branch-local midnight; two devices/config changes and revoked actor handled | AC06–11, AC23, AC25, AC30–32, AC34 |
| B retry | Double tap, lost success response, client crash after server commit, same key changed payload: one receipt/batch/audit result; retry reauthorizes and preserves draft on rejection | AC12, AC21–24, AC32 |
| C catalog/capture | Approval/link alone leaves stock unchanged; missing fields still block; duplicate identifier race reviewed; computed source/policy explicit; camera denial/manual fallback and repeated frames | AC06–10, AC24, AC28, AC34 |
| All UI | Correct branch/actor, visible queue state, distinct empty/loading/failure/stale; 390/1440, 200% text, >=56px required primary controls, keyboard and real assistive technology/device tests | AC26–27 |

No S2 acceptance test ran in this chapter. A passes only its foundation portion, B only known printed receipts; neither can close all of S2. AC04–05/13–20 and stock-action/round portions of AC12/21–27/32 stay with S3/S4. Use source-unit tests first, then named disposable backend, then actual app/browser/device checks. Keep any approved connected sequence in its implementation chat through backup, cleanup and evidence checkpoint. Stop on a missing action/dependency approval; do not restart historical private fixtures implicitly.

## Action-specific approval packet

Every row is **NOT GRANTED** except C07-DOC and C07-TRANSITION. An approval must name its row/action/target; approval of a documentation chapter alone does not activate R01/R02/R03/R05. These chapter-qualified rows do not reuse consumed Chapter05/06 permission.

| ID | Concrete approval request / target | Preconditions and exclusions |
|---|---|---|
| C07-DOC | Review S1 evidence and draft S2 scope, update local records, verify documentation | GRANTED by “Approved Admin Setup Acceptance Review and Receiving Scope”. No runtime/application tests. |
| C07-TRANSITION | Close this checkpoint and create exactly one fresh continuation, no fork | GRANTED by current human instruction; new chat must wait for its own start approval. No archive. |
| C08-DOC | Approve **Receiving Foundation Contract and Storage Decision** in its new chat: finalize S2-A session/security/storage contracts, exact package proposal and R01/R02 amendment | Documentation/source and primary-document review only. No source implementation, installation, runtime/device or permission changes. |
| S2-R01 | After contracts accepted, authorize S2-A source and meaningful unit/SQL test authorship in the A paths above, preserving S1 | No database application, installed dependency changes or live permission change. Present exact migration/source diff at checkpoint. B/C require separate slice approval. |
| S2-R02 | Execute offline local checks from `app_flutter`: `flutter analyze --no-pub`; `flutter test --no-pub test/identity test/sync test/receiving`; existing `test/setup` and `test/widget_test.dart` regressions, using installed tooling | No downloads/network/backend. Final storage adapter tests need the approved adapter first. Do not run nonexistent test paths. No application test executed by this review. |
| S1-GAPS-R03/R05 | If desired, restore only the final synthetic browser fixture to Chapter06 disposable target; add explicit lead denial, audit-insert failure/rollback and review-then-revocation browser checks; back up and restore baseline/stop afterward | Exact target below; existing seven migration source only, synthetic audit-failure trigger removed/rolled back; no product schema or unrelated state. New runtime/permission test action needs explicit approval; this row is not granted. |
| S2-R03 | Candidate isolated project/network/volume `shelflife-ch06-validation`, only five named services from Chapter06; loopback DB55322/API55321/mail55324. Apply retained seven plus reviewed new S2 migrations/grants to synthetic fixtures; SQL/Auth/concurrency/restart/rollback tests; preserve evidence and baseline restore/stop | Read-only preflight must reconfirm ownership/mounts/listener isolation after approval; source diff/fixture manifest required before mutation. Never start `_binding_backup` containers, use default54321, alter shared product/Onyx/Windows PostgreSQL, prune/reset Docker or fetch packages implicitly. |
| S2-R05-WEB | Named installed Chrome version recorded at execution, actual Flutter app served only at `127.0.0.1:8136` against approved API55321; synthetic A/B cases, reload, response loss, lifecycle/storage failure; close browser/server | Requires S2-R03 and exact build/dependency scope. Dedicated test profile only. No personal browser, hosting or camera. Native OS cases must be named explicitly. |
| S2-R05-DEVICE | Android device/OS identifier, app/build hash, test-network backend binding, install/uninstall scope, camera permission and AC cases | NOT execution-ready: device and transport unknown. Loopback backend is not automatically reachable on a phone; do not broaden binding as a workaround. Separate explicit device/network/camera approval. |
| S2-R06 | Exact storage package/tool/version/source, cache/download action and manifest/lock changes after C08 decision | Not execution-ready until selected; no wildcard package upgrade or implied installation. |
| R04 | Hosted backend target, allowed reads/writes, exact migrations/grants, backup and restore scope | No hosted target selected. Not requested as executable approval now. |
| R07/R08/R09 | Selected commit/push/PR/merge; release artifact/target/audience/access; rollout/rollback owner/window/action | Separate approvals after concrete candidate/diff exists. No production/GHL publication, permissions or rollout authorized. |

Residual S1 gaps may remain recorded while preparing S2-A contracts. Enabling operational access must await safe-read/legacy-permission review and actual authorization evidence; S1 success does not certify the old staff RPC surface.

## Rollback and decision register

Documentation rollback is additive correction/current-pointer repair, preserving this dated proposal and prior history. Future source rollback must isolate the approved diff from inherited edits. Future disposable tests retain and hash a baseline, verify its restoration, and stop only owned services. New final browser snapshot from Chapter06 is not restore-tested; if chosen, its first approved restore must be verified before tests. Do not erase production receipt/config/audit history; no hosted rollback is approved or designed by this local packet.

Pending decisions: bounded S1 acceptance; timing of S1 gap checks; S2-A contract/storage selection; server proof/lifetime and recovery rules; exact safe-read and legacy grant changes; then explicit R01/R02 and later exact runtime/dependency/device actions. Actual jurisdiction, locations, units and policies remain onboarding inputs. Generic login connectivity copy is a separate small proposed fix, not silently included in A.
