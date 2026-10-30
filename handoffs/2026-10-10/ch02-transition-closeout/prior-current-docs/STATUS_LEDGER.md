# ShelfLife status ledger

Current checkpoint: 2026-10-10 (Australia/Perth). **Chapter 02 specification written for human review; design acceptance and implementation approval pending.**
Owner chat: **ShelfLife — Staff Workflow Design Specification**, `01a12123-430e-7ab1-9ab1-06e648f8535f` ([original chat](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f)).

Evidence labels: **Fresh** = observed in this checkpoint; **Historical** = recorded
earlier, not rerun now; **Proposal** = not approved; **Unknown** = not established.
Append checkpoint events; do not rewrite earlier event history to imply new tests.

| Date / evidence | Event and result | Approval / limitations |
|---|---|---|
| 2026-09-25 / Historical | Locked design choices recorded in plan addendum; supplier-tier source now appears in main history. | Original earlier chat IDs unknown. No claim that backend migrations were applied. |
| 2026-09-29 / Historical | User requested an initial cockpit design; Flutter preview built. Three tests, targeted static analysis, web release build and desktop/mobile screenshots passed. | Sample catalog and in-memory activity; physical-phone camera and APK not validated. Original exact tool output is in Chapter 01. |
| 2026-09-29 / Historical | Ambiguous “can you not publish” led to an unpublished Site and an upload auto-review rejection. User clarified capability and then explicitly requested publication. | No standing restriction inferred from the ambiguous phrase; later publication was expressly approved. |
| 2026-09-29 / Historical | Sites publication succeeded, deployment `appgdep_6abbdb9e80a881918b0e74ce420a7261`, source `e806215c81926baaaec787030a935d408937bbed`. | Private owner-only at last access check. Not rechecked on 2026-10-09. |
| 2026-10-02 / Historical | Next staff-workflow features proposed in Chapter 01. | User asked what comes next; this was not implementation approval. |
| 2026-10-09 / Fresh | User explicitly authorized chapter-workflow setup, excluding implementation and new-chat creation. Current chat identity verified by list_threads. | Setup-only authorization. No transition or next-step start approval. |
| 2026-10-09 / Fresh | Root main HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; three tracked prototype files modified and six untracked paths before workflow edits. Nested hosting repo main HEAD `e806215c81926baaaec787030a935d408937bbed`, clean at inspection. | Local read-only Git observations; no fetch, push, commit, deployment or application tests. Exact inventory in engineering handoff. |
| 2026-10-09 / Fresh | Supplier migrations exist and part 2 was inspected; old RESUME unfinished flag is stale. Existing screenshots and test source exist. | Existence/source review is not fresh passing tests or production verification. |
| 2026-10-09 / Fresh | Workflow documents and additive navigation pointers prepared; documentation validation recorded in the dated evidence file. | Workflow checkpoint only. No feature implementation or continuation chat created. |
| Next / Proposal | Staff Workflow Design Specification, documentation-only chapter. | Scope confirmation, transition approval, and separate start approval in the new chat are pending. |
| 2026-10-09 / Fresh, subsequent transition approval | User said “Approved—continue the chapter cycle.” Closeout and ONE fresh continuation are now authorized for the selected Staff Workflow Design Specification. | Earlier pending-transition entries are preserved history. New-chat start approval is still required; no external-action approval is implied. |
| 2026-10-09 / Fresh, transition verification | Root and nested hosting HEADs unchanged; nested repository clean. Closeout documents prepared in a new dated folder; earlier records retained. | Documentation-only checks. No application test, deployment, connected/Cowork application validation, commit, push or access change. |
| 2026-10-09 / Fresh, creation receipt | Created ONE fresh local project chat: ShelfLife — Staff Workflow Design Specification, `01a12123-430e-7ab1-9ab1-06e648f8535f`. Its first turn completed with a waiting acknowledgement; task status is idle. | Mandatory start gate included verbatim. No fork/transcript copy; no start approval sent. Source chat remains unarchived. See dated CONTINUATION_RECEIPT.md. |
| 2026-10-10 / Fresh, Chapter 02 transition request | Human said “Approved—continue the chapter cycle” in Chapter 02 and requested closeout plus a fresh continuation at the checkpoint. Assistant retained the start gate and requested the named design approval. | Request recorded; no chat created, no work started on that message alone. Future-chat start approval remains separate. |
| 2026-10-10 / Fresh, Chapter 02 start | Human said “Approved to begin **Staff Workflow Design Specification**” in the owning chat. | Documentation-only design and associated records; no implementation, application tests or external delivery. |
| 2026-10-10 / Fresh, human design decision | Human selected “Shift lead confirms stock-removal and transformation actions (Recommended)”. | Staff receive/check/pull aside; lead confirms discard, donation, corrections, freeze and conversion. No deployed permission change. |
| 2026-10-10 / Fresh, source review | Read retained requirements, role/profile routing, schema, supplier policies and staff RPCs. Root main HEAD f56d5068e94cf80819f55be952a95769ad508c97; nested hosting HEAD e806215c81926baaaec787030a935d408937bbed, clean at inspection. | G01–G10 are source findings, not live verification. Scoped shell calls recovered from sandbox runtime startup failure. |
| 2026-10-10 / Fresh, review deliverable | Version 1 specifies 13 screens, six workflow areas, permission matrix, recovery states and AC01–AC28; dated review packet and navigation/status documents saved. | Documentation checks in dated EVIDENCE.md; acceptance scenarios not executed; design acceptance pending. |
| 2026-10-10 / Proposal, review pending | Offline reauthentication, catalog approval, paired-round completion and timing proposed; units/labels/store policies unresolved. | Keep review in Chapter 02. No continuation, application/connected/Cowork tests, commit, push, deployment, permission change or archive. |

## Approval register

- Historical prototype: “can you cough up an initial design?” in Chapter 01.
- Historical publication: “Yep, so please publish this into a site, so I have
  something to present to the client, something tangible. A demo, a proto type.”
  in Chapter 01; applies to that demo publication, not future changes.
- Initial workflow authorization: 2026-10-09 setup-only request, superseded as to
  closeout/chat creation by the subsequent explicit transition approval.
- Chapter 01 transition: **granted**; its one creation authority was **consumed**
  by chat `01a12123-430e-7ab1-9ab1-06e648f8535f`. Start was pending at creation.
- Chapter 02 start: **granted 2026-10-10** by “Approved to begin
  **Staff Workflow Design Specification**”. Supersedes the earlier waiting state.
- Chapter 02 policy: **granted** for lead confirmation of stock removal and
  transformations; additional proposals still need review.
- Chapter 02 transition request: the earlier in-chat “Approved—continue the
  chapter cycle” requests closeout and one new chat at the finished checkpoint.
  It is **unconsumed**; design review remains here before transition. A future
  continuation must wait for its own explicit in-chat start approval.
- New deployment/publication/push/merge/access change/connected test/rollout:
  **not granted** by this workflow request.

## Unknowns and pending decisions

Current hosted health/access, applied database state, real catalog connectivity,
current Android toolchain/device status, and client feedback are not freshly
verified. Operating state still needs confirmation for category policies. Design
start approval is satisfied; overall acceptance is not. See specification D02–D09
for remaining decisions/approvals. Root prototype work remains uncommitted;
committing it is outside this documentation scope. Next bounded step not finalized.

Latest [handoff](handoffs/2026-10-10/ch02-design-review-checkpoint/ENGINEERING_HANDOFF.md)
and [plan](IMPLEMENTATION_PLAN.md) govern navigation, not authorization.
