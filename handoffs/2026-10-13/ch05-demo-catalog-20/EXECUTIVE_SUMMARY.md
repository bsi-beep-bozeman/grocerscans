# Twenty-product demo catalog checkpoint

2026-10-13 (Australia/Perth). Owner: [ShelfLife — Admin Setup Foundation](codex://threads/01a12f57-0cf7-7fa0-8e2a-542b48d3985d).

Human requested “create a demo data, about 20 UPCs, and do you already have the 4 tier access?” Completed a bounded local preview-data expansion and read-only access-status review. S1 is still unstarted.

The [CSV](../../../app_flutter/demo-data/catalog-20.csv) and local preview now contain 20 fictional products with unique, checksum-valid synthetic UPCs. Earlier barcode aliases remain usable. Catalog count, stock summary and checklist totals now derive from the expanded data: 379 units, six attention items, 60 units due within two days. No real inventory was imported.

The intended roles are Admin, Staff, Viewer and Supplier, with Shift Lead as a staff flag. Database source contains role/policy foundations; Flutter still has a signed-in stub and no supplier role routing. The preview has no authentication. Four-tier access is not complete end to end and live authorization was not tested.

Local data validation passed. Application regression, build, camera/backend tests and publication were not run. The hosted demo remains its previous five-product snapshot. Separate approval is required for a local app build/test and publication sequence. [Engineering handoff](ENGINEERING_HANDOFF.md).
