# Server v1.6.483

This release packages Web Console `1.6.148` with unchanged Orchestration Engine
`v0.183.326` and the other component coordinates from Server `v1.6.482`.
The Server API, database schema, authentication service, and host-agent
contracts do not change.

Secret Edit follows the effective Secret schema. Existing names are read-only;
the form explains why, retains Secret Add's name and value inputs, and submits
only `description` in an edit PUT. A cleared description is sent as an explicit
empty string rather than silently omitted. A rejected save leaves the entered
value and diagnostic error visible in the modal. The 13 shipped locales include
the read-only name explanation.

The [Web Console 1.6.148 source](https://github.com/PastureStack/web-console/commit/755fc0b04a0eaa83663331463ee286b4f104b63c)
is the merged commit `755fc0b04a0eaa83663331463ee286b4f104b63c`.
Its immutable `web-console-1.6.148.tar.gz` input has SHA-256
`34e9d327a115cd6833b35bc379534e9695e37d914bf7e8ab8de52a0a405901bd`
and declares `VERSION.txt=1.6.148`. The unchanged Engine input is commit
`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, with `cattle.jar` SHA-256
`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.

The Web Console merged-source validation passed in
[run 36364892172](https://github.com/PastureStack/web-console/actions/runs/36364892172).
The release source gate also checks all locale keys, component hashes, numeric
version identity, and the inherited Server runtime contracts. The source-gate
documentation markers now use stable release identity and contracts rather
than mutable candidate/publication wording, so post-publication README edits
do not invalidate the same source build.

The isolated `8080` Secret Edit browser write flow and six-role permission
matrix are separate acceptance gates. Until their evidence is attached below,
this source change does not claim browser acceptance or production readiness.
No production deployment is part of this release task.

Upgrading from `v1.6.482` changes the Web Console package only. Preserve the
existing Compose environment variables, named volumes, restart policy,
AppArmor, HTTPS public origin, OIDC settings, and nftables architecture.
There is no database migration. If the isolated validation fails, stop the
new QA container and restart the retained `v1.6.482` container with the same
volumes; do not restore or delete volumes merely to roll back the UI.
