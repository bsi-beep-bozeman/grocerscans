# Chapter 02 — engineering review handoff

2026-10-10, Australia/Perth. **Documentation review checkpoint, not final design acceptance or application verification.**

## Identity and provenance

- Owner: **ShelfLife — Staff Workflow Design Specification**, `01a12123-430e-7ab1-9ab1-06e648f8535f`; [exact inputs/outputs](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f).
- Incoming chat: **Review Grocerscans handoff**, `01a0ec6a-a956-71d2-88f5-ed33d81f2930`; [original chat](codex://threads/01a0ec6a-a956-71d2-88f5-ed33d81f2930).
- Workspace: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`.
- Saved project from incoming record: Grocer Scanner, `384f962e-dd00-4cea-a58e-9addec9ec4c2`; project metadata was not freshly enumerated here.
- [Incoming engineering packet](../../2026-10-09/ch01-transition-closeout/ENGINEERING_HANDOFF.md) and both chats remain preserved.

## Approval sequence

This continuation initially acknowledged its mandatory start gate and performed no work. The human's later “Approved—continue the chapter cycle” requested closeout/transition, but did not clearly start the named step; the assistant asked for named approval. The human then said “Approved to begin **Staff Workflow Design Specification**”. That satisfied this chat's start gate.

During work, the human selected “Shift lead confirms stock-removal and transformation actions (Recommended)”. Ordinary staff receive/check/pull aside; a lead confirms discard/donation/stock corrections/freeze/conversion. This is a design decision, not a deployed permission change.

Approved: relevant local source/requirements reads, the documentation-only specification, source-gap and acceptance-criteria documentation, and associated plan/status/index/pointer and dated records. The transition request is recorded and unconsumed. Keep review here; start approval is not acceptance of every new proposal.

Unapproved: application implementation, schema/migration changes, dependencies/toolchains, application/connected/device/Cowork tests, deployment/publication/push/merge/access changes/rollout, and archiving. No continuation was created at this review checkpoint. A later new chat must contain the standing start gate and wait for explicit approval inside it.

## Deliverable and rationale

The [specification](../../../docs/superpowers/specs/2026-10-10-staff-workflow-design.md) includes S01–S13 screens, role/branch permissions, actor lifecycle, known/unknown identifier receiving, explicit date/quantity/lot semantics, product/batch details, lead-confirmed actions, paired rounds, offline states, G01–G10 source gaps, AC01–AC28 future acceptance checks and D01–D09 decisions/approvals.

Recommended receiving uses one review screen with progressive disclosure; alternatives were a wizard and bulk grid. Preserve fast common receipt without hiding required fields. Separate batch identity from product identity. Alert closure must not masquerade as a stock movement; local saves must not masquerade as shared inventory. Round completion must retain unresolved exceptions. Append-only capture does not remove conflicts between quantity/policy/action updates.

The brainstorming skill was read for design alternatives and review structure. No implementation, commit, visual server or application setup followed. Policy decisions used text; a static flow diagram is embedded in the specification. The skill's written-spec review gate remains pending; no implementation-planning chapter has begun.

## Current implementation position

Fresh source reads: schema/RLS/RPCs, supplier migration, authenticated Flutter entry/profile/login, retained plans and client reference. The authenticated entry remains a signed-in stub; profile resolution omits supplier profiles. Existing PIN functions and supplier policy source are not proof of deployment.

Material dependencies: alert resolution currently updates alert/audit only; round item insertion does not explicitly validate target round scope in its inspected body; completion sets a timestamp without proposed pair/completeness rules; batch writes omit client idempotency/receipt-date/supplier-ref inputs; inspected schema lacks the proposed unit/movement/approval/version semantics; raw PIN-bearing writes do not solve durable offline identity. Staff/supplier financial field separation needs future enforcement.

These are source findings, not a complete security audit or authorized fixes. Historical manager enum/policies remain; do not equate a shift-lead flag with manager privileges. Supplier source existence does not establish live access behavior.

## Branches, files and uncommitted work

Fresh root `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. Recent commits: supplier tier `f56d506`, role helper rename `84143c6`, locked decisions `52aedef`. No commits by this chapter.

Fresh nested `site-preview/` HEAD `e806215c81926baaaec787030a935d408937bbed`, clean at inspection. Separate Git checkout: do not accidentally stage it as a submodule or publish the parent repository.

Inherited tracked edits, preserved: `PLAN.md`, `PLAN_ADDENDUM_2026-09-25.md`, `RESUME.md`, `app_flutter/android/app/src/main/AndroidManifest.xml`, `app_flutter/pubspec.yaml`, `app_flutter/test/widget_test.dart`.

Inherited untracked paths: root workflow documents/`AGENTS.md`; `app_flutter/PREVIEW.md`, `assets/`, `lib/preview.dart`, `lib/preview/`, `serve-preview.mjs`; `handoffs/`; `site-preview/`. None were committed, cleaned or removed. Exact inventory: [before](GIT_STATUS_BEFORE.txt) and [after](GIT_STATUS_AFTER.txt).

Chapter-owned work:

- New `docs/superpowers/specs/2026-10-10-staff-workflow-design.md`.
- Updated `IMPLEMENTATION_PLAN.md`, `STATUS_LEDGER.md`, `SESSION_INDEX.md`, `NEXT_CONVERSATION_HANDOFF.md`.
- New `handoffs/2026-10-10/ch02-design-review-checkpoint/` with this summary/handoff, verification evidence, preservation baseline and Git inventories.
- `prior-current-docs/` contains the four pre-edit mutable documents for comparison/recovery. They are historical backups, not current state; no transcript was copied.

`AGENTS.md` was not changed. Its historical authorization narrative is supplemented by newer human messages and ledger entries. Earlier dated packets and ledger event rows are preserved.

## Evidence, tests and limitations

See [EVIDENCE.md](EVIDENCE.md) and [PRESERVATION_BASELINE.json](PRESERVATION_BASELINE.json). Fresh checks cover local links, required content, prior event rows, protected-file hashes, repository status and unchanged HEADs. The 103-file baseline covers tracked files, known untracked preview/assets and earlier dated handoffs; it does not claim all ignored build artifacts were hashed.

The sandbox process and Node kernel failed with `helper_unknown_error: setup refresh had errors`. Scoped approved shell calls outside that runtime succeeded. This was an environment failure, not an application failure or automatic approval rejection. A documentation patch initially failed validation before mutation because it targeted the pointer twice; it was corrected and reapplied.

Historical only: three passing preview tests, targeted analysis, release web build, screenshot inspection and September demo publication in Chapter 01. None was rerun. No live health/access check, backend inspection, SDK/device validation, phone camera test or Cowork application validation occurred. AC01–AC28 are future criteria, never passing-test claims.

Unknown: applied migrations, current hosted health/access, real catalog, SDK/device readiness, real offline persistence, actual units/labels, category policies and client feedback. Old legal text was not validated or reused as current legal advice. No food-safety/compliance certification is implied.

## Decisions and remaining review

D01 is human-decided. Retain Flutter/Supabase, Android/web first, iOS deferred, four roles, branch-bound kiosk, independent batches, printed/computed expiry, near-white/urgency UI and conservative past-date flags.

Pending proposals: D02 offline drafts with online reauthentication after lock/restart; D03 admin review of unknown products and lead confirmation for markdown/relabel; D05 paired-round completion with owned exceptions; D07 PIN/session timing. Pending store inputs: D04 units/pack/scale labels/lot/location and D06 handling policies/state. D08 implementation/tests and D09 external delivery remain unapproved.

Offline limitation is explicit: active verified sessions can capture durable drafts during network loss; cold offline login/reopen is not supported in the initial proposal. If work must continue offline across locks/restarts, design a bounded authorization mechanism first. Never persist raw PINs to make replay work.

## Rollback

No application or hosted rollback is needed because neither changed. If documentation rollback is requested, first compare subsequent edits, restore only appropriate sections of the four current documents from `prior-current-docs/`, retain this dated packet/spec as history, and append a correction. Do not reset/clean the repository or remove inherited application/nested-checkout files.

No new commit exists to revert. After this checkpoint, specification corrections should be a new version/dated addendum linked to this record. Hosted rollback/unpublication/access changes still require action-specific approval; a previously successful rollback target is not established here.

## Exact next steps

1. Human reviews version 1 in this chat, especially D02/D03/D05/D07. Do not ask again for D01 or the named start approval.
2. Record amendments in a new dated version/addendum and update current navigation/status. Obtain store inputs where available; retain unknowns explicitly.
3. Obtain design acceptance and select an exact next bounded step. Acceptance is not implementation, backend modification or testing approval.
4. At the finished design checkpoint, handle the recorded transition request once: create at most one fresh continuation with exact source title/ID, final handoff/spec/plan paths, scope, pending decisions and verbatim mandatory start gate. No fork or transcript copy. No autonomous work in that chat.
5. Record actual returned title/ID and waiting acknowledgement, preserve this chat and consume that one creation authority. Inspect uncertain outcomes; never create a duplicate.
6. Obtain separate named scope/target approvals for implementation and applicable backend/device/connected tests and delivery actions. Keep any approved connected sequence in its owning chat through verification.

This is a concrete review checkpoint, not an instruction to create another chat or delegate work now.
