# Compatibility Contract

The packaging migration preserves established database schemas, API paths and fields, event names, environment-variable aliases, service names used by stored data, container labels, filesystem upgrade paths, and bootstrap contracts.

Preferred product-facing coordinates use `PastureStack/*`, `ghcr.io/pasturestack/*`, `PLATFORM_*`, and `PASTURESTACK_*`. Historical identifiers remain only where existing databases, agents, clients, templates, or upgrade tooling consume them. They must not be mechanically removed.

The catalog helper is packaged and installed as `catalog-service` and `catalog-service-sqlite`. The historical executable path remains only as a compatibility wrapper because the preserved service supervisor and persisted settings still invoke it. Release assets must use the PastureStack filename `catalog-service-<version>.tar.xz`; compatibility aliases must never leak back into the public asset name.

The authentication helper follows the same boundary: the GitHub Release asset and actual executable use `authentication-service`, while the preserved supervisor-facing executable name exists only as a compatibility wrapper.

PastureStack keeps the platform account as the authorization principal
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

The current `v1.6.469` assembly consumes Orchestration Engine `v0.183.322`,
Web Console package `1.6.132`, Authentication Service `v0.4.42`, API Explorer
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
and generated project-member schema. Engine `v0.183.310` makes schema creation
wait for completed configuration startup, loads the reviewed list from the
packaged runtime defaults, then merges base and configured
options in stable deduplicated order. Engine `v0.183.311` also unions the
reviewed OIDC types with an older database override and exposes the same types
from its frozen `/v1` schema, so an upgraded installation cannot reject a
valid OIDC project member merely because its persisted list predates OIDC.
Unknown types remain rejected, and the
configured-provider state is restored from persisted settings after restart.
For an external token exchange that Authentication Service has already
validated, Engine `v0.183.311` treats that successful exchange as the provider
boundary and validates every returned identity against the reviewed external
type allowlist. It does not re-read the asynchronously propagated provider
flag for those same identities. Unknown and missing types remain rejected;
generic identity and project-member operations still require current provider
state.
Engine `v0.183.312` validates Authentication Service identities before access
policy evaluation, account lookup, or persistent mutation. The Engine-owned
stable `rancher_id` added after account resolution is handled on a separate
internal path and is accepted only when it resolves to the account
authenticated by that token. A provider-supplied or mismatched platform
identity cannot select another account. This completes the boundary that
`v0.183.311` began without broadening the external or project-member type
contracts.
Engine `v0.183.313` preserves that boundary and makes fresh external-account
activation synchronous. The complete `account.create` lifecycle now reaches
`active` before the token path enters MFA, while MFA continues to reject every
non-active account. Existing accounts, identity validation, session ownership,
and access-policy behavior are unchanged.
Engine `v0.183.314` closes the remaining frozen-v1 schema boundary. When the
historical `/v1 projectMember.externalIdType` options are loaded, only that
field is enriched from the reviewed current core schema. Historical provider
values remain in stable order, `oidc_user` and `oidc_group` become available to
v1 environment and membership creation, and unrelated schemas or enum fields
are not widened. Runtime validation of unknown external identity types remains
fail-closed.
Engine `v0.183.315` restores identity ownership across repeated OIDC logins on
upgraded installations. Authentication credentials are persisted for the
explicitly verified user or administrator, and internal service accounts are
not accepted by login-identity lookup. A historical link owned by the built-in
`token` account is repaired only when the provider, external identity type,
external ID, derived link digest, and target account identity all match. Links
owned by another real account remain fail-closed and require the explicit
reassignment workflow.
Engine `v0.183.316` keeps the existing local administrator recovery path usable
when the external provider is configured with required site access. The
exception is limited to a server-encrypted local-auth payload whose stable
principal is revalidated as an active administrator while platform security
and local recovery are enabled. Ordinary OIDC sessions continue through the
unchanged user or group allow-list.
Engine `v0.183.317` makes shared-project provisioning explicit and
role-preserving. In the default `shared` mode, each successful login reconciles
the stable internal account identity into the single `adminProject` Default
environment only when no direct or group membership already exists. Existing
owner, member, restricted, readonly, and noaccess decisions are never replaced;
existing personal environments remain intact. The optional `personal` and
`none` modes preserve compatible deployments without changing authorization
semantics.
Engine `v0.183.318` resolves an existing external identity link before applying
restricted-site admission. Restricted mode can therefore honor that account's
existing project membership, including the shared Default membership, without
weakening required mode: required mode continues to admit only the configured
OIDC user or group allow-list (plus the separately guarded local recovery
administrator). Inactive or unresolved accounts still fail closed.
Engine `v0.183.319` makes shared-Default reconciliation atomic. It checks all
active direct, group, and stable-identity memberships and creates a baseline
member only while holding the same project lock used by administrator member
updates. Existing owner, member, restricted, readonly, and noaccess decisions
remain authoritative under concurrent login and policy changes.
Engine `v0.183.320` checks project-member collection requests against the
requested project before loading members. A token authorized for project A
cannot use that project's `X-API-Project-Id` header to list project B's members
through `?projectId=B` on either `/v1/projectMembers` or
`/v2-beta/projectMembers`; unauthorized and malformed project IDs return 404.
Authorized collections and direct member-ID access retain their established
project checks.
Engine `v0.183.321` excludes inactive or removed project-member rows from
direct ID reads, matching active membership collections. Active direct reads
still require the caller to have access to the row's project, and an ID from
another project remains unavailable. This applies equally to `/v1` and
`/v2-beta`; a removed row is not exposed merely because its database ID still
exists.
Web Console `1.6.132` uses the effective per-project schema for workload create
and upgrade controls as well as direct routes. A missing POST or PUT method
therefore cannot be bypassed by typing the route, and a project switch forces
capability re-evaluation. Account administration reads exact per-account
`authIdentityLink` records for local and OpenID Connect identity display.
The environment editor separately follows project `update`, project
`setmembers`, and network `update` action links; a direct `?editing=true` URL
does not grant a missing action. These UI guards supplement, and do not replace,
server-side token and project authorization.
The environment editor's network-policy lookup also supplies its project ID
in `X-Api-Project-Id`; an unscoped read of a project-only network is not
treated as evidence that the selected project has no network policy.
The environment detail page offers an Edit entry for network-only capability
after its network model loads, without inferring permissions from a role name.
Direct `/env/:project_id` navigation and refresh select that permitted project
from the router's public RouteInfo before the tab or user Default fallback.
Missing, inactive, and inaccessible IDs retain the existing authorized
fallback; valid URL environments are not replaced by a saved preference.
Each readable account still receives an exact `authIdentityLink` lookup. HTTP
404 for an inactive historical account is isolated to that row and uses the
embedded identity fallback; 401, 403, 5xx, transport, and unexpected failures
continue to reject the route.
Environment view and edit use the project `projectMembers` link, so member
reads follow the same project authorization boundary. A 403 or 404 during the
project or member load is shown as a localized access or not-found message.
Server failures during environment load show a localized retry message instead
of the raw response.
Save failures identify whether the project, members, or network policy failed;
the form warns that an earlier save step may already have completed. Identity
search distinguishes a zero-result lookup from 401, 403, and server failure.
An authenticated account with no active environment is a valid empty state.
The console clears stale project scope, skips project-scoped collections until
an authorized environment exists, and does not loop on an obsolete direct
URL. Account names prefer authoritative identity links in the order name,
login, then external ID; a missing link falls back to the embedded identity.
Descriptions remain account data, and display-only identity links are never
serialized in an account update.
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
