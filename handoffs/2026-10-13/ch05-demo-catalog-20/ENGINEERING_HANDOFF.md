# Twenty-product demo catalog engineering handoff

2026-10-13 (Australia/Perth). Source/owner: [ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d). Original input/output evidence remains in that chat.

## Authority and implementation position

Human asked to create about 20 demo UPCs and asked whether four-tier access exists. The bounded work is local demo catalog authoring, directly related summary/count adjustments, data validation and a read-only source assessment of access. This is not S1 start approval, a permission change, database import or release approval. No new chat/transition authorized.

## Changes and rationale

- app_flutter/lib/preview/catalog.dart: 20 synthetic checksum-valid primary UPC-A values represented by zero-prefixed EAN-13; preserved five historical identifiers as lookup aliases. Four legacy identifiers fail checksum calculation, so they remain compatibility-only. Preserved existing five SKUs, generalized the branded health sample to Pain relief tablets, added 15 products and derived stock/count getters.
- app_flutter/lib/preview/cockpit.dart: replaced stale fixed catalog/attention/round/stock numbers with catalog-derived values; neutral attention guidance covers the broader sample. No role or authentication changes.
- app_flutter/demo-data/catalog-20.csv, README.md and validate_catalog.dart: downloadable matching data, fictional-data/import notes, reproducible validation. No new dependencies.
- app_flutter/PREVIEW.md: distinguishes twenty-product local source from unchanged hosted five-product snapshot.
- Current plan, status, index and stable pointer updated; earlier completed handoffs preserved.

All quantities, pack descriptions and remaining-day values are synthetic scenarios, not policy or manufacturer assignments. Original legacy lookups are retained to avoid breaking prior walkthroughs.

## Verification and limits

Existing installed Dart SDK parsed/formatted the two preview files and validator. The Flutter-provided dart launcher produced no output and was interrupted; invoking the existing cached Dart executable succeeded without installation.

Data validator PASS: 20 distinct UPCs/SKUs, check digits and EAN format, CSV/source field parity for every row, UPC-A/EAN/SKU lookup, all ten legacy UPC/EAN forms, unknown-code rejection, totals 379 overall / 319 fresh / 46 due in 1–2 days / 14 due today, six attention items. Exact command output is in the source chat.

No application widget/regression suite, web release build, physical camera, hosted backend, applied RLS or live identity tests. Formatting/data checks do not establish rendered application behavior. The previously hosted preview was not modified or republished.

## Four-role findings

Accepted design names admin/staff/viewer/supplier; is_shift_lead is an extra staff permission. Initial SQL has admin/manager/staff/viewer; supplier is added by a later migration, and manager remains a historical policy detail. Source includes RLS and supplier-tier definitions, which do not establish applied production protection. main.dart routes signed-in users to _SignedInStub; supa.dart resolves kiosk/staff profiles but not supplier memberships. The separate preview has no login. End-to-end four-tier access is therefore incomplete; security enforcement needs future scoped implementation and verification.

## Repository and recovery

Latest root branch/HEAD observation in this same chapter: main at f56d5068e94cf80819f55be952a95769ad508c97. No branch, stage, commit, push, merge or nested hosting change performed. Inherited tracked changes in plans/resume, manifest/pubspec and preview widget tests remain; prior untracked preview/docs/site material remains. Existing global-ignore permission warning was not repaired.

No production rollback needed. Do not reset/clean inherited work. If reversal is requested, remove only the 15 additions and this change's primary-code/alias/derived-summary edits while preserving earlier preview work; retain dated audit records and correct summaries additively. Hosted demo remains the earlier release.

## Next steps and pending approvals

Deliver the CSV and access-status answer; stop at this checkpoint. To show the expanded catalog on the hosted demo, obtain scoped approval for existing-dependency local preview checks/build and publication to the existing ShelfLife cockpit site, retaining its access settings. Do not infer that approval from creating local data. S1 boundaries/contracts/precision/input limits and R01/R02 still require explicit approval; backend/device/installation/access/rollout remain separate. No real store setup facts are needed for this fictional dataset.
