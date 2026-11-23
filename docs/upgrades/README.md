# Upgrade and persisted-coordinate migration

## Bundled default Catalog

Server v1.6.604 candidate includes the complete default Catalog Git source at its
pinned commit and Catalog Service v0.20.20. On startup and refresh, the service verifies
the bundle SHA-256, complete Git objects and exact pinned commit before indexing
it. This applies only when the configured source URL, branch and pinned commit
match the bundled manifest. Explicit custom sources retain their source policy
and network requirements; the service does not change a custom source or pin.

For the bundled source, an empty cache, stale index, missing required revision or
modified cache is recovered from the image's verified source. A bad bundle or
unparseable source preserves the existing index and reports a diagnostic error.
Refresh operations are serialized, and external Git commands have a deadline.
The native health check requires the pinned commit and all seven required
template revisions, including both historical and current Container Crontab
revisions. Release readiness also verifies their read-only library aliases;
a nonempty list or healthy workload alone is insufficient.

After an image upgrade, verify the effective `catalog.url` source, its Catalog
API `commit`, and both template and exact templateversion APIs for each deployed
Stack `externalId`. They must agree. Once resolved, use the existing two-phase
upgrade below. Recovering the index does not recreate healthy Stack containers
or change their saved configuration. Image registries still need to be reachable.
Read the Setting's resolved `activeValue` and `source`: a stored `value` can be
older while an environment override supplies the effective Catalog source.

Keep the previous Server image and existing volumes for rollback. Returning to a
release without bundled-source support restores that release's dependency on
remote Git access; it does not undo completed Stack upgrades. Keep their own
rollback points until their affected networking and health checks pass.

## Legacy Container Crontab migration

The v1.6.604 source candidate provides a read-only compatibility path for
`catalog://library:infra*container-crontab:3` to revision `4`. Verify that both
exact versions are readable before upgrading. The hidden compatibility template
retains the existing `container-crontab` service key, the `metrics` and
`debug` settings, and service-state checks through `--metadata-mode`; a new
installation uses `container-schedule:4` instead.

A clean installation using the new image defaults automatically selects the
matching bundled source. Updating an existing Server image does not override an
explicit Catalog source or pin. In particular, retaining the previous
`CATTLE_CATALOG_URL` environment value also retains its old `pinnedCommit` and
does not select the new compatibility revisions.

Before the Stack upgrade:

1. Read the effective `catalog.url` and the Compose/container Catalog overrides,
   including `CATTLE_CATALOG_URL` and any `RC16_CATALOG_URL`. Keep deliberate
   custom sources and pins unchanged.
2. For the built-in PastureStack source being advanced to this release, update
   only its `pinnedCommit` to the reviewed commit recorded in the v1.6.604
   release note. Preserve the source name, URL, branch, all other Catalog entries
   and unrelated environment values. Recreate the Server with the same volumes
   and retained rollback container/image.
3. Verify the effective source and Catalog API `commit` match the selected pin,
   then read both exact `library:infra*container-crontab:3` and `:4` identities.
   Continue only when both are available under the retained library namespace.

The Server does not run a worker or write the database to replace an operator's
Catalog pin. Matching the new built-in pin to the bundled manifest is an
explicit deployment configuration update.

Use the existing Stack **Upgrade**, verify the replacement scheduler and jobs,
then choose **Finish Upgrade** or **Rollback**. The compatibility strategy stops
the previous scheduler before starting its replacement. Do not create a second
canonical scheduler on the same Host during this migration: the component does
not provide cross-process leader election.

Preserve the workload's `cron.schedule`, `cron.action`, `cron.restart_timeout`,
custom labels and `TZ` values. `cron.timezone` is retained as a label; the
compatibility migration does not introduce new timezone-label behavior.
Keep the previous scheduler configuration until actual scheduled execution and
the retained settings pass. Finishing consumes the native rollback point.

## Managed load-balancer image settings

Server v1.6.604 selects Load Balancer Service v0.9.35 for new load balancers.
An explicit database or environment setting retains precedence over that image
default. Read the effective `activeValue` and `source` of both settings:

| Setting | Selected v1.6.604 component |
| --- | --- |
| `lb.instance.image` | `ghcr.io/pasturestack/load-balancer-service:v0.9.35` |
| `lb.instance.image.uuid` | `docker:ghcr.io/pasturestack/load-balancer-service:v0.9.35` |

The image and image UUID must identify the same selected component. If an
existing database setting is intentionally being advanced, explicitly update
both keys through the standard settings interface or Setting API and read back
their effective values and sources. Updating only `lb.instance.image` can leave
an older UUID active. Keep deliberate custom image selections unchanged.

This setting change controls new creation; existing load-balancer services need
their normal service upgrade, HTTP and certificate-verified HTTPS acceptance,
then **Finish Upgrade** or **Rollback**. The Server does not force database
setting changes when its image is replaced.

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

Server `v1.6.548` pins Catalog `v0.3.16`, whose Network Services revision 13
uses Network Plugin Manager `v0.8.25` and Metadata Service `v0.10.6`.
The manager reselects live, authorized CNI providers when an old driver stops
or its replacement starts; Metadata preserves the engine's opaque change token
so endpoint watchers observe new containers. Dependency removal remains with
the Server lifecycle. Managers older than v0.8.24 retain their destructive
Metadata/DNS reaper; upgrading only the Server image does not replace those
already running services.

A successful Stack API response alone does not prove a healthy migration.
Retain the rollback point and verify Metadata version changes, DNS, replacement
CNI selection and the actual cross-host network path before finishing an
upgrade. The [548 release note](../releases/server-1.6.548.md) separates verified
publication from its completed, scoped real-host acceptance. Those results do
not replace verification of an operator's own upgrade and rollback points.

## Persisted runtime coordinates

Server `v1.6.548` retains Load Balancer Service `v0.9.33` as
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
