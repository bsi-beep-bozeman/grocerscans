-- ShelfLife — Supplier tier, part 1: extend the app_role enum.
--
-- ALTER TYPE ... ADD VALUE cannot execute in the same transaction as the code
-- that references the new value, so the enum extension is its own migration.
-- The rest of the supplier-tier work lives in 20260925000001_supplier_tier.sql.
--
-- Per PLAN_ADDENDUM_2026-09-25.md §1 (design locked 2026-09-25).

alter type app_role add value if not exists 'supplier';
