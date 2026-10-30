# Chapter 03 — engineering handoff

2026-10-10 (Australia/Perth). Documentation checkpoint; no fresh application or deployed-system verification.

## Identity and authority

Owner exact title: **ShelfLife — Staff Workflow Design Decisions Review**. ID `01a125ee-a20b-7663-a7f7-f5fe694580d4`; [original chat](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4).

Source exact title: **ShelfLife — Staff Workflow Design Specification**. ID `01a12123-430e-7ab1-9ab1-06e648f8535f`; [source chat](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f); [incoming handoff](../ch02-transition-closeout/ENGINEERING_HANDOFF.md).

Workspace: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`. Source-reported project: Grocer Scanner, `384f962e-dd00-4cea-a58e-9addec9ec4c2`; project metadata was not re-queried here.

The start gate was obeyed. The human then said “Approved to begin **Staff Workflow Design Decisions Review**”. Approved scope: documentation review of D02/D03/D05/D07, available D04/D06 inputs and a dated addendum, preserving D01. The human subsequently requested admin-editable presets and initial onboarding; this authorized design detail, not implementation. After presentation, the human selected “Accept the design with admin onboarding” for version 1 plus the addendum. Exact questions and replies remain in the owning chat.

## Changes and rationale

[Version 1](../../../docs/superpowers/specs/2026-10-10-staff-workflow-design.md) is preserved unchanged. The [dated addendum](../../../docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md) records decisions, cross-decision effects, deferred inputs, admin controls and future acceptance scenarios AC29–AC34. AC01–AC28 remain in version 1; none were executed here.

Admin setup addresses the user's preference to supply store-specific values during onboarding. Six steps cover branch/jurisdiction/time zone, units/packs, locations/receiving, labels/expiry, actions and review/activation. Starter options are explicit choices, not inferred store facts or approved handling advice. Save/resume and later settings are included. Ready workflows can be activated while missing prerequisites block affected workflows. Versioned settings preserve historical receipts/actions and require review of pending drafts affected by changed rules.

Current plan, ledger summary, session index and stable pointer now reflect acceptance and the stop gate. Ledger history and earlier dated packets remain intact. Suggested next scope is documentation-only implementation scope/acceptance planning because D08 is unresolved and onboarding/configuration adds implementation dependencies. This suggestion grants no authority.

## Decisions and remaining questions

| ID | Current status |
|---|---|
| D01 | Retained: staff receive/check/pull aside; lead confirms removal/corrections/transformation. |
| D02 | Accepted: offline drafts during verified active session; online verification after lock/restart/person switch and before finalization; no cold offline login. |
| D03a | Accepted: admin catalog review; catalog approval and valid receiving confirmation remain separate. |
| D03b | Accepted: lead markdown/relabel confirmation; admin confirmation for permitted actions in explicitly selected organization branch; no policy bypass. |
| D04 | Admin setup/preset design accepted. Actual units/precision/packs/labels/locations/supplier/lot rules deferred to onboarding and still unknown. |
| D05 | Accepted: distinct active same-branch pair, all items accounted for and uploads confirmed; open exceptions require reason/owner/next action; no solo completion. |
| D06 | Admin policy setup accepted. Actual jurisdiction/category/handling/transformation rules deferred to onboarding; missing policy keeps affected actions unavailable. |
| D07 | Accepted: five-minute inactivity lock, background/switch lock; five failures trigger five-minute device cooldown. Offline lock prevents resumption until connected. |
| D08 | Implementation slice, backend/configuration persistence, dependencies and application/connected/device validation NOT APPROVED. |
| D09 | Delivery/release/sharing/access/rollout/rollback targets NOT APPROVED. |

Overall design is accepted; no proposal was explicitly rejected. D04/D06 values are deferred, not invented. Admin customization does not make accepted identity, permission, pairing or timing rules discretionary. Past-date markdown/donation flags remain false. No safe shelf-life values or legal eligibility was established. Pack sizes are descriptive in the initial design; automatic unit conversions and arbitrary label/rule scripting are not added.

## Current implementation position

No application files changed. Flutter/Supabase and Android/web first remain the direction; iOS deferred. Chapter 02 G01–G10 are historical local source findings (authenticated stub, supplier routing, action effects, round validation, offline/idempotency and related gaps). They were not re-audited. Accepted design does not imply implementation.

Demo tests/build/screenshots/publication remain historical sample-data evidence. Current live health/access, applied migrations, PIN behavior, real offline persistence, device readiness and catalog connectivity remain unverified. Admin onboarding and configuration storage are not built.

## Files, branch, commits and uncommitted work

Fresh root branch `main`; HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch/commit/stage action occurred. Nested `site-preview/` was not freshly inspected; source handoff's HEAD `e806215c81926baaaec787030a935d408937bbed` and clean state remain historical.

Inherited tracked changes: `PLAN.md`, `PLAN_ADDENDUM_2026-09-25.md`, `RESUME.md`, `app_flutter/android/app/src/main/AndroidManifest.xml`, `app_flutter/pubspec.yaml`, `app_flutter/test/widget_test.dart`. Inherited untracked paths include workflow documents, docs/handoffs, preview source/assets and `site-preview/`. Root inventories: [before](GIT_STATUS_BEFORE.txt), [after](GIT_STATUS_AFTER.txt). Preserve all; do not reset/clean/stage inherited content incidentally.

Chapter-owned files: new `docs/superpowers/specs/2026-10-10-staff-workflow-decisions-addendum.md`; updates to `IMPLEMENTATION_PLAN.md`, `STATUS_LEDGER.md`, `SESSION_INDEX.md`, `NEXT_CONVERSATION_HANDOFF.md`; this `handoffs/2026-10-10/ch03-decisions-review/` packet. It includes summary/handoff/evidence, prior-current-document copies, preservation baseline and Git inventories. All remain uncommitted.

Baseline covers 33 files: prior handoff files and version 1. Current-document copies were saved before edits; prior ledger rows are separately checked. This is documentation preservation, not a whole-workspace/application audit.

## Verification, limitations and rollback

[EVIDENCE.md](EVIDENCE.md) records local documentation verification: preserved historical-file hashes, prior ledger rows, local reference existence and current acceptance/approval status. No application tests, backend calls or legal research were performed. No deployment or compliance claim is made.

Normal shell startup failed twice with `helper_unknown_error: setup refresh had errors`; narrowly scoped elevated local commands succeeded through approval review. No configuration/environment repair was attempted. This was an execution-environment limitation, not an application failure.

No application/hosted rollback is needed. For later documentation correction, compare `prior-current-docs/` with current files; preserve completed dated records and add a numbered correction/addendum rather than erasing accepted-decision history. Do not blindly restore stale waiting states. No source commit was created to revert. Preserve inherited work and all original chats.

## Scope and exact next steps

Approved and finished: named documentation review, accepted design and admin setup, dated addendum, checkpoint records and local document verification. Still unapproved: implementation, toolchain/dependencies, database changes, application/connected/device/Cowork validation, deployment/publication/push/merge/access/rollout, archive and another chat.

1. Stop at Chapter 03's checkpoint and wait for explicit human transition approval.
2. Proposed next step: **Staff Workflow Implementation Scope and Acceptance Plan**, documentation only. Confirm the target through the transition instruction; define first slice and D08 targets/validation without executing them.
3. Only after explicit transition approval, complete any requested closeout and create exactly ONE fresh continuation with this exact source title/ID/link, handoff/addendum/plan, accepted and unapproved scopes, unknown store values and the verbatim AGENTS.md start gate. No fork or duplicate after an uncertain creation outcome.
4. New chat acknowledges waiting and stops without files/tools until explicit human start approval there. Transition is not start approval; “continue” alone is insufficient under the gate.
5. Later implementation and connected testing/delivery still require exact action/target/scope approval. Keep any approved connected sequence in its owning chat through a verified checkpoint.

No continuation was created, other chat messaged or chat archived in Chapter 03.
