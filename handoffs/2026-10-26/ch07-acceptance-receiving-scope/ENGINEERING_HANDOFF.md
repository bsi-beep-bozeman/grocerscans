# Chapter07 engineering handoff

2026-10-26 Australia/Perth. Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`. Exact desktop source title **ShelfLife — Admin Setup Acceptance Review…**, full named chapter **Admin Setup Acceptance Review and Receiving Scope**, ID `01a17543-b4ed-7153-97e3-2658f0ddf88d`, [original inputs/outputs](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d). Preceding [Chapter06](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a) owns all backend/browser execution cited here. No source chats archived.

## Authority and changes

The user explicitly approved “Admin Setup Acceptance Review and Receiving Scope” and “then continue the chapter cycle.” This satisfies this chat's start gate for documentation-only evidence review and S2 scope/approvals. It authorizes one fresh continuation after closeout. It does not accept the review's eventual findings, grant S2 implementation/testing, or waive the next chat's mandatory start gate. [Decision record](DECISIONS_AND_APPROVALS.md).

New deliverables:

- [S1 review](../../../docs/testing/2026-10-26-admin-setup-acceptance-review.md): requirement-by-requirement evidence, original sources, coverage limits, whole-design AC ownership and specific remaining checks.
- [S2 packet](../../../docs/superpowers/plans/2026-10-26-receiving-identity-queue-scope.md): A/B/C slices, source/data boundaries, identity/queue/receipt invariants, storage/session decisions, acceptance checks and chapter-qualified approval requests.
- This dated checkpoint plus updated IMPLEMENTATION_PLAN, STATUS_LEDGER summary/additive events, SESSION_INDEX and NEXT_CONVERSATION_HANDOFF. Original design, acceptance procedure, all prior handoffs and ledger events preserved.

Rationale: a tested admin configuration is a prerequisite, not an implemented staff workflow. The original S1 device/manual layers cannot be declared passed from mocks or browser screenshots. Receiving needs secure staff attribution, durable drafts, safe reads and idempotent confirmation; catalog approval must remain separate from stock creation.

## Acceptance position

S1-01–07 and S1-12 have complementary local evidence supporting their bounded engineering claims, with layer-specific limits in the matrix. S1-08 has no separately identified shift-lead=true fixture. S1-09 has revocation/denial/atomicity evidence, but no located injected audit-insert failure test and no actual UI review-then-revocation run. S1-10 is partial: browser focus loss and lock by309.309 seconds are recorded; native hidden/minimized/OS lock and Android are not. Browser-back is not separately identified. S1-11 has local width/200%-text/semantics and browser keyboard evidence, but no OS screen-reader, full target-size audit or physical-device certification. These are evidence limits, not proof that the corresponding behavior fails.

Formal human acceptance of even the bounded checkpoint remains pending unless a later dated receipt records a response. An optional in-chat question offered bounded acceptance or keeping it pending; no answer is inferred from silence or the instruction to perform the review. Full product/release acceptance is not claimed.

Historical results: Chapter05 74 local cases across two final runs and clean analysis; Chapter06 transaction suite,19 concurrency groups,23 Auth/API groups,61 DTO decodes, restart and corrected restore; five October16 UI groups and17 October26 recorded groups with qualifications. Counts are different units and are not added together. The [evidence review](../../../docs/testing/2026-10-26-admin-setup-acceptance-review.md) links primary results. No such application test was rerun here.

## Fresh source findings and implementation position

`main.dart` uses `SupabaseAdminSetupGate`; it is no longer the historical signed-in stub. Legacy `supa.dart` still resolves kiosk first and does not give full active/supplier ambiguity enforcement. Retained PIN RPCs accept PIN-bearing writes without the accepted session/cooldown/operation contract. Product rows contain finance fields. These are source observations, not deployed probes. S2 must inventory direct table/view/RPC permissions, not merely return a smaller DTO while leaving sensitive direct reads available.

S2-A proposes identity/read/session and durable draft foundation only. B adds known printed receipts and safe details. C adds unknown catalog approval/link, computed dates and approved scanner/device behavior. No new code exists for these slices in this chapter. Full S2, S3 stock actions and S4 paired rounds remain incomplete. No package or platform storage adapter has been selected. Native/browser key handling, crash-safe schema migration, server session lifetime/renewal and authorized draft recovery must be concrete before implementation approval.

## Files, branch and preservation

Fresh read-only Git observation: branch `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch/stage/commit/push/merge. [Before status](GIT_STATUS_BEFORE.txt) records inherited edits to PLAN, PLAN_ADDENDUM, RESUME, AndroidManifest, main/login, pubspec and preview widget test; numerous existing setup/docs/handoffs/report paths are untracked. Do not reset/clean or accidentally commit all of them.

[Preservation baseline](PRESERVATION_BASELINE.json) hashes285 preexisting files under handoffs/docs/app lib/tests/migrations/harnesses/reports plus root/domain/package files. Five current documents are copied in `prior-current-docs/`. [Source comparison](SOURCE_COMPARISON.json) freshly matches26 implementation files to the Chapter06/05 manifest. Seven migration sources are recorded in [hashes](MIGRATION_HASHES.json) and verified against the prior checkpoint. The final documentation check records preservation, links, ledger order and gate checks. Unavailable global Git ignore-file access emitted warnings, but status/HEAD commands completed.

## Runtime, backups and rollback constraints

Last recorded, not re-observed: Chapter06 restored the disposable five-migration/zero-user/zero-org baseline and removed setup tables; stopped five owned services and three binding backups; four listeners absent. Shared Docker/unrelated workloads stayed unchanged then. This chapter made no container/service/network request. Never start `_binding_backup` containers, especially the old DB sharing the target volume. Never use default54321 as fallback or bind the backend broadly to reach a phone.

Private ignored files remain under `.cache/ch06-validation/private/`; no private file contents were read or copied in this review. Chapter06 records hashes for before-setup.dump, tested-20261016.dump and browser-tested-20261026.dump. Baseline restore was demonstrated; final browser dump archive listing is not restore proof. Existing browser account/config files refer to fixtures removed at cleanup. Source-only commands must not start/reapply/restore them without new exact approval. See [Chapter06 handoff](../ch06-browser-completion/ENGINEERING_HANDOFF.md).

Documentation rollback uses saved current copies for comparison, restores only desired current prose and appends a correction; preserve dated evidence/receipts and original ledger history. No application/database rollback was needed. Any future source rollback must isolate the approved diff; hosted restore/deployment/permission change remains unapproved. [Detailed rollback and next steps](ROLLBACK_AND_NEXT_STEPS.md).

## Next chapter and exact gates

The next bounded step is **Receiving Foundation Contract and Storage Decision**, documentation only. Its [opening](CONTINUATION_OPENING.md) includes the exact mandatory gate; [receipt](CONTINUATION_RECEIPT.md) records creation outcome. Creation is not approval to begin, nor S2-R01/R02 authority. Do not send a work follow-up or dispatch remote agents. Keep original chats available for audit.

After explicit human start approval in that new chat: read this packet, settle the S2-A contract and storage decision with current primary documentation, produce exact file/package/test and permission-diff proposals, then request only the next concrete action approvals. Missing device identity and hosted targets are unresolved, not implied defaults. Keep any newly approved connected sequence in that owning chat. At its checkpoint close out and wait for fresh transition approval before creating another chat.

## Actual continuation outcome

Exactly one fresh [ShelfLife — Receiving Foundation Contract…](codex://threads/01a17814-e94a-74a1-80fa-d1027c7eff88), ID01a17814-e94a-74a1-80fa-d1027c7eff88, was created. Full named step: Receiving Foundation Contract and Storage Decision. Waiting acknowledgement/idle state and no tool marker verified; no start follow-up sent. Creation authorization consumed. [Receipt](CONTINUATION_RECEIPT.md). Source chat remains unarchived.
