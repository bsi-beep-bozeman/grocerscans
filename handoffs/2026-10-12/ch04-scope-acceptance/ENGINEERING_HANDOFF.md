# Chapter 04 engineering handoff

2026-10-12 (Australia/Perth).

## Identity and authority

Owner/source: **[ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan](codex://threads/01a12796-7acf-70b2-94f9-8d0efc7a2e87)**, ID `01a12796-7acf-70b2-94f9-8d0efc7a2e87`. Preserve original inputs/outputs there. Incoming accepted decisions: **[ShelfLife — Staff Workflow Design Decisions Review](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)**. Project: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`; app project Grocer Scanner, `384f962e-dd00-4cea-a58e-9addec9ec4c2`, local host, verified through project listing.

Human instruction: “Approved to start **ShelfLife — Staff Workflow Implementation Scope and Acceptance Plan**” and “**then continue the chapter cycle.**” The same message authorizes verified documentation closeout and ONE fresh continuation, keeps connected approved sequences in their owning chat, preserves action-specific external gates and asks to retain the source chat. Standing AGENTS.md requires explicit human approval in the new chat before any work; this gate is retained. No application sequence was started or split.

## Deliverable and rationale

[Scope/acceptance plan](../../../docs/superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md) proposes S1 Admin Setup Foundation: admin entry, six-step saved setup, preset/location lifecycle, immutable activated versions, per-capability readiness, scoped authorized operations and audit. This is a prerequisite that can be assessed without pretending the entire receiving/offline/action/round system exists.

The plan separates source authoring, offline tests, isolated backend creation/migration/integration, hosted tests, device tests, installation and delivery approvals. It defines S1-01–12 with observable outcomes and evidence layers; all accepted AC01–AC34 map to S1–S4 with partial coverage identified. No criterion is reported as passed. File/task paths and proposed API/persistence contracts guide later implementation; this scope proposal is not a fully coded implementation recipe.

S1 stays online for admin save/resume, with no new durable local store. Server confirmation is required before “saved”; session lock conceals input and requires online revalidation. Server drafts persist after confirmed save. Accepted staff offline behavior remains a later requirement, not weakened by the admin slice.

New proposals requiring acceptance: S1 boundaries; typed/versioned configuration and endpoint contracts; measured precision 0–3 to fit existing numeric storage; 120-character names, 2,000-character notes/reasons and 256-KiB payload limit. These are not real store policies or already implemented behavior.

## Decisions, constraints and unknowns

Retain Flutter/Supabase, Android/web first, iOS deferred. D01/D02/D03/D05/D07 and overall v1 plus admin addendum are accepted; do not ask again. D04/D06 real values are entered in onboarding: jurisdiction, units/packs, labels, actual locations, supplier/lot and handling rules. No invented shelf lives, yields or legal eligibility. Missing policy blocks affected actions; past-date markdown/donation flags remain false.

S1 does not implement staff PIN sessions, catalog requests/approval, receiving, stock containment/actions, rounds, offline queue, camera/OCR, reports or supplier dashboards. Existing identities/org/branches are prerequisites; synthetic fixture provisioning requires its own local-backend approval. Future receiving and stock actions must not call historical RPCs as if they satisfied accepted identity/idempotency/permission rules.

Fresh observations: `main.dart` uses `_SignedInStub`; `supa.dart` kiosk-first/profile selection is not unique active admin resolution; current widget tests import preview code; manifest declarations and lockfile existence observed but installed tools not probed. Schema already has branch timezone, supplier/lot and three-decimal quantity fields; configuration/unit/version model needs new source. SQL PIN/alert/round source read, not executed. This is not a full legacy security audit.

Unknown: applied hosted schema, actual linked backend, live access/health, real catalog/admin identity, installed tooling readiness, physical devices and real store inputs. Nested hosting checkout was not inspected. Historical Chapter 02 gaps/September demo evidence stay historical outside these named fresh observations. No external SDK/API research was performed; implementation must verify relevant APIs before coding, within its approved scope.

## Files, branch and uncommitted state

Root `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch, staging, commit, push or merge. Inherited tracked edits: PLAN.md, PLAN_ADDENDUM_2026-09-25.md, RESUME.md, AndroidManifest.xml, pubspec.yaml and preview widget_test.dart. Existing untracked preview/assets/docs/handoffs and nested site checkout remain. Exact inventories: [before](GIT_STATUS_BEFORE.txt), [after](GIT_STATUS_AFTER.txt).

Chapter-owned files: new scope plan, this packet, current IMPLEMENTATION_PLAN.md, STATUS_LEDGER.md, SESSION_INDEX.md, NEXT_CONVERSATION_HANDOFF.md. Copies of those four before editing are in `prior-current-docs/`. The [120-file baseline](PROTECTED_BASELINE.json) protects selected inherited source/docs and earlier completed packets. It excludes credentials/config values and is not a whole-workspace backup. Accepted specification/addendum and earlier dated records are unchanged.

## Verification, evidence and limitations

[EVIDENCE.md](EVIDENCE.md) records actual documentation checks: protected hashes, preserved ordered ledger events, valid local links, required gate and scope/coverage review. Source reading and document validation are the only verification lanes here. Application unit/widget/integration/device/Cowork tests, builds, migrations and connected backend checks: NOT RUN. No package or toolchain installation. Existing Git global-ignore permission warning was observed; no settings repair attempted. An initial SQL glob search failed due to Windows wildcard handling; directory-based search succeeded and source was read. Neither is an application defect/test result.

Writing-plans skill was used for structure and coverage. Its execution/commit suggestions were bounded by this explicitly documentation-only scope; no subagents or implementation execution were dispatched.

## Rollback and recovery

No app/database/hosted change requires rollback. For a requested documentation correction, compare `prior-current-docs/`, amend current summaries and add a dated correction without erasing historical packets or ledger rows. Actual approvals and creation receipts must remain true. Do not reset/clean inherited edits. No commit was created to revert.

The future plan describes rollback boundaries: local diff only; disposable backend destruction only with named R03 authorization; hosted candidate withdrawal, audited configuration reversal and preserved version/audit data; backups/reconciliation and exact target under R09 before release. These are proposals, not approved recovery actions. Keep this chat unarchived.

## Exact next steps and remaining approvals

1. Finish Chapter 04 documentation verification and current record updates.
2. Use [NEXT_CHAT_OPENING.md](NEXT_CHAT_OPENING.md) to create exactly one fresh **ShelfLife — Admin Setup Foundation** chat; no fork or transcript copy. Record the returned ID in the receipt and current index/pointer/ledger; wait for its acknowledgement. Do not send a start message on behalf of the human.
3. Human approves the named step in that chat. Proposed local implementation lane is S1/R01 and, only if expressly included, R02 existing-dependency local checks. R03–R09 remain separate. A documentation-only reply authorizes only documentation review.
4. Before code, accept/revise S1 persistence/boundaries/precision/limits and refine into exact executable code/test steps. Do not reopen settled product decisions or request real setup values unnecessarily.
5. With R01 implement only listed local source. With R02 run selected offline tests. Source completion alone is not full S1 acceptance.
6. Obtain exact-target R03/R04 and R05 approvals before database/device work; obtain R06 for any needed installation. Keep any approved connected sequence in that owning chat through its checkpoint.
7. Record actual S1-01–12 evidence, unresolved issues and remaining gates. Close out that chapter and STOP for new transition approval; no automatic next creation. D09 release/sharing/access/rollout remains unapproved.

Creation outcome is authoritative in [CONTINUATION_RECEIPT.md](CONTINUATION_RECEIPT.md). Unknown creation outcome must be inspected, never followed by a duplicate creation.

## Verified source checkpoint

Source documentation verification passed before creation: 120 protected hashes, 32 prior ledger events, 55 local links, exact gate and document-format checks. Application tests remain NOT RUN. Transition outcome is recorded separately in CONTINUATION_RECEIPT.md; no new start approval is inferred.

## Completed transition

Exactly ONE fresh **[ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d)** chat created, ID `01a12f57-0cf7-7fa0-8e2a-542b48d3985d`; waiting acknowledgement and idle status verified. Steps 1–2 above completed. Human in-chat scope/start approval is next. No work follow-up sent; creation authority consumed. Source remains unarchived. See receipt for initial response and tool outcome.
