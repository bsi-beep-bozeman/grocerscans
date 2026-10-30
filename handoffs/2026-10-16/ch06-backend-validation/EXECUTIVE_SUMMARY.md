# Chapter 06 — interim backend validation checkpoint

Date: 2026-10-16 Australia/Perth. Owner: **[ShelfLife — Admin Setup Backend and Application Validation](codex://threads/01a13ce2-a8fe-7063-8867-260412dd096a)**, ID `01a13ce2-a8fe-7063-8867-260412dd096a`.

The Admin Setup SQL compiled and passed its transaction suite against a real disposable Supabase backend. Nineteen concurrency acceptance groups passed; 23 API groups passed using real Auth sign-ins. The actual Dart models parsed 61 captured responses. A restart preserved setup tables, inventory fingerprints and authenticated API state. No application implementation or migration source correction was necessary.

The final backup/restore check is incomplete. Our restore harness used Supabase's limited `postgres` account, which cannot restore a schema owned by `supabase_admin`. Both private backups are intact. The disposable database is currently partially restored and all five validation containers are stopped. Existing PostgreSQL, the separate product Supabase project and Onyx resources were not deliberately modified or stopped by validation commands.

The corrected restore harness now uses the existing built-in `supabase_admin` account; read-only inspection confirmed that account can log in locally and is a superuser. No grants, roles or credentials were changed. It has **not** been retried: the approved packet explicitly makes a failed restore a stop condition. [Restore retry request](RESTORE_RETRY_REQUEST.md).

Docker recovered between turns without the proposed socket repair. A later fresh launch also worked. The initial validation startup unexpectedly published wildcard ports despite its network's localhost default; the five validation containers were stopped immediately when observed and recreated with explicit localhost bindings. All acceptance tests ran after those bindings were verified. The initial exposure interval is a recorded limitation, not described as loopback-only operation. No real data was seeded.

Browser/device validation remains unapproved and unexecuted. [R05 Chrome request](R05_BROWSER_REQUEST.md) is ready for review. No hosted deployment, publication, commit, push, merge or rollout occurred. Chapter 06 remains the owning chat; no continuation has been created and the eventual transition authority is unconsumed.

[Engineering handoff](ENGINEERING_HANDOFF.md) · [Evidence](EVIDENCE.md) · [Implementation plan](../../../IMPLEMENTATION_PLAN.md) · [Status ledger](../../../STATUS_LEDGER.md).
