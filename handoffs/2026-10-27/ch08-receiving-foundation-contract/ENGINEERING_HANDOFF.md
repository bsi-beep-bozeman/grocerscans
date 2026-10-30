# Chapter08 engineering handoff

2026-10-27 Australia/Perth. Exact desktop title **ShelfLife — Receiving Foundation Contract…**, full named chapter **Receiving Foundation Contract and Storage Decision**. ID `01a17814-e94a-74a1-80fa-d1027c7eff88`; [original inputs and outputs](codex://threads/01a17814-e94a-74a1-80fa-d1027c7eff88). Workspace `D:/LLM-Data/Claude-Desktop/claude-code/shelflife`.

## Outcome and rationale

The [contract](../../../docs/superpowers/specs/2026-10-27-receiving-foundation-contract.md) is the proposed implementation specification. The [amendment](../../../docs/superpowers/plans/2026-10-27-receiving-foundation-approval-amendment.md) defines exact paths, three additive migrations, direct dependency pins/transitive resolution limits, offline commands, connected target prerequisites and A01–A12 acceptance groups.

Selected architecture: opaque32-byte random server staff secret, digest-only storage, eight-hour absolute lifetime, no silent renewal; device-serialized durable five-failure/five-minute cooldown with expected denial committed rather than raised/rolled back; strict derived tenant/actor/scope reauthorization. Browser IndexedDB/idb_shim2.10.1+1 and Android SQLite/sqflite2.4.5 store AES-256-GCM encrypted envelopes via cryptography2.9.0; existing web1.1.1 is promoted to direct. Keys are server-held per actor/device partition and memory-only on client while unlocked. A does not submit stock or catalog operations.

Key rationale: PIN-derived local keys permit offline guessing; local secure key persistence would not itself enforce staff re-verification. Server key release meets the accepted no-cold-offline-unlock boundary, with explicit server-operator/backup trust. Drift remains viable, but its browser Wasm/worker/storage paths add unnecessary deployment validation for this envelope store. No package was downloaded/installed. Browser quota/eviction and Android clear/uninstall remain real durability limits.

Safe-read DTOs alone are insufficient. The new migration proposal closes direct client access to17 legacy tables, five reporting views and19 unique legacy helper/RPC names (all reviewed overloads); preserves eight already restricted setup tables and six public S1 setup RPCs. Runtime effective/default ACLs are unknown. Applying the proposed restriction affects legacy viewer/supplier/admin consumers as well as staff; consumer inventory and target-specific permission approval are mandatory before execution. No live grant was changed.

Lead recovery deliberately authorizes a full original-actor partition on the same device, with recent online PIN/current lead flag and atomic audit-before-key-release. It retains original actor/recoverer/reason and creates no receipt. Admin recovery is denied in A pending a separate proof design. A12 accessibility/device layers cannot pass through fake storage or unit-only evidence.

## Decisions, limits and approvals

Named human start and one transition are granted; [approval record](DECISIONS_AND_APPROVALS.md). Technical proposal acceptance and all S2A-R01/R02/R03/R05/R06 execution permissions remain outstanding. Human approval of the next exact local bundle can authorize source, pinned dependency resolution and offline checks together; it cannot imply database application, browser/device tests, publishing, permission changes, commit/push/merge or rollout.

Accepted D02/D07 remain fixed: active-session offline drafts; lock after five minutes inactivity, background or person switch; online verification after lock/restart. Absolute eight-hour lifetime is newly selected. Server cannot instantaneously revoke a bearer when a disconnected client backgrounds; client memory erasure is best effort under managed runtimes. Keys stored in private server bytea do not protect against compromised DB operator/raw backups. Hosted key wrapping/retention/access needs separate approval/design before release. No real policy values or legal defaults invented; no automatic stock from catalog approval; lead action and paired-round constraints retained.

S1 bounded checkpoint acceptance is recorded in the [Chapter07 addendum](../../2026-10-26/ch07-addendum-01-s1-acceptance/ACCEPTANCE_ADDENDUM.md). Do not ask the same acceptance question again or claim full S1 acceptance. Residual S1-08/09/10/11 gaps remain. S2-B/C and S3/S4 are not implemented by this chapter.

## Source state and preservation

Read-only Git observations: `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`. No branch, stage, commit, push or merge. Inherited tracked edits: PLAN, PLAN_ADDENDUM, RESUME, AndroidManifest, main.dart, login.dart, pubspec.yaml and widget_test.dart; untracked setup/preview/docs/handoffs/test/report/site files remain. [Git inventory](GIT_STATUS_BEFORE.txt) is a source snapshot, not a clean-tree claim. A global ignore-file permission warning did not prevent Git observation.

New chapter files are the two dated deliverables and this handoff/evidence/approval/rollback/opening/receipt packet, package metadata and documentation checker/results. Current IMPLEMENTATION_PLAN, STATUS_LEDGER summary/additive events, SESSION_INDEX and NEXT_CONVERSATION_HANDOFF are reconciled. Before copies are in `prior-current-docs/`; [314 protected file hashes](PRESERVATION_BASELINE.json) cover preexisting handoffs/docs/source/tests/migrations/reports and key root/manifests. Dated history is preserved; original ledger history is checked verbatim. Additional comparison to Chapter07's26 source hashes is recorded by the checker.

## Verification and runtime

[Evidence](EVIDENCE.md) distinguishes fresh reads/document checks from historical execution and future acceptance cases. `DOCUMENTATION_CHECK.json` is the final machine-readable result, not a substitute for application tests. There are zero newly executed application, backend, browser or device tests. No SDK command, dependency solver or application build ran.

Last runtime evidence remains [Chapter06](../../2026-10-26/ch06-browser-completion/ENGINEERING_HANDOFF.md): restored five-migration empty disposable baseline, owned services stopped. Never start binding-backup containers, use54321, probe/restore private files casually, or assert fixtures against the empty baseline. Final browser dump is archive-listed, not restore-tested. No credentials or ignored backups were read/copied into this packet.

## Exact next steps

1. Create the single authorized continuation using [opening](CONTINUATION_OPENING.md), then record its exact ID/title/waiting state in [receipt](CONTINUATION_RECEIPT.md). Do not retry an uncertain creation without checking existing state. Preserve source unarchived.
2. New chat initially acknowledges waiting and stops: no reading/tools/planning until explicit human approval there. After approval read this packet, the contract and amendment. Obtain the concrete S2A-R01/R06/R02 bundle; approving only review is not implementation authority.
3. With that bundle, preserve dirty baseline; author bounded source/test/migration changes; resolve exact pins/necessary transitives; review graph/diff; run offline checks. Do not enable operational access on any backend.
4. If connected validation is desired, first present actual migration/grant diff and fixture/target/backup/cleanup plan for R03 and exact browser/build/device R05 approval. Keep any approved connected sequence in that owning chat through verification and cleanup. Otherwise report the bounded local checkpoint and untested platform/API limits accurately.
5. At that next checkpoint save dated evidence/handoff and update navigation. Wait for fresh transition approval before another chat. No inherited authority for an unattended cycle.

[Rollback details](ROLLBACK_AND_NEXT_STEPS.md). Documentation-only completion is the achieved result; implementation/security/platform acceptance remains future work.
