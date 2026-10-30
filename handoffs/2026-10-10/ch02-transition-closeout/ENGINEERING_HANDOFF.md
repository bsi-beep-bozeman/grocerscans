# Chapter 02 — engineering transition handoff

2026-10-10 (Australia/Perth). Documentation closeout; no fresh application or deployed-system validation is claimed.

## Identity and authorization

Source exact title: **ShelfLife — Staff Workflow Design Specification**.
Source ID: `01a12123-430e-7ab1-9ab1-06e648f8535f`.
[Original inputs, outputs and approvals](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f).
Project: **Grocer Scanner**, `384f962e-dd00-4cea-a58e-9addec9ec4c2`, local host, freshly confirmed through project listing.
Workspace: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`.
Earlier source: **Review Grocerscans handoff**, `01a0ec6a-a956-71d2-88f5-ed33d81f2930` ([chat](codex://threads/01a0ec6a-a956-71d2-88f5-ed33d81f2930)).

Human start approval in this source chat: “Approved to begin **Staff Workflow Design Specification**”. Human policy choice: “Shift lead confirms stock-removal and transformation actions (Recommended)”. Latest transition approval: “continue the chapter cycle.” followed by explicit instructions to verify within scope, close out and create a fresh continuation.

The latest request permits this transition despite unfinished human review. It supersedes the earlier review packet's instruction to keep review here, without silently accepting proposals. This is one creation authority, not multiple authorities accumulated from repeated transition wording. No new chat may start merely because it was created. Record the actual result in CONTINUATION_RECEIPT.md and consume the creation authority once.

Approved now: documentation verification, current plan/status/index/pointer updates, new dated summary/handoff and exactly one fresh gated continuation for **Staff Workflow Design Decisions Review**. Selected scope there, subject to explicit start approval in that chat: documentation-only decisions review and addendum. Unapproved: any work there before that start approval; application implementation, dependencies/toolchains, schema changes, application/connected/device/Cowork tests, deployment/publication/push/merge/access changes/rollout, archiving or a further continuation.

## Changes, rationale and implementation position

Chapter 02 produced [specification version 1](../../../docs/superpowers/specs/2026-10-10-staff-workflow-design.md): S01–S13 screens, permission matrix, receiving, batch details, expiry actions, rounds and offline/sync states; AC01–AC28 future acceptance criteria; G01–G10 local source findings; D01–D09 decision/approval register.

The approved human policy lets staff receive/check/pull aside and requires a lead to confirm discard/donation/stock correction/freeze/conversion. Extra lead confirmation for markdown/relabel is still proposed. The recommended one-screen receiving review keeps mandatory exceptions visible. Batch identity stays distinct from products. Actions require quantity effects and attribution; replay must not duplicate stock. Rounds preserve owned open exceptions. Local drafts never claim shared-inventory confirmation.

Source observations from this chapter, not deployment evidence: authenticated Flutter entry remains a signed-in stub; profile resolution omits supplier profiles; existing alert resolution only updates alert/audit; round completion lacks the proposed completeness/pair validation; inspected write interfaces lack the proposed durable offline/idempotency protocol. The detailed G01–G10 table records future dependencies, not authorized fixes or a comprehensive security audit.

Flutter/Supabase and Android/web remain the direction, iOS deferred. Four intended roles, branch-bound kiosks and shift-lead flag remain; historical manager enum/policies do not grant new UX authority. Preserve printed/computed expiry, independent batches, estimated quantities and conservative past-date markdown/donation flags. Do not use deprecated clients as the current deliverable.

This transition adds a new dated packet and changes only the current navigation/status documents. Version 1 and the completed earlier review packet remain untouched. An addendum records why review will occur in Chapter 03 rather than silently rewriting prior instructions.

## Decisions, constraints and questions

| Decision | Current status and next treatment |
|---|---|
| D01 | Human-decided lead confirmation; retain without asking again |
| D02 | Proposed active-session offline drafts, online verification after lock/restart, no cold offline login; accept or revise explicitly |
| D03 | Proposed admin review of unknown products and lead confirmation for markdown/relabel; accept or revise |
| D04 | Store units/pack sizes/label formats/location/supplier/lot inputs unknown; collect available facts or retain unknowns |
| D05 | Proposed paired rounds and completion with owned exceptions; accept or revise |
| D06 | Operating state and category/handling/transformation/donation policies unknown; conservative restrictions stay in place |
| D07 | Proposed five-minute lock and five-failure/five-minute PIN cooldown; accept or revise |
| D08 | Implementation slice, backend, dependencies and application/device test scope not approved |
| D09 | Release target, sharing, rollout and rollback target not approved |

Offline cold-start limitation is material: current proposal permits capture during a verified active session but requires online verification to reopen after locking/restart. Broader offline identity needs bounded design before implementation; persisting raw PINs is not an acceptable shortcut. None of this is already working merely because a document describes it.

## Files, branches, commits and uncommitted work

Fresh root branch `main`; HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. Recent known commits: supplier tier `f56d506`, role helper rename `84143c6`, decisions `52aedef`. Nested `site-preview/` HEAD `e806215c81926baaaec787030a935d408937bbed`, clean at closeout inspection. No commit or branch change occurred.

Inherited tracked modifications: `PLAN.md`, `PLAN_ADDENDUM_2026-09-25.md`, `RESUME.md`, `app_flutter/android/app/src/main/AndroidManifest.xml`, `app_flutter/pubspec.yaml`, `app_flutter/test/widget_test.dart`. Inherited untracked paths: root workflow documents/AGENTS.md; preview files/assets; docs; handoffs; nested hosting checkout. Exact inventory is in GIT_STATUS_BEFORE.txt and GIT_STATUS_AFTER.txt. Preserve all; never reset/clean or stage the nested checkout incidentally.

Transition-owned edits: `IMPLEMENTATION_PLAN.md`, `STATUS_LEDGER.md`, `SESSION_INDEX.md`, `NEXT_CONVERSATION_HANDOFF.md`; additions under `handoffs/2026-10-10/ch02-transition-closeout/`. Pre-edit copies of the four current documents are in `prior-current-docs/`. The specification and prior dated packets are protected by PRESERVATION_BASELINE.json, along with the earlier source baseline (114 files total).

## Verification, test results and limitations

Fresh: source-chat/project identity, Git state, protected-file hashes, preserved ledger event rows, local reference existence, documentation whitespace and start-gate content. Actual results: [EVIDENCE.md](EVIDENCE.md). Creation/waiting-state result is recorded separately in [CONTINUATION_RECEIPT.md](CONTINUATION_RECEIPT.md).

Historical: earlier Chapter 02 review checks passed for 103 protected files, 13 old ledger rows and 50 local links. Chapter 01 recorded three preview tests, targeted analysis, web release build, screenshot inspection and one demo publication. These application results were not rerun. AC01–AC28 remain proposed tests, not passed tests.

Not performed: application tests/build/analysis, database connections/migrations, live Site health/access checks, phone camera or offline-device validation, connected/Cowork application validation. No deployment/testing/application sequence was authorized for this documentation chapter, so transition interrupts no such sequence. If a later sequence is authorized, keep it in its owning chat through a verified checkpoint.

Unknown: live health/access, applied migrations/RLS, catalog connectivity, current SDK/device readiness, real offline behavior, store policies and client feedback. Historic legal text was not verified or adopted as current advice. Scoped approved shell calls were used because the sandbox runtime previously failed during startup; no application/environment setup was changed to work around it.

## Rollback and preservation

No application or hosted rollback is needed. If documentation rollback is requested, compare later edits, restore only appropriate current-document sections from this packet's prior-current-docs, and preserve completed dated packets/specification as history with an additive correction. The updated index/pointer must continue to reflect a successfully created chat even if other wording is corrected. Do not imply chat creation was undone by restoring old files.

No source commit exists to revert. Do not remove inherited prototype files, ignored build assets or nested Git history. Hosted rollback/unpublication/access changes require separate action/target approval; no older successful rollback version is established. Preserve all original chats; archive only on human direction.

## Exact next steps

1. Complete documentation verification and save evidence in this packet.
2. Create exactly one fresh local project chat using NEXT_CHAT_OPENING.md; do not fork, copy the transcript or override the user's default model.
3. Record the returned identity and wait for its initial response. Verify only acknowledgement/waiting; do not send start approval or a follow-up work request.
4. Update session index, stable pointer and ledger with the actual receipt; preserve this source chat.
5. Human explicitly approves **Staff Workflow Design Decisions Review** in that new chat. Before approval: no file reads, tools, planning, searches or background work.
6. After approval there, review the specification decisions with the human and create a dated decision addendum. Preserve unknowns and distinguish design acceptance from implementation approval. Update plan/status/index/pointer at its checkpoint.
7. Stop at that checkpoint and wait for a new transition approval. Do not create an unattended chain or start implementation based on this handoff.

## Supersession note

The version 1 specification and [earlier review handoff](../ch02-design-review-checkpoint/ENGINEERING_HANDOFF.md) said to finish design review in Chapter 02. The human's later explicit transition request moves only the remaining documentation review to a gated Chapter 03. All substantive undecided design choices remain undecided. This new record preserves, rather than overwrites, that history.

## Completed creation checkpoint

Steps 1–4 above are complete. Created one fresh chat with exact title
**ShelfLife — Staff Workflow Design Decisions Review**, ID
`01a125ee-a20b-7663-a7f7-f5fe694580d4` ([open](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)).
Waiting acknowledgement and idle status are verified; no start approval/work
follow-up was sent. The receipt records the exact initial response and title
confirmation. Creation authority consumed; next action is human start approval
in Chapter 03. This source remains unarchived.
