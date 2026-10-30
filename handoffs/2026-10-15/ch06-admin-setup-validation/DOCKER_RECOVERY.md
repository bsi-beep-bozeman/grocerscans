# Docker recovery observation — 2026-10-15

Human approved the scoped repair with “yep go ahead and repair docker. I don't know whats happening with it”. Before repair, fresh engine inspection succeeded: Desktop4.93.0, Engine29.8.1, Linux/amd64. Existing product Supabase and Onyx containers were running. Recovery occurred between turns; cause is unknown. No graceful stop, force stop, socket rename/deletion or Docker settings/credential change was performed by this chat. The repair is no longer necessary. Existing workloads remain untouched.

Resume the already-approved isolated R03/R06 sequence. The separate project's proposed ports had no listeners; its named containers/volumes/network were absent in fresh inventory. Official Docker bridge documentation supports per-network host_binding_ipv4=127.0.0.1; an isolated network can enforce the requested binding without changing daemon defaults. Verify actual bindings after startup.
