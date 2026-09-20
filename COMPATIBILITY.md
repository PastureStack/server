# Compatibility Contract

The packaging migration preserves established database schemas, API paths and fields, event names, environment-variable aliases, service names used by stored data, container labels, filesystem upgrade paths, and bootstrap contracts.

Preferred product-facing coordinates use `PastureStack/*`, `ghcr.io/pasturestack/*`, `PLATFORM_*`, and `PASTURESTACK_*`. Historical identifiers remain only where existing databases, agents, clients, templates, or upgrade tooling consume them. They must not be mechanically removed.

The catalog helper is packaged and installed as `catalog-service` and `catalog-service-sqlite`. The historical executable path remains only as a compatibility wrapper because the preserved service supervisor and persisted settings still invoke it. Release assets must use the PastureStack filename `catalog-service-<version>.tar.xz`; compatibility aliases must never leak back into the public asset name.

The authentication helper follows the same boundary: the GitHub Release asset and actual executable use `authentication-service`, while the preserved supervisor-facing executable name exists only as a compatibility wrapper.

Server `v1.6.428` keeps the platform account as the authorization principal
and treats local credentials and external identities as explicit login links.
Provider changes therefore preserve the account identifier, direct project
memberships, and administrator role. OpenID Connect links use exact issuer and
subject values; username and email are never compatibility matching keys.
Explicit reassignment may copy direct memberships and administrator status,
but never copies passwords, API keys, sessions, MFA factors, recovery codes,
or audit history.

Machine management uses the neutral `machine-driver-bundle` asset, and vSphere operations use the neutral `vsphere-cli-bundle` asset. The externally defined executable names inside those archives are compatibility interfaces, not PastureStack branding. Artifact, license, and command-surface checks must pass before assembly; real provider and authenticated vSphere lifecycles still require isolated integration tests.

Secret payload operations use the neutral `secret-delivery-api` asset. The preserved engine still invokes the historical `secrets-api` executable and `/v1-secrets` routes, so Server supplies that filename only as an internal symlink while keeping the public artifact, primary executable, source repository, and license destination under the PastureStack name. Existing database key names and encrypted payload formats remain compatibility data and must survive upgrade and rollback testing.

The established `telemetry.opt`, `service.package.telemetry.url`, and `/v1-telemetry` identifiers remain internal compatibility data. Server installs `usage-telemetry-agent`, retains `/usr/bin/telemetry` only as an internal symlink, and packages the agent privacy notice beside its license and source record. A legacy target variable never enables publishing.

The `webhook.service.*`, `service.package.webhook.service.url`, `/v1-webhooks`, and four established driver identifiers also remain internal compatibility data. Server installs the neutral `webhook-automation-service` executable and retains `/usr/bin/webhook-service` only as an internal rollback link. The public asset and license destination use the neutral name, and the child process receives only the RSA public verification key.

The current `v1.6.450` assembly consumes Orchestration Engine `v0.183.309`,
Web Console package `1.6.122`, Authentication Service `v0.4.41`, API Explorer
`v1.1.18`, Compose Executor `v0.14.36`, Node Agent `v0.13.27`, Load Balancer Service `v0.9.27`, Catalog
Service `v0.20.11`, WebSocket Proxy `v0.23.14`, vSphere CLI Bundle `v0.55.2`, distributed cache runtime
`v5.7.4`, and Catalog Templates at commit
`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates `v0.3.12`). A Catalog upgrade changes
`pinned_commit` first and leaves the last indexed `commit` untouched until
Catalog Service has rebuilt the template index; pre-advancing both values can
preserve a stale nonempty index. Operational container references must use
numeric semantic version tags; image digests are retained only in
release-verification evidence. Web Console packaging must retain its
fingerprinted `/assets/ui*.js` entry, and API Explorer must retain
`/api-ui/ui.min.js` and `/api-ui/ui.min.css`.

The frozen `/v1` authorization snapshots expose `runtime`, `shmSize`, and
typed `deviceRequests` on both direct containers and service `launchConfig`
payloads, matching `/v2-beta`. Role-specific create and update permissions
remain authoritative; neither API version bypasses the shared service create
and upgrade validation or Docker conversion path.

OIDC configuration retains a strict source-versus-policy boundary. An already
enabled provider can change only its site access policy without repeating
discovery or local-recovery initialization. The same comparison is applied to
the platform-setting reload event emitted after the save, so the event cannot
reinitialize an unchanged live provider. Startup, a first enablement, provider
switch, or identity-source change still requires fresh local recovery.
Broadening access requires the existing one-use MFA confirmation bound to the
operator, `oidcAccessPolicyUpdate` purpose, and canonical request digest.
`unrestricted` is represented with an empty allowlist in both the API and
database. Its setting update carries an explicit `value: ""` field; generated
client omission rules cannot turn the clear into a no-op. Restricted
allowlists contain only deduplicated `oidc_user` and
`oidc_group` principals, while stable error codes preserve the client contract.
The same two identity types are present in the default external-identity list
and generated project-member schema. Engine `v0.183.309` makes schema creation
wait for completed configuration startup, loads the reviewed list from the
packaged runtime defaults, then merges base and configured
options in stable deduplicated order. Unknown types remain rejected, and the
configured-provider state is restored from persisted settings after restart.
Legacy provider settings are imported only while the encrypted `auth.config`
object does not exist. After that one-time migration boundary, the common
access-mode and allowlist settings are authoritative; service and Server
container restarts cannot replay absent legacy OIDC keys over a saved
restricted or unrestricted policy.
The `/v1-auth` proxy preserves the caller's PastureStack authorization for an
exact `POST /v1-auth/config`, so the actor-bound policy confirmation reaches
the Authentication Service. Provider-backed reads continue to receive the
external identity-provider token; unrelated proxy routes are unchanged.
New browser tokens keep the create-only `clientSessionId` field through the
dynamic authorization overlay and the frozen `base`, `superadmin`, and `token`
v1 schemas. Explicit logout normalizes a cookie's bare key and a
standard `Authorization: Bearer` value to the same database key; mismatched
generations and unsupported authorization schemes cannot revoke the token.
Cookie and session-generation reads, login commit, and explicit logout share
one origin-level mutex. A tab captures its generation when starting requests,
timers, and subscriptions; stale passive failures stop their own work and
adopt the newer committed session without clearing shared state. Storage and
sanitized BroadcastChannel events carry no token material and converge through
one serialized reconciliation path. An explicit logout is the only browser
path allowed to revoke the bound token.
The current-token collection is authenticated only when its first entry has a
non-empty `accountId`, `user`, or `userIdentity`; an HTTP 200 provider
login-options object with no identity is an unauthenticated response. The
console normalizes it to its local 401 contract, clears only an unchanged
Cookie and generation under the authentication mutex, and routes to login
without a passive DELETE or reload loop.
Promise/callback interoperability uses one RSVP-based adapter for
`PromiseToCb`, authenticated-route lookup, and settings loading. Task factories
start in a deferred RSVP turn, so synchronous throws, thenables, plain values,
and Promises share one settlement contract; callback exceptions cannot enter a
second error callback. The 27 `NewOrEdit` consumers share one awaitable,
owner-bound save lifecycle covering validation, persistence, success hooks,
error hooks, completion callbacks, and cleanup. A pre-existing `saving=true`
lock is never claimed or cleared by a duplicate submission. Environment member
loading uses the supported `followLink('projectMembers')` store boundary.

External-service `healthState` remains writable API data, including `null`.
Load-balancer editing persists the chosen target through
`PortRule.serviceId`; this changes no load-balancer runtime or API shape.

Deployments that terminate TLS before the Server container may set
`PROXY_PLATFORM_PUBLIC_ORIGIN` to one exact public HTTP(S) origin. The proxy
uses that origin only for requests whose Host matches the configured authority;
unrelated hosts retain transport-derived forwarding values. Credentials,
paths, queries, and fragments are rejected. Platform API responses are always
rewritten to `Cache-Control: private, no-store`, while static assets preserve
their existing cache policy.

Native MariaDB validation must override both `CATTLE_DB_CATTLE_MYSQL_URL` and `CATTLE_DB_LIQUIBASE_MYSQL_URL`; the application and migration pools are configured independently. The default compatibility path intentionally uses a MySQL JDBC scheme with the MariaDB driver compatibility options.

The embedded database explicitly sets `innodb_snapshot_isolation=OFF`. MariaDB
11.8 enables snapshot isolation by default, but the preserved control-platform
transaction layer predates that behavior and already performs its own
optimistic locking and retries. Leaving the new database default enabled can
surface error 1020 during concurrent system-stack creation. External MariaDB
deployments must apply the same compatibility setting before the Server starts.

Image defaults do not override rows already persisted in the `setting` and
`catalog` tables. Existing installations must audit and migrate the narrow
distribution-coordinate allowlist with
`scripts/migrate-approved-runtime-coordinates.sh` against an isolated restore
before cutover. The tool preserves compatibility setting names, creates an
exact rollback bundle, and changes only approved GitHub, GHCR, CLI, Agent,
load-balancer, and Catalog coordinates.

Before a future release, validate fresh install, preserved-database upgrade,
both database modes, web console and API, CLI, node registration,
authentication, subscriptions, catalog, networking, storage, backup/restore,
rollback, artifact hashes, and non-root execution in isolated VMs.
