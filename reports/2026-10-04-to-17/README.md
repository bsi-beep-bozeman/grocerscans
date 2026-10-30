# ShelfLife progress report — October 4–17, 2026

Open [the original report](Oct%204-17%2026%20Shelflife%20progress%20report.html) in a browser. It is an offline HTML presentation with six tabs, 36 slides, 14 calendar-day entries and four embedded original project screenshots. Use the slide arrows or keyboard; select dates in the Daily log. Gallery images enlarge on click. Print/PDF expands the whole deck; physical PDF pagination has not been certified.

## GHL-ready evidence copy — October 26 addendum

Use [ghl-standalone.html](ghl-standalone.html) when moving the report out of this repository. All 13 primary evidence records and all four screenshots are embedded in that single file. Evidence buttons open a readable dialog inside the report, with Escape/Close and scrolling. It does not need local Markdown/JSON files or image folders. The source documents are presented as plain text, so their internal relative references are readable text, not additional hosted pages. Original Codex chat links still require authorised Codex access.

Preserve this file's complete HTML, CSS and JavaScript in the hosting method you choose. The original local-file evidence links are replaced in this edition. No GHL account/site was edited or published here. Actual GHL rendering and any code-block restrictions remain to be checked in the chosen page. The package is a source snapshot: later project records do not update it automatically. Snapshot date is October 26; report milestone counts retain the October 17 cutoff.

All 13 evidence readers matched source contents and closed with Escape; 108 slide/viewport checks found no horizontal overflow, with no browser script errors. See [GHL_VERIFICATION.json](GHL_VERIFICATION.json) and [GHL_PACKAGE.json](GHL_PACKAGE.json). Rebuild locally with `node reports/2026-10-04-to-17/package-ghl.mjs`. The original HTML had been renamed to `Oct 4-17 26 Shelflife progress report.html`; packaging preserves it.

Prepared October 19 at the user's request before any further Docker action. Source chat: **ShelfLife — Admin Setup Backend and Application Validation**, `01a13ce2-a8fe-7063-8867-260412dd096a`. No publication or Docker startup occurred as part of report creation.

## Evidence policy

The period is inclusive October 4–17 in Australia/Perth. October 9–13 and 15–16 have dated work evidence. October 14 is labeled a reconstructed interval inside the October 13–15 implementation window, not a verified exact-day allocation. October 4–8 and 17 contain explicit evidence-gap/carry-forward labels. No hours or completion events were invented. October 19 testing/recovery events are excluded from period results.

Screenshots distinguish the existing sample demo, local widget fixtures and the connected application. No generated images are presented as progress evidence. Test counts measure different scopes and are not summed.

## Files

- `index.html`: deliverable; styles, scripts and images embedded. Relative evidence links work within this repository; original chat links require Codex. If the HTML is shared alone, its slides/images still work but repository evidence links will not travel with it.
- `content.json`: structured slide content and source/image provenance.
- `build-report.mjs`: local builder. From repository root, run `node reports/2026-10-04-to-17/build-report.mjs`.
- `VERIFICATION.json`: final 108 slide/viewport checks plus navigation, image zoom, source existence and print-expansion checks.
- `report-desktop.png`, `report-mobile.png`, `report-gallery.png`: report presentation previews, not additional application milestones.
- `layout-check-initial.json`: initial responsive issues, retained; final results supersede these after layout adjustments.

No app source, migration, credential, deployment or chapter-transition state changed for this report.
