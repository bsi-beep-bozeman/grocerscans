# Chapter 01 — engineering transition handoff

Date: 2026-10-09, Australia/Perth. This is a documentation closeout; it does not
claim fresh application or deployed-site validation.

## Identity and authorization

Source chat: **Review Grocerscans handoff**.
ID: `01a0ec6a-a956-71d2-88f5-ed33d81f2930`.
[Exact original inputs/outputs](codex://threads/01a0ec6a-a956-71d2-88f5-ed33d81f2930).
Project: **Grocer Scanner**, ID `384f962e-dd00-4cea-a58e-9addec9ec4c2`, local host.
Root: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`.

Fresh authority: user said **“Approved—continue the chapter cycle.”** The request
authorizes remaining in-scope verification, closeout records, index maintenance
and a fresh continuation chat. It expressly retains separate external-action
approvals. The earlier mandatory IN-THIS-CHAT start gate remains in force: this
transition permits one waiting continuation, not autonomous work in that chat.

Evidence vocabulary: Fresh = read/verified in this closeout; Historical = prior
evidence not rerun; Selected scope = transition destination but start-gated;
Unknown = not established. Original chats are the audit record, not this summary.

## Changes and implementation position

Historical: `app_flutter/lib/preview.dart` and `lib/preview/` implement a standalone
sample-data cockpit, inventory search, barcode/manual SKU lookup, review/date/
quantity capture and session-only rounds/activity. It does not initialize the
production Supabase client. `lib/main.dart` remains the authenticated app entry.
Prototype edits include Android camera/network declarations and bundled fonts.

Historical: the preview was published to Sites after explicit approval. It is a
static snapshot, separate from the main repository. Source preparation and a
successful native deployment were recorded in this source chat.

Fresh closeout changes are documentation only: updated standing authorization,
implementation plan, status ledger, session index and stable pointer; this NEW
dated handoff packet preserves the earlier folder without overwriting it. New
app code, feature design execution, tests, commits and remote deployment are not
part of this closeout. The rationale is bounded chapters with fast evidence access.

## Files, branches, commits and uncommitted work

Fresh root branch: `main`; HEAD `f56d5068e94cf80819f55be952a95769ad508c97`.
This includes supplier-tier commit `f56d506`; prior commits include `84143c6`
(role helper rename), `52aedef` (decisions), `dfc2795` and `f0fa27b` (addenda).

Tracked working-tree modifications at closeout inspection:

- `PLAN.md`, `PLAN_ADDENDUM_2026-09-25.md`, `RESUME.md`: additive workflow pointers.
- `app_flutter/android/app/src/main/AndroidManifest.xml`, `app_flutter/pubspec.yaml`,
  `app_flutter/test/widget_test.dart`: existing prototype changes, preserved.

Untracked at closeout inspection:

- `AGENTS.md`, `IMPLEMENTATION_PLAN.md`, `NEXT_CONVERSATION_HANDOFF.md`,
  `SESSION_INDEX.md`, `STATUS_LEDGER.md` and `handoffs/`: workflow records.
- `app_flutter/PREVIEW.md`, `assets/`, `lib/preview.dart`, `lib/preview/`,
  `serve-preview.mjs`: existing prototype files.
- `site-preview/`: separate nested Git checkout; do not accidentally stage it as
  a submodule or push the parent repository to the Site.

Fresh nested Sites branch: `main`; HEAD
`e806215c81926baaaec787030a935d408937bbed`; clean at read-only inspection.
No source commit or push is made by this closeout. Final inventory is in EVIDENCE.txt.

Retained implementation references: `product/supabase/migrations/`, seed.sql,
`reference/AL_SAFA_MARKET_OS.md`, `PLAN.md`, September addendum, ASSESSMENT.md,
MARKET.md and app_flutter/README.md. `product/js/` and `app/` are historical
reference clients. Do not extend them as the current deliverable.

## Evidence, tests and limitations

Fresh: project/chat metadata identifies the owning chat and target local project.
Local Git/source documentation observations above were repeated. Documentation
validation checks local links, the exact start gate, preserved historical plans
and old dated handoffs, unchanged application diff, and Git whitespace. Results
are saved separately in EVIDENCE.txt and the later continuation receipt.

Historical application evidence, NOT rerun:

- Three passing Flutter tests: exact SKU and normalized UPC lookup; mobile 390×844
  and desktop 1440×1100 layouts with invalid-save rejection and successful date/save.
- Targeted analysis of preview source/tests: no issues. Whole-project analysis
  previously reported a deprecated anonKey use; do not claim whole-project clean.
- Release web build with locally bundled renderer and fonts: succeeded.
- Desktop/phone/scanner screenshots in `app_flutter/build/` were visually checked.
  They are ignored build artifacts, not guaranteed durable records in Git.
- Sites native publish result: succeeded on 2026-09-29.

No fresh application tests, deployment health checks, connected testing or Cowork
application validation were required for this documentation-only checkpoint and
none were executed. No approved application/deployment sequence is being cut in
half by the transition. Future connected sequences stay in their owning chat
through verification and require applicable explicit action approvals.

Unknown: current live demo health/access, applied database/RLS state, production
catalog readiness, current Android SDK availability, actual phone-camera results,
client feedback and live offline behavior. No APK has been verified historically.
Sample saves only add in-memory activity; they are not persistent stock records.
SKU recognition means catalog lookup of typed or barcode-encoded values, not OCR.

## Published artifact provenance

Historical URL: https://shelflife-cockpit-preview.ppdpainting-4984.chatgpt.site
Site: `appgprj_6abbd9aa5a808191a1121fdf09932ab5`.
Deployment: `appgdep_6abbdb9e80a881918b0e74ce420a7261`.
Version: `appgprj_6abbd9aa5a808191a1121fdf09932ab5~appgver_5dd564c842088191a0dfba099fbdb8e4`.
Manifest: `site-preview/.openai/hosting.json`; static export: `site-preview/dist/`.
Last historical audience was owner-only. Client sharing was not authorized.

Historical Windows packaging required installed Git Bash, process-only
`TAR_OPTIONS=--force-local` and an exact safe.directory for the sandbox-owned
checkout. Never persist credentials; future publication must use the then-current
Sites skill and fresh scoped credentials under separate approval. This is recovery
context, not an instruction to deploy during a design-spec chapter.

## Decisions and constraints

Flutter + Supabase, Android/web first, iOS deferred. Four intended roles:
admin/staff/viewer/supplier. Shift-lead flag instead of a manager UX; unused manager
enum remains in SQL. Supplier-role migrations exist/are committed, despite stale
unfinished text in RESUME.md; whether applied is unknown. Preserve batch-level
expiry distinctions and conservative markdown/donation defaults until store state
is confirmed. UPC does not encode an expiration date.

Keep white surfaces, prominent expiry numbers, urgency colours and short capture
flows. Claude Vision/human review/0.75 threshold, Resend, and Monday 08:00
America/New_York reporting are historical choices, not implemented demo features.

## Scope and pending decisions

Approved HERE: documentation verification, approved closeout, exactly ONE fresh
chat for **Staff Workflow Design Specification**, and indexing its identity.
Selected next scope: documentation of role/PIN entry, receiving, products/batches,
alert actions, rounds and offline/sync states, including permissions, screen/state
inventory, happy/error/empty flows, acceptance criteria and unresolved decisions.
Execution of that step must wait for the human's explicit approval IN THAT CHAT.

Unapproved: application implementation, schema changes, installing tools, new
application/connected tests, deployment/publication/pushing/merging, permission
changes, rollout, archiving or another continuation. The next checkpoint needs a
new transition approval. Future implementation and client sharing remain decisions.

## Rollback and preservation

No rollback occurs now. Prior dated records and the source chat remain intact.
If documentation rollback is requested later, revert only transition pointer/
status/authorization edits using the earlier packet and retain this packet for
audit. Do not reset/clean the root repository or remove preexisting prototype work.
The production app is still isolated from the preview entry point.

Hosted rollback/unpublication/access changes require specific approval. There is
only one documented successful saved release, so a prior rollback target is not
established. Do not invent a version or remove the Site. Preserve ignored artifacts
separately if later cleanup is approved; nested Git history requires separate care.

## Exact next steps

1. Finish documentation checks in this source chat and save evidence here.
2. Create exactly one fresh local project chat with NEXT_CHAT_OPENING.md; no fork,
   transcript copy or model override. Record the returned actual title/ID and
   confirm its waiting acknowledgement using a compact task-status snapshot.
3. Update index/stable pointer/ledger with that result. Keep source chat unarchived.
4. Human opens the continuation and explicitly approves the named documentation
   step there. Before that: acknowledgement only; no files, tools, planning or work.
5. After approval there, read the stable pointer, this handoff, current plan/ledger
   and relevant specs; perform only the selected design-spec step. Do not infer
   external-action authority from historical publication or this handoff.
6. At its checkpoint, update plan/ledger, save fresh dated executive/engineering
   records, update index/pointer and wait for the next transition approval.

Original [setup engineering record](../ch01-workflow-checkpoint/ENGINEERING_HANDOFF.md)
and [evidence](../ch01-workflow-checkpoint/EVIDENCE.txt) remain unchanged.
