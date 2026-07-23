# Upgrade and persisted-coordinate migration

A new container image does not automatically replace values already stored in
an existing control-plane database. Older installations can therefore continue
to request a private registry, a temporary HTTP server, or an obsolete Catalog
even when the new image contains correct defaults.

`scripts/migrate-approved-runtime-coordinates.sh` handles only this narrow,
reviewed allowlist:

- node registration and load-balancer images;
- node-agent and host-API downloads;
- the six user CLI and Compose downloads;
- the commit-pinned PastureStack Catalog; and
- four non-coordinate settings only when they contain a clearly invalid image
  reference.

The default action is a read-only audit. It does not print previous values,
database passwords, credentials, registration commands, or API secrets:

```sh
scripts/migrate-approved-runtime-coordinates.sh audit \
  --container pasturestack-server
```

Public verification fetches the approved Catalog by its full content-addressed
commit. It does not require the Catalog `main` branch to remain frozen after a
Server release.

Run the audit and apply action against an isolated restore of the latest
database first. `apply` requires an explicit confirmation flag and creates a
mode-0600 rollback bundle before opening its database transaction:

```sh
scripts/migrate-approved-runtime-coordinates.sh apply \
  --container pasturestack-server \
  --backup-root /secure/operator-owned/path \
  --restart \
  --yes
```

The output reports the exact rollback-bundle directory. Keep it with the
database and `/var/lib/cattle` backup made immediately before the upgrade.
Rollback restores only the snapshotted allowlisted rows:

```sh
scripts/migrate-approved-runtime-coordinates.sh rollback \
  --container pasturestack-server \
  --backup-dir /secure/operator-owned/path/runtime-coordinate-YYYYMMDDTHHMMSSZ \
  --restart \
  --yes
```

The migration is not a substitute for a complete backup, an isolated restore,
authenticated API and RBAC checks, host-agent checks, system-stack lifecycle
checks, or a tested full rollback. Do not run it directly against the only
copy of a production database.
