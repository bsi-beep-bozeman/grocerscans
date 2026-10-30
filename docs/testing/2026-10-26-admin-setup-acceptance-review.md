# S1 acceptance evidence review

2026-10-26 Australia/Perth. Documentation review owned by [ShelfLife — Admin Setup Acceptance Review…](codex://threads/01a17543-b4ed-7153-97e3-2658f0ddf88d), full named step **Admin Setup Acceptance Review and Receiving Scope**. Human start approval and one chapter transition were granted in this chat. No runtime tests were authorized or run here.

## Disposition

The retained evidence supports a **bounded local engineering checkpoint** for administrator setup. It does not establish complete S1 acceptance across every originally specified layer. In particular, S1-08/09/10/11 have explicit residual coverage gaps below. Formal human acceptance of the bounded checkpoint remains pending unless subsequently recorded in the owning chat. Approval to conduct this review is not acceptance of its findings or permission to run missing tests.

All application results below are historical executions in Chapters 05/06, even where their date is today. Fresh work here consists of reading criteria, test source and retained outputs and checking documentation/source integrity. No Docker, database, browser, app, device or hosted resource was started, queried or changed.

Evidence keys:

- **L:** [Chapter05 local evidence](../../handoffs/2026-10-15/ch05-admin-setup-foundation/EVIDENCE.md): 73 combined cases plus one additional accessibility case, clean final analysis. Includes fake repository/widget tests; not live authorization.
- **T:** [Transaction log](../../handoffs/2026-10-15/ch06-admin-setup-validation/TRANSACTION_01.log) and [assertion source](../../product/supabase/tests/store_setup.sql).
- **C:** [19 concurrency groups](../../handoffs/2026-10-16/ch06-backend-validation/CONCURRENCY.json).
- **A:** [23 Auth/API groups](../../handoffs/2026-10-15/ch06-admin-setup-validation/API.json), with [execution limitations](../../handoffs/2026-10-16/ch06-backend-validation/EVIDENCE.md).
- **B16:** [Five October16 UI groups](../../handoffs/2026-10-16/ch06-browser-validation/BROWSER_CHECKS.json).
- **B26:** [17 October26 recorded groups](../../handoffs/2026-10-26/ch06-browser-completion/BROWSER_CHECKS.json) and [test notes](../../handoffs/2026-10-26/ch06-browser-completion/TEST_NOTES.md). Counts include qualified observations; they are not 17 independent full acceptance criteria.
- **D:** [Database checkpoint](../../handoffs/2026-10-26/ch06-browser-completion/DATABASE_CHECKPOINT.json), [baseline restore](../../handoffs/2026-10-26/ch06-browser-completion/RESTORE.json), [cleanup](../../handoffs/2026-10-26/ch06-browser-completion/CLEANUP.json).

Original test audit: [Chapter05](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d), [Chapter06](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a). The [original S1 criteria](../superpowers/plans/2026-10-12-staff-workflow-scope-acceptance.md) remain unchanged.

## S1-01–12 reconciliation

“Supported locally” is a review disposition, not a new test pass or human sign-off. A scenario with a missing required layer remains partial.

| Criterion | Retained evidence and supported result | Review disposition / remaining limit |
|---|---|---|
| S1-01 identity and session replacement | L gate/repository cases; A inactive, conflicting, non-admin identities and revocation; B26 viewer/staff denial, sign-out and other-org isolation | Supported locally for setup entry. Does not certify full four-role operational routing or future staff PIN sessions. |
| S1-02 saved draft resume | L controller/forms; B16 saved/unsaved handling; B26 page reload and fresh Chrome process restore draft6/active1 | Supported locally. Fresh process used privately preserved browser storage; not a physical-device restart or a promise of crash durability for unsaved admin input. |
| S1-03 partial capability activation | L readiness/review cases; T activation snapshot; A activation and exact retry; B26 actual activation; D no inventory changes | Supported locally. “Configuration ready” still means workflow implementation pending; no receiving end-to-end claim. |
| S1-04 validation and missing policy | L contract/validator cases; T invalid payload/precision/reference assertions and atomicity; A invalid contract rejection | Supported locally by complementary unit/SQL/API evidence. Not an exhaustive UI permutation of every field, nor legal verification of any policy. Fixed past-date flags remain false. |
| S1-05 reference edits/history | T preset edit/duplicate/deactivation, renamed location snapshot; C reference/activation races; B16 reference editing/deactivation; L review regressions | Supported locally. Active historical configuration stays immutable; operational receipts consuming those versions await S2. |
| S1-06 concurrent saves/activation | C explicit blocking, one-winner conflicts, save/activation order and same/different-org checks; B26 two real admins and explicit reload | Supported locally. Finite scenarios do not prove every possible interleaving. |
| S1-07 retry and duplicate effect | T/A activation exact retry and changed-key-payload rejection; C same-operation races; L adapter/controller; B26 dropped committed save response and identical retry; D one operation/audit | Supported locally. The browser fault used a draft save; activation retry is supported at SQL/API layers, not a separate browser activation-response-loss run. |
| S1-08 role and tenant boundary | T real DB role/grant assertions; A nine disallowed variants, anonymous, cross-org and direct table/helper denial; B26 staff/viewer/other-org UI checks | Partial against the literal matrix: no separately identified staff fixture with is_shift_lead=true was found. Staff denial is relevant but must not be renamed a fresh lead-specific test. Staff finance/supplier privacy across legacy tables is outside S1 proof. |
| S1-09 revoked role and audit failure | T/A revoked admin including recorded retry; C revocation/expiry after lock wait; L typed denied/error paths | Partial. No retained injected audit-insert failure execution was found in T/C/A sources/results; rejection atomicity is not the same experiment. No actual browser review-then-revocation rejection sequence was found. Prior pointer/operation/audit rollback under injected failure and actionable UI remain targeted checks. |
| S1-10 lifecycle/offline | L lifecycle dialog concealment; B16 unsaved input; B26 reload, fresh process, offline verification denial, online recovery, injected visibility event and real headed focus loss | Partial. Android/native minimization/hidden-window/OS lock unverified; browser-back sequence not separately identified. Idle lock observed at 309.309 seconds, not exact five-minute firing. No new claim of durable unsaved admin data. |
| S1-11 layout/accessibility | L 390/1440 widths at 200% text, semantics/keyboard and one >=56px save target; B26 six narrow pages and lower controls/focus | Partial. No OS screen-reader announcement certification, full manual target-size inventory, or physical Android large-text result. Selected semantics and one measured target do not prove every control. |
| S1-12 no inventory effects/history | T counts; A/C six nonempty sentinel fingerprints; D unchanged values, immutable active1 vs draft6; baseline restore verified | Supported for local setup isolation. Application source routes to setup; retained RPC observations support setup-only behavior, not a newly captured exhaustive network trace. Restoring the empty disposable baseline is cleanup, not a production configuration rollback. |

## Whole-design acceptance coverage

| Accepted criteria | Current position and owner of remainder |
|---|---|
| AC29 | Local admin save/resume supported by S1. Human acceptance pending. |
| AC30 | Configuration portion supported; actual receiving with transformations unavailable requires S2 execution evidence. |
| AC31 | Policy-authoring portion supported; staff enforcement and effective receipt fields belong to S2. |
| AC33 | Setup reference/version history supported; confirmed-receipt historical meaning remains S2/S3. |
| AC34 | Missing-rule/setup/manual-option behavior supported at setup level; actual manual receiving and unsupported-label path remain S2. |
| AC01–03, AC06–12, AC21–28, AC32 | S2 identity/receiving/queue criteria remain unaccepted as complete staff workflows. S1 gives partial identity/UI evidence only. AC12 and AC21–24/32 also have later stock-action responsibilities. |
| AC04–05, AC13–17 | S3 containment/stock-action work remains unimplemented within the accepted design. |
| AC18–20; rounds parts of AC21–27 | S4 paired rounds remain unimplemented. No solo completion exception. |

## Concrete remaining acceptance decisions

1. Accept the bounded local engineering checkpoint with these gaps, or keep formal acceptance pending. Neither choice declares all twelve criteria fully passed or authorizes delivery.
2. Decide whether to close S1-08/09 before S2 source work. Proposed targeted checks: explicit lead fixture, audit-insert failure with rollback counts/pointer, actual UI revocation after review; require the exact local backend/test approval in the S2 packet.
3. Select an actual Android device and OS, desktop OS/browser lifecycle cases and assistive technology if full S1-10/11 acceptance is required. Device identity is unknown, so that lane is not execution-ready.
4. Generic login connectivity wording remains a usability issue. Proposed copy: “Could not connect. Check your connection and try again.” Keep wrong-credential messages generic; change only on separately approved source scope.

The final browser-state private dump was archive-listed but not restore-tested. The original baseline restore did pass. All containers/listeners were stopped/absent at Chapter06 cleanup; that is the last recorded runtime state, not a new observation here. Do not start binding-backup containers. Do not rerun fixture-specific checkpoint assertions against the restored empty baseline.

Next proposal: [S2 receiving, identity and queue scope/approvals](../superpowers/plans/2026-10-26-receiving-identity-queue-scope.md). This review changes no source, permissions, tests or accepted product policy.
