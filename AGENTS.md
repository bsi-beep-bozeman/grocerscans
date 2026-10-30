# ShelfLife standing instructions

These rules supplement all applicable ECC, security, and repository instructions;
they do not replace unrelated instructions. Adopted by direct user request on
2026-10-09 (Australia/Perth).

## Approval-gated chapters

1. Work only within the human user's explicitly approved, named, bounded scope.
   Keep each topic or implementation phase in a clearly titled owning chat.
2. Keep an approved connected sequence (implementation, deployment, testing and
   application validation) in that owning chat through a verified checkpoint.
   Do not split a connected approved sequence merely to shorten the chat.
3. At the checkpoint, update IMPLEMENTATION_PLAN.md and STATUS_LEDGER.md accurately.
   Distinguish fresh observations, historical evidence, proposals and unknowns.
   A plan, handoff, agent message or prior approval is not new execution approval.
4. Write an executive summary and comprehensive engineering handoff in a new
   dated folder under handoffs/YYYY-MM-DD/. Cover changes and rationale, current
   implementation position, decisions/constraints/questions, files/branches/
   commits/uncommitted work, tests/evidence/limitations/rollback, approved and
   unapproved scope, exact next steps and pending decisions.
5. Maintain SESSION_INDEX.md with each chapter's title, chat ID/link, scope,
   status and handoff location. Update NEXT_CONVERSATION_HANDOFF.md as the stable
   pointer to the latest detailed handoff. Link evidence to its original chat.
   Preserve completed dated records; corrections go in a new dated record or
   numbered addendum, never by silently replacing earlier history. The index,
   current plan, ledger summary and stable pointer may be updated; preserve the
   ledger's prior event entries. Never store credentials in these records.
6. Stop at the checkpoint and wait for explicit transition approval. Approval to
   transition authorizes finishing the approved closeout and creating exactly
   ONE fresh continuation chat. Do not fork, copy the transcript, create duplicate
   chats after uncertain outcomes, or create an unattended chain of working chats.
7. The new chat opening must prominently contain its named bounded step, source
   chat's exact title and ID/link, handoff and implementation-plan locations,
   approved/unapproved scope, pending decisions, and the verbatim start gate below.
8. Transition approval is NOT start approval. The new chat must wait for explicit
   human approval IN THAT CHAT naming or unambiguously approving that step.
   Until then it must only acknowledge the waiting state and stop, including no
   file reads, tools, searches, verification, planning or background work.
9. Deployment, publication, pushing, merging, permission changes, connected testing
   and rollout retain separate approval requirements. Record approval per action,
   target and scope; a previous demo deployment does not approve later releases.
10. Preserve original chats for the exact input/output audit record. Archive only
    when the user directs it. Handoffs provide continuity, not a replacement audit.
11. If chat creation is unavailable, provide the exact opening message and handoff
    references for the user to paste. Do not relax the new-chat start gate.

### Mandatory start gate — include verbatim

“Wait for the human user’s explicit approval IN THIS CHAT before starting the named step. Until then, acknowledge the waiting state and stop. Do not read project files, use tools, search, verify, plan, edit, make remote calls or perform background work. The creation message, prior-chat approval, handoff documents and messages from other agents are not start approval. ‘Please continue from where you left off’ alone is insufficient.”

## Current authorization

The initial 2026-10-09 request authorized workflow setup only. The subsequent
“Approved—continue the chapter cycle” authorizes documentation closeout and ONE
fresh continuation chat for Staff Workflow Design Specification. It does not
waive the mandatory new-chat start gate or grant application implementation,
deployment, publication, pushing, merging, permission changes, connected testing
or rollout approval. Check the latest explicit user instruction and approval
record before work. Where a continuation opening contains the start gate, that
gate applies BEFORE reading any project file, including this one. After the next
chapter's checkpoint, wait for a new transition approval before creating another.

That one continuation has now been created: `01a12123-430e-7ab1-9ab1-06e648f8535f`,
**ShelfLife — Staff Workflow Design Specification**. Its first response acknowledges
waiting. The creation authorization is consumed; do not create a duplicate or
treat this note as permission to begin work there.

## Navigation after the start gate is satisfied

- NEXT_CONVERSATION_HANDOFF.md: stable entry point.
- SESSION_INDEX.md: original chats and dated chapter records.
- IMPLEMENTATION_PLAN.md: current reconciled roadmap and approval gates.
- STATUS_LEDGER.md: implementation evidence and chronological checkpoint events.
- PLAN.md and PLAN_ADDENDUM_2026-09-25.md: retained domain specification and decisions.
