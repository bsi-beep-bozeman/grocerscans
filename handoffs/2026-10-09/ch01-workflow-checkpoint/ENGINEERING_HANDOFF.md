# Chapter 01 — comprehensive engineering handoff

Recorded: 2026-10-09, Australia/Perth. This is a documentation checkpoint, not
a new application validation. Preserve this record after closeout; later changes
belong in a new dated record or numbered addendum.

## Identity and audit navigation

- Exact source title: **Review Grocerscans handoff**.
- Chat ID: `01a0ec6a-a956-71d2-88f5-ed33d81f2930`.
- [Original chat](codex://threads/01a0ec6a-a956-71d2-88f5-ed33d81f2930).
- Project ID from the app: `384f962e-dd00-4cea-a58e-9addec9ec4c2`, host `local`.
- Root: `D:\LLM-Data\Claude-Desktop\claude-code\shelflife`.
- [Session index](../../../SESSION_INDEX.md), [stable pointer](../../../NEXT_CONVERSATION_HANDOFF.md),
  [current plan](../../../IMPLEMENTATION_PLAN.md), [ledger](../../../STATUS_LEDGER.md).
- The chat contains exact inputs and tool outputs. No transcript was copied and
  no new chat was created. Earlier Claude chat IDs are unknown.

Evidence labels throughout: **Fresh** means observed in this setup turn;
**Historical** means prior chat evidence, not rerun; **Proposal** means unapproved;
**Unknown** means not established. Documentation existence is not feature completion.

## What changed and why

Historical application work added an isolated Flutter cockpit entry point to make
the visual direction and scanner journey tangible before production work. It uses
five seed-inspired product records, local SKU aliases, barcode lookup, explicit
date review and session-only state. Main production authentication was preserved.

The user later explicitly approved publishing that demo. A separate static Sites
checkout was created and deployed; the original project repository was not pushed
as part of that deployment. The current setup adds approval gates and navigation
records to reduce scrolling, maintain continuity and preserve the original audit.

Fresh documentation changes: AGENTS.md, SESSION_INDEX.md,
NEXT_CONVERSATION_HANDOFF.md, IMPLEMENTATION_PLAN.md, STATUS_LEDGER.md, this dated
folder and additive entry-point notes in PLAN.md, PLAN_ADDENDUM_2026-09-25.md and
RESUME.md. No prior plan content is deleted or rephrased. This setup does not
modify application source, execute tests, commit, push, publish or alter access.

## Current implementation position

- Historical/fresh-source: Flutter is the current deliverable. `lib/main.dart`
  still initializes Supabase; the preview uses `lib/preview.dart` independently.
- Historical: preview inventory and rounds are session-only. Saved preview
  batches add activity entries; they are not durable stock writes.
- Historical: barcode capture uses mobile_scanner. Typed or barcode-encoded SKU
  values resolve through the sample catalog. UPC-A is normalized to EAN-13.
  Unknown products stay unknown; arbitrary printed SKU/date OCR is not implemented.
- Fresh: supplier migrations exist in two parts (enum addition, then table/RLS).
  Root HEAD includes the supplier-tier commit. The old RESUME “NOT done” is stale.
  This does not establish that migrations ran against a deployed database.
- Historical: SDK at `D:\dev\flutter`, PUB_CACHE at `D:\dev\pub-cache`.
  Android SDK was missing, so no APK or physical-phone scanning validation was
  claimed. Current toolchain availability is unknown; it was not rechecked.
- Unknown: live production database, Supabase connection readiness, client feedback,
  current demo availability and current audience. Do not infer them from source files.

## Repository and file inventory

Fresh main-repository branch: `main`.
HEAD: `f56d5068e94cf80819f55be952a95769ad508c97`.
Recent preceding commits observed: `84143c6` (current_app_role rename), `52aedef`
(locked decisions), `dfc2795` and `f0fa27b` (plan addenda).

Fresh pre-setup tracked modifications (preserve):

- `app_flutter/android/app/src/main/AndroidManifest.xml` — camera/network declarations.
- `app_flutter/pubspec.yaml` — local font assets.
- `app_flutter/test/widget_test.dart` — preview lookup/layout/scan-save tests.

Fresh pre-setup untracked paths (preserve):

- `app_flutter/PREVIEW.md` — operation and publication notes.
- `app_flutter/assets/` — bundled fonts and licence.
- `app_flutter/lib/preview.dart` — standalone preview entry point.
- `app_flutter/lib/preview/` — cockpit and sample catalog.
- `app_flutter/serve-preview.mjs` — local static preview server.
- `site-preview/` — separate nested Sites repository.

The status command displayed these six app/hosting groups plus the three modified
tracked files; directory entries are not individual-file counts. Fresh tracked
diff before setup: 3 files, 60 insertions, 24 deletions. Setup adds documentation
on top; see EVIDENCE.txt for final status. Nothing is staged or committed by setup.

Important source/reference paths:

- `product/supabase/migrations/20260924030000_init.sql`
- `product/supabase/migrations/20260924030001_rls.sql`
- `product/supabase/migrations/20260924030002_rpcs.sql`
- `product/supabase/migrations/20260925000000_supplier_tier.sql`
- `product/supabase/migrations/20260925000001_supplier_tier.sql`
- `product/supabase/seed.sql`; `reference/AL_SAFA_MARKET_OS.md`.
- `PLAN.md`, `PLAN_ADDENDUM_2026-09-25.md`, `ASSESSMENT.md`, `MARKET.md`.
- `product/js/` and `app/` are historical reference clients, not current deliverables.

## Hosted demo and evidence

Historical publication URL:
https://shelflife-cockpit-preview.ppdpainting-4984.chatgpt.site

- Site ID: `appgprj_6abbd9aa5a808191a1121fdf09932ab5`.
- Deployment ID: `appgdep_6abbdb9e80a881918b0e74ce420a7261`.
- Saved version: `appgprj_6abbd9aa5a808191a1121fdf09932ab5~appgver_5dd564c842088191a0dfba099fbdb8e4`.
- Historical native tool result: `succeeded`, no failure message, 2026-09-29.
- Fresh hosting checkout: `site-preview/`, branch `main`, clean when inspected.
- Fresh hosting HEAD: `e806215c81926baaaec787030a935d408937bbed` (Update Site source).
- Manifest: `site-preview/.openai/hosting.json`; static output in `dist/`.
- Historical audience: custom owner-only; no external client access granted.
- Current deployment health/access are UNKNOWN. No remote revalidation this turn.

Historical validation:

1. `flutter test --no-pub`: three passing tests (catalog exact/normalized lookup,
   phone 390×844 and desktop 1440×1100 layout and review/date/save journey).
2. Targeted `flutter analyze --no-pub lib/preview.dart lib/preview test/widget_test.dart`:
   no issues. Earlier whole-project analysis reported an existing deprecated
   anonKey usage; do not claim a clean whole-project analysis.
3. Web release build with `--no-web-resources-cdn --target lib/preview.dart` succeeded.
4. Desktop, phone and scanner screenshots inspected; fresh existence confirmed at
   `app_flutter/build/cockpit-desktop.png`, `cockpit-phone.png`, `cockpit-scanner.png`.
   These are ignored build artifacts, not durable Git evidence.
5. Browser captures reported no page errors after bundling renderer and fonts.
   No hardware camera recognition, APK, production auth, live RLS or offline queue test.

Fresh setup validation is documentation-only: link targets, required fields/start
gate, Git diff whitespace and final change inventory, recorded in EVIDENCE.txt.
No app builds, tests, network queries or production checks were run for this setup.
App chat-list metadata was read solely to identify this owning conversation.

## Decisions, constraints and unresolved questions

Retain Flutter + Supabase; Android/web first; admin/staff/viewer/supplier; shift-lead
flag rather than manager UX. SQL still retains an unused manager enum value.
Keep large expiry numerals, white surfaces, urgency colours and short capture flow.
The store's operating state remains unknown; category policies stay conservative.
OCR via Claude Vision with human review and 0.75 threshold, Resend and Monday
08:00 America/New_York reports are historical design decisions, not demo features.

Pending: next chapter scope, transition approval, in-chat start approval, how to
handle existing uncommitted prototype files in a later approved implementation,
backend environment, Android test device/toolchain and any client-sharing request.

## Approved versus unapproved

Historical approved work: initial prototype and one expressly requested demo
publication. The earlier upload rejection arose from ambiguous phrasing; the
user clarified and approved publication, which subsequently succeeded.

Current approved work: set up this chapter workflow and accurately document local
state. This authorization includes documentation inspection/verification only.

Not approved: beginning staff-workflow design/implementation; new tests against
the application or services; deployment, publication, pushing, merging, access
changes, installations, rollout, archiving, or creating a continuation chat.
Transition approval authorizes ONE fresh chat plus approved closeout, not starting
its named work. The new chat must wait with no tools/files/planning until explicit
approval from the human IN THAT CHAT. Prior records/messages are never approval.

## Rollback and preservation

Documentation rollback, if later requested: remove only the new workflow files
and additive pointer blocks identified above, preserving unrelated files and
the preexisting prototype diff. No rollback is performed here.

Prototype isolation: `lib/main.dart` remains the production entry point; the
preview is selected explicitly. Do not use git reset/clean to discard unknown
work. The nested Sites repository and ignored build files need separate care.

Hosted rollback/unpublication/access changes require separate user approval.
Only one successfully saved deployment is documented; no previous good hosted
version is established. Use verified saved version IDs if a rollback is later
authorized; do not invent a rollback target or delete the Site.

Historical Windows publishing lessons (instructions for a future approved action,
not permission to execute): use installed Git Bash rather than the broken WSL
Bash; `TAR_OPTIONS=--force-local` handles drive-letter paths. A process-scoped
safe.directory was needed for the sandbox-created nested checkout. Keep credential
tokens only in tool memory/stdin, never in files. Root user Git config was not changed.

## Exact next steps — gates first

1. In the current chat, obtain explicit approval of transition and the next bounded
   scope. Proposed title: **ShelfLife — Staff Workflow Design Specification**.
2. If approved, finish only the approved closeout; record approval and any changed
   scope in a new addendum, then update index/pointer/plan/ledger.
3. Create exactly ONE fresh project chat (no fork, no copied transcript) using the
   prepared opening, amended to match the human-approved scope. Record its actual
   returned title and ID; mark WAITING FOR IN-CHAT START APPROVAL. If tools are
   unavailable, provide the exact message and paths for manual creation.
4. That chat must acknowledge waiting and stop. It must not even read this handoff
   before explicit human approval of the named step in that chat.
5. Only after that approval, read the handoff, plan and applicable instructions;
   perform only the approved bounded step. Proposed output is a design spec with
   screens, role boundaries, success/error/offline states and acceptance criteria.
6. Keep any separately approved connected sequence in its owning chat until its
   verified checkpoint, then repeat closeout. Never auto-chain working chats.
