# Staff workflow decisions — Chapter 03 addendum

2026-10-10 (Australia/Perth). **Overall design accepted, including admin onboarding and editable presets. Documentation only; implementation/testing and delivery remain unapproved.**

Owning chat: **[ShelfLife — Staff Workflow Design Decisions Review](codex://threads/01a125ee-a20b-7663-a7f7-f5fe694580d4)**, ID `01a125ee-a20b-7663-a7f7-f5fe694580d4`. Source: **[ShelfLife — Staff Workflow Design Specification](codex://threads/01a12123-430e-7ab1-9ab1-06e648f8535f)**, ID `01a12123-430e-7ab1-9ab1-06e648f8535f`.

The human explicitly approved starting this documentation-only chapter: “Approved to begin **Staff Workflow Design Decisions Review**”. This addendum supplements [version 1](2026-10-10-staff-workflow-design.md); it does not overwrite that historical record. Where decision status differs, this dated record is current. Full question wording and human replies remain in this owning chat.

## Accepted decisions

| ID | Human response / source | Accepted behavior |
|---|---|---|
| D01 | Retained human decision from Chapter 02; not requested again | Ordinary staff receive/check/pull aside; a shift lead confirms discard, donation, stock corrections, freeze and conversion. |
| D02 | “Accept this initial offline limit” | During an already verified active session, staff may save offline drafts. Lock, restart or person switch requires an internet connection and online verification before resuming. Saved drafts survive; final stock changes require online verification. No cold offline login is accepted for this initial design. |
| D07 | “Accept the proposed timing” | Lock after five minutes without activity, on app backgrounding or when switching people. Five failed PIN attempts trigger a five-minute device cooldown. With D02, a lock during an outage blocks resumption until connected. |
| D03a | “Accept admin review” | Unknown products become requests with receiving drafts. Admin approves or links the catalog item; a separate valid receiving confirmation is required before stock becomes available. Approval alone never creates available stock. |
| D03b | “Accept these additional permissions” | Markdown and relabel also require shift-lead confirmation. Admins may confirm permitted actions for an explicitly selected branch within their organization. Neither confirmation nor admin status overrides store policy. |
| D05 | “Accept paired rounds and owned exceptions” | Two different active staff in the same branch confirm participation. Every worklist item must be accounted for and record uploads confirmed before completion. Open exceptions require a reason, accountable owner and next action and remain visible. Without a partner, preserve progress and resume later; no solo completion exception is accepted. |

## Cross-decision consequences

- Offline capture is limited to the active verified session, including the accepted backgrounding and inactivity locks. Durable storage does not provide offline permission to reopen working data. Do not relax this limitation implicitly during implementation.
- Offline round progress can be saved, but final completion waits for confirmed uploads and paired participation. Pairing and approval of individual stock actions remain distinct.
- Admin catalog approval does not supply missing dates, units, quantities, locations or required lots. Staff still reviews a valid receipt before stock is confirmed.
- Accepted lead/admin permissions do not establish food-handling eligibility, change shelf-life rules or override conservative past-date restrictions.
- These choices settle the named decision rows. They do not independently approve every detail of version 1 or authorize application changes or tests.

## Store inputs and unresolved scope

| ID | Status | Required input / boundary |
|---|---|---|
| D04 | Admin setup design accepted; actual values deferred to onboarding | Admin selects/customizes units, pack sizes, label profiles, locations, supplier/reference/lot requirements and receipt exception handling using the accepted controls below. |
| D06 | Admin setup design accepted; actual values deferred to onboarding | Admin supplies operating jurisdiction and category/handling/transformation/markdown/donation policies. Unknown policy keeps affected actions unavailable. |
| D08 | Not approved | Exact implementation slice, backend target, dependencies and application/connected/device testing. |
| D09 | Not approved | Release/publication/sharing target, access changes, rollout and rollback. |

Read-only review of PLAN.md, PLAN_ADDENDUM_2026-09-25.md and reference/AL_SAFA_MARKET_OS.md found historical field requirements and examples, not confirmed store-specific answers to D04/D06. Historical legal statements and sample shelf lives are not adopted as current policy. Past-date markdown/donation flags remain false; unknown handling policies do not become enabled by this review.

The human requested: “can we not have an admin part of this/these where customizable presets are on the admin's discretion? Just provide them options, will you? then on onboarding, prompt them their first initial set up.” This authorizes documenting an admin configuration and guided initial-setup approach within this chapter; no admin UI implementation is authorized. It replaces the need to supply every store value during this conversation. Actual store values remain unknown until configured.

Rejected decisions: none. Store-specific D04/D06 values are deferred to admin onboarding. After the concrete addendum was presented, the human selected **“Accept the design with admin onboarding”** in response to the question accepting version 1 plus this addendum, with existing past-date restrictions retained and documentation-only scope. This accepts the combined design and detailed controls below; it does not approve implementation or testing.

## Accepted admin setup and customizable presets

### Entry and setup sequence

On an admin's first sign-in, show **Set up your store** with progress and saved steps. Later visits resume unfinished setup. The same controls remain available under **Admin → Store setup & presets**. Staff see a clear setup-needed message for any blocked workflow and can ask their admin to complete it.

1. **Store and branch:** store name, real branches, operating country/state or region, and branch time zone. Ask for these values; do not infer jurisdiction from the admin's device.
2. **Units and packs:** choose starter options, edit permitted precision, and define actual pack sizes per product.
3. **Locations and receiving:** confirm real storage/receiving-hold locations, supplier requirements, lot requirements and receipt exception routing.
4. **Labels and expiry:** choose identifier entry and date modes, confirm supported label formats, and supply rules only for the categories that need calculated expiry.
5. **Allowed actions:** configure which category actions the store permits and the prerequisites they require.
6. **Review and activate:** show effective choices, missing information, workflows ready to use and workflows still unavailable. Admin explicitly confirms the setup version. Saving an unfinished setup never labels it ready.

Allow **Save and finish later** throughout. Activation can be limited to a ready workflow: for example, receiving known products with printed dates, confirmed units/locations and a completed required-field policy, while calculated-expiry or transformation actions remain unavailable. Every affected product/category must have its required configuration before its receipt can become confirmed stock. Optional capabilities can be marked **Not used** explicitly.

### Options presented to admins

| Setup area | Starter options / editable controls | Effect and missing-input behavior |
|---|---|---|
| Quantity units | Each, kg, g, lb, oz, L, mL; enable only those used; choose permitted decimal places for measured units | Each uses whole counts. Product has an explicit stock unit. Staff sees that unit; no silent rounding or conversion. |
| Pack sizes | Single item; named pack/case with admin-entered number of items; custom pack description | Pack count must be a positive whole number for each-based products. Store it as descriptive catalog information in the initial design; staff records quantity in the visible stock unit. Automatic pack/unit conversions remain outside this design. |
| Locations | Editable suggestions such as Receiving hold, Shop floor, Chiller, Freezer and Back room; add/rename/deactivate actual locations | Suggestions are not real locations until confirmed. Select an actual receiving-hold location for exceptions. Deactivation preserves prior receipt history. |
| Supplier and delivery reference | Supplier required or optional by category; invoice/delivery reference required or optional; explicit handling of missing required data | Missing required data stays a draft/exception and does not become available stock. Admin must choose; optional is not silently assumed. |
| Lot capture | Required for selected categories/products; optional where the store has explicitly confirmed that choice; label the requested lot/reference field | No guessed lot or placeholder that passes validation. Admin configuration records store policy, not a claim that legal requirements have been verified. Unknown requirements block affected receipt confirmation. |
| Product identifiers and labels | Standard product barcode, internal SKU/PLU, manual catalog selection; a named scale-label profile only after its format is supplied and supported | Offer manual product/quantity/date entry for unsupported labels. No arbitrary parser builder, automatic scale-format guessing or new OCR scope. |
| Date source | Printed package date; calculated from receipt date using an admin-supplied category/product rule | Printed date starts blank for each delivery. Calculated rules require a value, unit, applicability and store-policy reference; no supplied example is an approved shelf life. Missing rule keeps that path unavailable. |
| Action availability | Per category: markdown, relabel, donation, freeze, conversion, or not used; record prerequisites and store instructions | These actions begin unavailable until the relevant policy is configured. D01/D03 lead/admin confirmation remains mandatory. Pull-aside containment remains available under D01. |
| Transformation details | For an enabled freeze/conversion rule: eligible source category/product, destination, quantity/unit relationship, resulting date rule and required label information | Incomplete rules cannot be activated. No default safe durations, inferred yields, automatic date extensions or permission to refreeze. |
| Past-date handling | Display existing past-date markdown/donation restrictions and their status in setup | Both flags remain false in this design. Admin discretion does not create a bypass. Changing this retained boundary needs separately reviewed policy/design scope. |
| Receipt exceptions | Draft and request admin review; route physical stock to a confirmed receiving-hold location; record reason and responsible role | Missing policy or required metadata remains visible; saving a draft is not confirmation of available stock. |

Starter options are editable configuration choices, not pre-approved store facts or handling advice. The admin can save named presets and reuse them for applicable categories/products. Display the effective preset and any explicit override so staff cannot unknowingly receive against a hidden rule.

### Configuration boundaries and changes

- Admin owns setup and presets within their organization; staff and shift leads use the resulting choices. Branch-specific locations and settings cannot cross branch boundaries accidentally.
- This request makes D04/D06 store configuration customizable. It does not reopen the accepted D01/D02/D03/D05/D07 role, offline, paired-round or timing decisions as discretionary admin switches.
- Maintain draft and active configuration versions, who changed them, when and why. An admin review shows affected categories/branches and resulting availability before activation. Configuration changes are auditable.
- Changes apply prospectively. Preserve the configuration version and date basis used for confirmed receipts/actions; never recalculate historical expiry or rewrite an earlier stock action silently.
- Pending receipts/actions must revalidate against active configuration when confirmed or synced. If a rule changed, show what changed and require review; do not silently substitute new values or lose the draft. Active-session offline capture uses the last confirmed configuration and still follows D02/D07.
- Presets can be duplicated and edited; deactivation preserves referenced records. Do not delete referenced units, locations or policy history as an ordinary settings action.
- No connected catalog integration, legal verification, arbitrary rule scripting, dependency installation or onboarding implementation is included here.

### Additional proposed acceptance scenarios

These are documentation criteria for a later approved implementation, not tests run here.

| ID | Scenario | Expected behavior |
|---|---|---|
| AC29 | Admin begins setup, saves midway and returns | Progress and choices persist; incomplete configuration is clearly shown and affected workflows stay unavailable. |
| AC30 | Admin activates printed-date receiving but leaves transformation policy unfinished | Configured receiving works; freeze/conversion remains unavailable with a setup reason. |
| AC31 | Staff receives against a preset | Explicit unit, real location, date source and required supplier/lot fields apply; staff cannot change admin policies. |
| AC32 | Pending offline receipt meets a changed rule on sync | Draft survives, changes are shown and review is required; stock is not silently confirmed under a replacement rule. |
| AC33 | Admin changes or deactivates a used preset/location | Earlier records retain their original configuration and meaning; new work uses only valid active choices. |
| AC34 | Admin has not supplied a label format or handling rule | Manual supported entry remains available where valid; no inferred weight, shelf life or transformation eligibility. |

## Evidence and preservation

Fresh evidence is limited to local documentation reads, human replies and local Git inspection. Root branch is `main`, HEAD `f56d5068e94cf80819f55be952a95769ad508c97`; inherited source/prototype changes remain uncommitted. No application code, dependencies, database, application tests or deployed state were changed or validated.

The [review packet](../../../handoffs/2026-10-10/ch03-decisions-review/) holds prior-current-document copies and a historical-file hash baseline. Version 1 SHA256 before this addendum: `BA786E5B5B61B3CE62EB36011569C93F1BFAD9FBC0EF5F2549D9444DF33A5084`.

Checkpoint: design review is complete. Actual store values will be supplied during the accepted onboarding design. See the [executive summary](../../../handoffs/2026-10-10/ch03-decisions-review/EXECUTIVE_SUMMARY.md), [engineering handoff](../../../handoffs/2026-10-10/ch03-decisions-review/ENGINEERING_HANDOFF.md) and [documentation evidence](../../../handoffs/2026-10-10/ch03-decisions-review/EVIDENCE.md). Stop for explicit transition approval; no further continuation is authorized.
