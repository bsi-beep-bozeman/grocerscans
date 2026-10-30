# ShelfLife — Admin Setup Foundation

Verified local-source checkpoint: 2026-10-15, Australia/Perth.
Original audit chat: **[ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d)**, ID `01a12f57-0cf7-7fa0-8e2a-542b48d3985d`. Preserve this chat; no archive authorized.

## Outcome

The production Flutter entry now opens a verified-admin setup gate instead of the signed-in stub. Six setup steps cover store details, units/packs, receiving/hold locations, versioned category presets, product exceptions, action policies, and reviewed configuration activation. Draft handling distinguishes unsaved edits, confirmed saves, uncertain replies and conflicts. Session locks conceal protected screens and dialogs.

The matching database migration and acceptance-test source is authored and independently reviewed. It is **not applied or runtime-tested**. The new setup is therefore a locally tested implementation candidate, not a deployed working backend or production-ready release.

## Evidence

- 73 setup/preview tests passed in the final combined run, plus one additional keyboard/semantic-label/56px-target test: **74 passing local cases**.
- Whole-app offline static analysis: **No issues found**.
- Twenty-product synthetic demo catalog validation passed. Its earlier local changes are preserved; the hosted demo remains the previously observed five-product release.
- Actual Flutter widget captures: [desktop](setup-1440.png), [phone](setup-390.png). Both explicitly use one synthetic product and no backend; they are not live validation.
- Independent contract, SQL security/specification and client/UI reviews resolved their consequential findings. [Evidence](EVIDENCE.md) identifies fixes, test logs and limitations.

## What remains

The next bounded chapter is **ShelfLife — Admin Setup Backend and Application Validation**. It must first receive explicit start approval in that new chat. Backend creation, migration/grant application, connected tests, installation, device/browser validation, commit/push/merge, publication/access changes and rollout each retain their separate action/target gates.

No database has been started or changed, no new release published, and no role permission changed. Four-tier access is still not complete end to end. Staff receiving/identity/offline queue, stock actions and paired rounds remain later implementation slices.

The human approved exactly one chapter transition. Its actual outcome is recorded in [CONTINUATION_RECEIPT.md](CONTINUATION_RECEIPT.md). No further automatic chapter is authorized. [Engineering handoff](ENGINEERING_HANDOFF.md) contains exact next steps and rollback guidance.
