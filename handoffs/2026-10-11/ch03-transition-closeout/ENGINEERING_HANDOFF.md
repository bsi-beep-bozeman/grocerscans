# Chapter 03 — engineering transition handoff

2026-10-11 (Australia/Perth). Documentation-only transition after accepted design and verified review closeout.

## Identity, authority and audit

Source exact title: **ShelfLife — Staff Workflow Design Decisions Review**; ID `01a125ee-a20b-7663-a7f7-f5fe694580d4`; [original chat](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4). Earlier design source: **ShelfLife — Staff Workflow Design Specification**, `01a12123-430e-7ab1-9ab1-06e648f8535f`; [chat](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f).

Workspace: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`. Freshly verified project: Grocer Scanner, `384f962e-dd00-4cea-a58e-9addec9ec4c2`, local host. Source title/ID were confirmed through the chat listing.

Original human start: “Approved to begin **Staff Workflow Design Decisions Review**”. Accepted design: “Accept the design with admin onboarding”. Latest “continue the chapter cycle.” explicitly approves remaining documentation closeout and ONE fresh continuation. The standing mandatory gate still requires separate explicit start approval in that new chat. Approval does not authorize implementation, connected validation or delivery. Actual creation consumes this one authority; use the [receipt](CONTINUATION_RECEIPT.md), never assume an uncertain creation failed and create a duplicate.

## Deliverable, decisions and rationale

[Version 1](../../../docs/superpowers/specs/2026-10-10-staff-workflow-design.md) and the [accepted addendum](../../../docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md) are unchanged. They cover staff screens/workflows plus admin initial setup and editable presets. Six-step setup supports save/resume, explicit unit/pack/location/lot/label/date/action configuration, partial activation, auditable policy versions and revalidation of pending drafts. It does not silently rewrite stock history or guess missing store rules.

| ID | Accepted position or pending boundary |
|---|---|
| D01 | Staff receive/check/pull aside; lead confirms removal, stock corrections, freeze and conversion. Retain without repeat approval. |
| D02 | Verified active-session offline drafts; online verification after lock/restart/person switch and before finalization. No cold offline login. |
| D03 | Admin catalog review separate from valid receipt confirmation; lead markdown/relabel confirmation; admin confirms permitted actions for an explicitly selected branch in the organization. No policy bypass. |
| D04 | Admin presets/onboarding accepted. Actual units/precision/packs, labels, locations, supplier/lot requirements remain unknown until setup. Automatic pack conversions not added. |
| D05 | Two distinct active same-branch participants; all items accounted for and uploads confirmed; open exceptions need reason/owner/next action; no solo completion. |
| D06 | Admin policy configuration accepted. Real jurisdiction and handling/transformation/eligibility rules remain unknown. Missing rules block affected actions. Past-date markdown/donation flags remain false. |
| D07 | Five-minute inactivity lock, background/person-switch lock; five failures trigger five-minute device cooldown. Offline lock prevents resumption until connected. |
| D08 | Exact first implementation slice, backend/configuration persistence, dependency/toolchain and application/connected/device test scope NOT APPROVED. |
| D09 | External delivery/release/sharing/access/rollout and rollback targets NOT APPROVED. |

Overall design is accepted; no proposals were explicitly rejected. D04/D06 values are deferred to onboarding. Presets do not make accepted identity/permission/pairing/timing rules discretionary. No shelf-life numbers, legal eligibility or real store facts were invented.

Selected next step, after separate in-chat start approval: **Staff Workflow Implementation Scope and Acceptance Plan**, documentation only. It will propose a first implementation slice with admin/configuration prerequisites, exact targets, dependencies, future validation evidence and action-specific approval boundaries. It does not execute implementation or tests.

## Implementation and evidence position

Flutter/Supabase and Android/web first remain the direction; iOS deferred. Chapter 02 G01–G10 source findings and earlier demo tests/build/screenshots/publication are historical. No app, admin onboarding, configuration persistence or backend gap was implemented here. AC01–AC34 remain future acceptance criteria, not passed tests.

Current live health/access, applied database state, catalog connectivity, device readiness, true offline behavior and store inputs remain unknown. No application/deployment/testing sequence is open or interrupted by transition.

The [verified review closeout](../ch03-review-closeout/EVIDENCE.md) recorded 49 protected files, 26 prior ledger rows and 56 local links. Its [correction](../ch03-review-closeout/ADDENDUM_01.md) explains the earlier credit-related approval-review failure and premature completion wording. Preserve both the correction and earlier records. Fresh transition results go in [EVIDENCE.md](EVIDENCE.md); they do not rerun application tests.

## Files, branches, commits and preservation

Fresh root branch `main`; HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch/stage/commit operation. Nested `site-preview/` not freshly inspected; historical source HEAD `e806215c81926baaaec787030a935d408937bbed` and clean state are not current verification.

Inherited tracked modifications: PLAN.md, PLAN_ADDENDUM_2026-09-25.md, RESUME.md, app_flutter/android/app/src/main/AndroidManifest.xml, app_flutter/pubspec.yaml, app_flutter/test/widget_test.dart. Existing untracked source/assets, workflow files, docs/handoffs and nested hosting checkout remain. Exact root inventories are in GIT_STATUS_BEFORE.txt and GIT_STATUS_AFTER.txt. Do not reset/clean or stage inherited content incidentally.

Transition-owned changes: current IMPLEMENTATION_PLAN.md, STATUS_LEDGER.md, SESSION_INDEX.md, NEXT_CONVERSATION_HANDOFF.md; this new `handoffs/2026-10-11/ch03-transition-closeout/` packet. Pre-edit copies are in prior-current-docs/. Baseline protects 61 prior files, including accepted specifications, prior dated packets and inherited tracked modifications. All work remains local/uncommitted.

## Verification limits and rollback

Checks cover protected hashes, ledger event preservation/order, current local references, documentation formatting and exact new-chat start-gate content. Chat creation/waiting is separately recorded. No unit/integration/device/Cowork tests, builds, migrations, legal research or live application checks.

Git reports the user global-ignore file inaccessible; listings may not reflect those preferences. No environment/configuration/permission repair attempted. Normal sandboxed commands work.

No app/hosted rollback needed. For requested documentation correction, compare prior-current-docs/ and add dated corrections; preserve completed records and actual approvals. Never restore a false waiting state or imply a successfully created chat was undone by restoring files. No commit was created to revert. No archive without human direction.

## Exact next steps and approval gates

1. Complete source documentation verification and current record updates.
2. Create exactly ONE fresh local project chat using [NEXT_CHAT_OPENING.md](NEXT_CHAT_OPENING.md); no fork/transcript copy/model override.
3. Record returned identity, wait for acknowledgement, verify waiting state; do not send a start prompt or approve on the human's behalf.
4. Update index/pointer/ledger with actual receipt; preserve this source chat unarchived.
5. The human explicitly approves **Staff Workflow Implementation Scope and Acceptance Plan** in that new chat. Before that, no tools/files/searches/planning/background work.
6. After start approval, produce only the bounded documentation plan/action approval register. D08 implementation and tests and D09 delivery still need explicit scoped approvals.
7. At that chapter's checkpoint, update records and save a dated handoff, then stop for a new transition approval. No unattended chain.

Authorized now: source closeout and one waiting continuation. Unapproved: work in the new chat before its start approval; implementation/dependencies/toolchain/database changes; application/connected/device/Cowork tests; deployment/publication/push/merge/access/rollout; archive or a further continuation. Any later connected approved sequence remains in its owning chat through a verified checkpoint.

## Completed continuation checkpoint

Steps 1–4 are complete subject to the final evidence record: exactly one fresh **ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan** chat was created, ID `01a12796-7acf-70b2-94f9-8d0efc7a2e87` ([open](codex://threads/01a12796-7acf-70b2-94f9-8d0efc7a2e87)). Its waiting acknowledgement and idle state were verified; no work follow-up was sent. Full title confirmed. Creation authority consumed. Next action is explicit human start approval in that chat; source remains unarchived. See the receipt and evidence for actual results.
