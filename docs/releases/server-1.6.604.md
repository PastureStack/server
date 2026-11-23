# Server v1.6.604 candidate

## Candidate boundary

This source candidate prepares the legacy Container Crontab Catalog migration
and a new managed load-balancer default. Server build, publication and affected
deployment workflows remain pending. The published installation target remains
v1.6.603 until the release workflow produces the new immutable image.

## Verified component inputs

Engine v0.183.395, Web Console 1.6.239, Compose Executor 0.14.46 and the
new-registration Agent v1.2.36 retain their existing component identities.

Catalog Service [v0.20.20](https://github.com/PastureStack/catalog-service/releases/tag/v0.20.20)
is published from `bced4b96b0c6a0fe7d3db044f5c30a5b33d01172` by
[release run 45133228172](https://github.com/PastureStack/catalog-service/actions/runs/45133228172).
Its archive SHA-256 is
`6bce527300205aeb0d589b67f4b38e037be3bdb8e6da5ea04f7357d287eedf6d`;
the Catalog binary SHA-256 is
`acf89922925f62ce2ae9333636568f50c7fa6a2dee8b843e68dd8be43d8342b4`;
the SQLite helper SHA-256 is
`c7e6c53d2382d7955edaf8b77869d6df3aa9e7cab2b7bf7646080791b3169e16`.
The license SHA-256 remains
`0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594`.

The complete default Catalog source is pinned to
`8c1c28318580d5ec18c14a13b224ce0e02e40bf8`. Its self-contained Git bundle
SHA-256 is `d9a678ef2c1dfd08a599b799cad57ac77cfc9b0f65a158ff1162702b571dccf5`.
The manifest requires seven exact template revisions. Publication readiness
reads eighteen canonical and legacy template/templateversion identities during
both first startup and restart; the smoke summary reports the counts read from
those native readiness receipts.

Load Balancer Service [v0.9.35](https://github.com/PastureStack/load-balancer-controller/releases/tag/v0.9.35)
is published from `9ea5bbf51cb54275331d37b1e241d78875a19ab8` by
[release run 45130590088](https://github.com/PastureStack/load-balancer-controller/actions/runs/45130590088).
The linux/amd64 image is
`ghcr.io/pasturestack/load-balancer-service:v0.9.35@sha256:9211b842f13e609950f495cac1717383fcbf647c471972f7a1836c13ee4c936b`.
It provides HAProxy 3.4.8 with AWS-LC 5.14.0 and Lua 5.4.8.

## Legacy Container Crontab migration

The complete bundled Catalog includes both historical
`container-crontab:3` and compatibility `container-crontab:4`, alongside the
canonical `container-schedule:4` template for new installations. The historical
revision retains the original compose bytes. Exact reads of
`library:infra*container-crontab:3` and `:4` preserve the library namespace;
the alias does not enable writes to that Catalog.

The image updates default coordinates, not an explicitly configured operator
pin. A clean installation loads these revisions from the matching new bundled
default. An existing Compose or container environment that retains
`CATTLE_CATALOG_URL` with the v1.6.603 pin must explicitly select this release's
reviewed Catalog pin before the new compatibility revision becomes available.
Change only that source entry's `pinnedCommit`, preserving its name, URL,
branch, all other sources and unrelated environment values. A deliberate custom
source or pin retains its existing policy and is never silently migrated.
Read back the effective `catalog.url`, indexed commit and exact revision APIs
before submitting a Stack upgrade. No startup worker or direct database pin
rewrite is part of this release.

An existing Stack upgrades in place through the normal Stack **Upgrade** action.
The compatibility revision retains the `container-crontab` service key and the
`metrics` and `debug` settings. The maintained `--metadata-mode` preserves the
legacy service-state checks. Its stop-first strategy stops the previous
scheduler before activating its replacement. Keep the replacement unconfirmed
until its scheduled jobs and retained configuration pass acceptance, then use
**Finish Upgrade** or **Rollback**. Creating another canonical scheduler on the
same Host is not the migration procedure.

Workload `cron.schedule`, `cron.action`, `cron.restart_timeout`, custom labels
and `TZ` settings retain their configured values. `cron.timezone` is preserved
as a label; this release does not introduce new timezone-label semantics or
cross-process leader election.

## Managed load balancer

New load-balancer creation and the packaged HA compose use v0.9.35 as the
component default. Existing load balancers retain their image until their own
normal service upgrade. Acceptance must check the actual HAProxy version,
HTTP routing and certificate-verified HTTPS before finishing, and check the
retained previous configuration through rollback.

Explicit settings retain precedence over the new image default. Inspect the
resolved `activeValue` and `source` for both `lb.instance.image` and
`lb.instance.image.uuid`; they must select the same component, with the UUID
using its `docker:` prefix. When advancing an existing database override, use
the standard settings interface or Setting API to update both keys and read
them back. The image replacement does not force a database rewrite. Similarly,
a stored Catalog `value` is not its effective source when an environment
override supplies the resolved `activeValue`.

## Validation and rollback boundary

The release must pass the existing source, artifact identity, security,
fresh-volume startup and restart gates. Exact Catalog readiness includes the
historical and current compatibility revisions and their legacy aliases.
Component publication does not establish Server deployment or workload
lifecycle acceptance.

Keep the previous Server container/image and all persistent volumes. Server
rollback does not reverse completed Stack upgrades; retain each Stack or
service rollback point until its affected behavior has passed. The old-runtime
QA substitution used to isolate metadata migration must be identified in any
acceptance report, rather than reported as an unchanged historical binary.
