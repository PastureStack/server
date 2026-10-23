# Upgrade and persisted-coordinate migration

## Catalog infrastructure-stack upgrades

An available update is a Catalog candidate, not an upgrade already in progress.
Manual Catalog upgrades use two phases:

1. Choose the candidate and submit **Upgrade**. Wait for the stack and its
   services to reach `upgraded` with no transition error.
2. Verify the replacement containers and the plugin's readiness/network
   behavior. **Upgraded: Finish Upgrade** means confirmation is pending;
   stopped previous containers are retained for rollback and may be included
   in the displayed container count.
3. Choose **Finish Upgrade** to commit, or **Rollback** to restore the previous
   configuration. Finishing consumes that rollback point. Wait for `active`
   and verify that the superseded container IDs have been removed.

Do not remove retained containers manually or disable the confirmation step
to make a status badge disappear. Catalog template versions and component
image versions are separate; a template-only upgrade may keep the same image.

## Persisted runtime coordinates

Server `v1.6.546` provides Load Balancer Service `v0.9.33` as
the image default and in both HA Compose templates. Database settings and
explicit operator overrides take precedence over the new image defaults.
An existing persisted `v0.9.27` pair therefore stays on `v0.9.27`; an administrator
must explicitly update both `lb.instance.image` and `lb.instance.image.uuid`
to select `v0.9.33` for newly created load balancers. Preserve custom images and
mixed settings for operator review.

Changing these defaults or settings does not replace existing Services or their
containers. Upgrade only the selected load-balancer Service, verify its new
containers, then explicitly finish or roll back the upgrade. Do not use a bulk
environment upgrade for this change: it can also replace custom load-balancer
images and finish their upgrades automatically.

The coordinate migration tool below retains its earlier reviewed targets. Its
`apply` action overwrites allowlisted settings, including custom LB coordinates;
it is not an automatic `v0.9.27` to `v0.9.33` upgrade path. Use its read-only audit
to inspect persisted configuration before choosing a migration.

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
