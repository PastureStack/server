# PastureStack Server

Server assembles the compatible control-platform runtime, orchestration engine, web console, node agent, authentication, proxy, catalog, and database components into a deployable source package.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.

**Upstream:** [`rancher/rancher`](https://github.com/rancher/rancher). This GitHub fork preserves upstream history, authorship, dates, tags, licenses, and copyright notices. PastureStack maintenance is consolidated into one commit after the preserved upstream boundary.

## Project status

This is a compatibility-focused modernization project. Existing Ubuntu 26.04,
Java 25, MariaDB, modern Docker, non-root runtime, artifact-integrity,
authentication, WebSocket, backup/restore, and test work is retained. Server
`v1.6.452` combines Orchestration Engine `0.183.311`, Node Agent `0.13.27`,
Authentication Service `0.4.42`, and the reviewed Ember 7.2 Web Console
`1.6.122`.

The inherited `v1.6.429` runtime repairs the embedded Host API `0.38.4`
package for fresh host registration. The original executable and installer
script are unchanged;
the archive now includes `SHA256SUMS` and `SHA256SUMSSUM` alongside its legacy
SHA-1 files. Image assembly verifies the original release digest and both
checksum chains. The published Server release includes the repaired archive
and its verification result; see [v1.6.429 release notes](docs/releases/server-1.6.429.md).
`v1.6.430` updates the pinned Catalog and its firewall-plugin templates;
see [v1.6.430 release notes](docs/releases/server-1.6.430.md). The current
release packages the same tested runtime as one rootfs layer so classic
Docker `overlay2` stores can register it. The release gate compares every
image runtime-config field before and after flattening, then starts and
restarts the flattened candidate; see [v1.6.431 release notes](docs/releases/server-1.6.431.md).
`v1.6.432` additionally pins Catalog Templates `v0.3.4` with the IPsec
host-port handoff correction. Its multi-stage build uses the digest-pinned,
single-layer `v1.6.431` runtime as a transitional base, and CI rejects a
layered source candidate above 32 layers before publishing the verified
single-layer image. This stops accumulation of the older 207-layer base while
retaining separate build stages; see [v1.6.432 release notes](docs/releases/server-1.6.432.md).
The current release gate also checks that the pushed registry manifest has one layer.
`v1.6.433` targets Catalog Templates `v0.3.5` with IPsec Overlay `v0.14.31`.
It keeps the same multi-stage packaging and verified single-layer runtime,
while a temporarily offline overlay peer is retried without stopping the
shared charon daemon. Publication and live peer-restart validation are
separate release gates; see [v1.6.433 release notes](docs/releases/server-1.6.433.md).
`v1.6.434` targets Catalog Templates `v0.3.6` and IPsec Overlay `v0.14.32`.
Although it kept encrypted traffic working, a subsequent real two-host
rolling upgrade retained two established IKE associations for one peer;
that release did not satisfy the one-SA gate. The verified one-layer runtime
and multi-stage build remain unchanged; see
[v1.6.434 release notes](docs/releases/server-1.6.434.md).
`v1.6.435` targets the follow-up IPsec Overlay `v0.14.33` through Catalog
Templates `v0.3.7`. Missing-SA recovery remains inside the IPsec module;
Network Plugin Manager still exclusively owns host NAT, forwarding marks,
and host-port rules. Publication and two-host rollout results are separate
evidence gates; see [v1.6.435 release notes](docs/releases/server-1.6.435.md).
`v1.6.436` pins Catalog Templates `v0.3.8`: the network manager `v0.8.17`
owns NAT, forwarding and host-port hooks, while the IPsec/VXLAN plugin
`v0.14.34` owns encrypted overlay, CNI and route state. The selected host
firewall backend is preserved (`nftables`, `iptables-nft` or
`iptables-legacy`), never silently switched. See
[v1.6.436 release notes](docs/releases/server-1.6.436.md).
`v1.6.437` pins Catalog Templates `v0.3.9` and IPsec Overlay `v0.14.35`.
The IPsec module retries a transient TCP port-80 handoff without changing
another plugin's firewall rules. See
[v1.6.437 release notes](docs/releases/server-1.6.437.md).
`v1.6.438` pins Catalog Templates `v0.3.10`. Network Services uses Network
Plugin Manager `v0.8.18`, and Layer 2 Flat Network uses the corrected CNI in
IPsec/VXLAN Overlay `v0.14.36`. Existing numeric template versions remain
available. See [v1.6.438 release notes](docs/releases/server-1.6.438.md).
`v1.6.439` pins Catalog Templates `v0.3.11`. Network Services version 7 uses
Network Plugin Manager `v0.8.19`, which binds managed forwarding to the exact
bridge and safely guards, preserves, and restores each bridge's
`route_localnet` setting. See
[v1.6.439 release notes](docs/releases/server-1.6.439.md).
`v1.6.440` pins Catalog Templates `v0.3.12`. Network Services version 9 uses
Network Plugin Manager `v0.8.21`; it deterministically binds CNI wrappers to
one immutable provider, repairs file and symlink drift atomically, and retains
the last working host-port rules when lifecycle data is missing or ambiguous.
Orchestration Engine `v0.183.301` restores every upgraded child service's prior
launch configuration before scheduling a Catalog stack rollback. See
[v1.6.440 release notes](docs/releases/server-1.6.440.md).

`v1.6.443` introduced same-origin, cross-tab session ownership and completed
the first OIDC site-access policy save correction. Web Console
`1.6.119` separates explicit
logout from passive authentication failures,
serializes login commit and logout through a fail-closed cross-tab mutex, and
adopts a newly committed session in every open tab without storing JWTs in Web
Storage. It also preserves structured top-level OIDC errors for the bounded MFA
retry path. Orchestration Engine `v0.183.308` binds new tokens to the committing
browser generation, normalizes both cookie keys and `Authorization: Bearer`
values before the ownership lookup, makes deletion idempotent, rejects
mismatched stale-tab revocation, serializes restricted-session replacement,
and retains the `clientSessionId` create field in both the shipped dynamic
authorization overlay and all three frozen `/v1` token schemas. Its core
schema factory also waits for configuration startup before
freezing public schemas, so `oidc_user` and `oidc_group` are present in the
integrated v1 and v2-beta project-member options instead of only in the
packaged defaults.
Authentication
Service `v0.4.38` distinguishes an OIDC identity-source change from a policy-only
update, suppresses the provider reload generation for the policy-only path,
normalizes the allowlist, and consumes an actor-, purpose-, and
request-digest-bound one-use MFA confirmation when access is broadened. See
[v1.6.443 release notes](docs/releases/server-1.6.443.md).

`v1.6.444` closes the remaining OIDC policy-save boundary defect. The proxy
now preserves the authenticated PastureStack operator credential for
`POST /v1-auth/config`; it continues to use the external identity-provider
token only for provider-backed reads such as identity enrichment. A valid,
actor-bound MFA confirmation can therefore reach the policy service instead
of being replaced before verification. Other `/v1-auth` routes retain their
existing provider-token behavior. See
[v1.6.444 release notes](docs/releases/server-1.6.444.md).

`v1.6.445` fixes the last OIDC unrestricted-policy persistence defect.
Authentication Service `v0.4.39` sends the allowlist clear as an explicit
`value: ""` platform-setting field instead of routing it through a generated
`omitempty` model that removed the field on the wire. The API and database
therefore both retain an empty allowlist after the actor-bound MFA
confirmation is consumed; source-versus-policy separation, discovery
suppression, stable errors, and the v1.6.444 proxy credential boundary remain
unchanged. See [v1.6.445 release notes](docs/releases/server-1.6.445.md).

`v1.6.446` closes the remaining initial-navigation cross-tab race with Web
Console `1.6.120`. Cookie and generation reads now occur inside the same
origin-level mutex as login commit and explicit logout. Storage and sanitized
`BroadcastChannel` notifications share one serialized reconciliation path;
an initial 401 without an Ember transition enters passive recovery directly
instead of trying to dispatch through an inactive route. Login-route refresh
revalidates and adopts the committed cookie, stale OIDC callbacks cannot
replace a newer generation, passive failures never revoke a token, and an
explicit logout remains generation-bound and coalesced to one DELETE. No JWT,
OTP, OIDC code, or session secret is stored in Web Storage. See
[v1.6.446 release notes](docs/releases/server-1.6.446.md).

`v1.6.447` fixes restart persistence for the OIDC site-access policy.
Authentication Service `0.4.40` treats legacy provider settings as a one-time
migration source only until the encrypted `auth.config` object exists. After
that boundary, the common access mode and allowlist are authoritative, so an
authentication-service process restart or complete Server container restart
cannot copy absent legacy OIDC keys over a saved restricted or unrestricted
policy. Existing installations whose restricted allowlist was already cleared
must save the intended policy once after upgrading; subsequent restarts retain
it. See [v1.6.447 release notes](docs/releases/server-1.6.447.md).

`v1.6.448` closes the remaining OIDC policy-only reload path. Platform-setting
events emitted after a successful access-policy save also reach the
Authentication Service reload handler; that handler now compares the active
and requested OIDC identity-source configuration before deciding whether to
initialize the provider. A live, unchanged OIDC provider accepts only the
policy change without repeating discovery, while startup, first enablement,
provider switches, and identity-source changes retain the full initialization
and local-recovery requirements. See
[v1.6.448 release notes](docs/releases/server-1.6.448.md).

`v1.6.449` packages Web Console `1.6.121` and closes the expired-session
loading loop. The current-token endpoint intentionally returns HTTP 200 with
provider login options when no authenticated browser session exists; the
console now requires a non-empty account, user, or user identity before it
adopts that response. An identity-free result follows the existing local 401
path: the origin-level mutex clears a still-matching Cookie and generation at
most once, routes directly to login, sends no passive token DELETE, and cannot
clear a newer login. Three-tab, TOTP, Passkey, callback, explicit-logout, 403,
and cookie-readback protections remain intact. See
[v1.6.449 release notes](docs/releases/server-1.6.449.md).

`v1.6.450` packages Web Console `1.6.122` and centralizes asynchronous
lifecycle handling instead of applying route-specific workarounds. One
RSVP-based adapter now defers Promise/callback task factories, adopts plain
values and thenables, reports synchronous throws through the original callback,
and cannot call that callback twice when the callback itself throws.
Authenticated-route lookup and settings loading use the same contract. The
environment editor now follows the supported `projectMembers` link, exposing
and fixing the real exception previously hidden by `Callback was already
called.` The shared `NewOrEdit` lifecycle is awaitable from validation through
save hooks and cleanup, and uses explicit ownership so duplicate submissions
cannot clear another operation's saving lock. See
[v1.6.450 release notes](docs/releases/server-1.6.450.md).

`v1.6.451` repairs the OpenID Connect identity contract on upgraded
installations. Authentication Service `0.4.42` reconciles the non-secret
provider contract at startup and after policy-only saves without rediscovery
or rewriting the client secret. Orchestration Engine `0.183.310` keeps the
reviewed `oidc_user` and `oidc_group` types available when an older database
override omits them, while still requiring a configured provider and rejecting
unknown identity types. Both the generated schema and frozen `/v1`
project-member schema expose the same options. See
[v1.6.451 release notes](docs/releases/server-1.6.451.md).

`v1.6.452` removes the remaining timing-sensitive OpenID Connect token
boundary check. Authentication Service already validates the provider and
returns only reviewed external identities during a successful token exchange;
Orchestration Engine `0.183.311` now consumes those identities at that exact
boundary instead of immediately consulting a separately propagated provider
flag that can still be stale. The reviewed `oidc_user` and `oidc_group`
allowlist remains mandatory, unknown or missing types still fail closed, and
generic identity plus project-member paths retain the configured-provider
check. See [v1.6.452 release notes](docs/releases/server-1.6.452.md).

Docker Engine `29.4.1` through `29.7.2` is represented as one bounded SemVer
compatibility interval, with `29.8.0` supported explicitly. Hosts on
an in-range version such as `29.6.2` are therefore reported as supported.

The current image retains the embedded API Explorer's reviewed UI maintenance,
replacing the retired Bootstrap 3.4.1 stylesheet and Glyphicons with API Explorer `1.1.18`,
Bootstrap `5.3.8` CSS, and Bootstrap Icons `1.13.1`. Bootstrap JavaScript
remains excluded; modal and dropdown behavior stays in the reviewed
first-party compatibility layer.

The same release replaces every vulnerable Go 1.26.5 executable found by the
finished-image scan with a Go 1.27.0 build: Authentication Service `0.4.42`,
Catalog Service `0.20.11`, Compose Executor `0.14.36`, Host Provisioner
`0.39.7`, Secret Delivery API `0.3.1`, Usage Telemetry Agent `0.4.1`, Webhook
Automation Service `0.10.1`, WebSocket Proxy `0.23.14`, vSphere CLI Bundle
`0.55.2`, and the in-tree Console Broker. Image assembly also
installs the current Ubuntu 26.04 package updates before the final scan. It
also removes the setuid bit from the container's mount helpers and disables
SSH X11 forwarding and GSSAPI authentication; root-only mount operations and
ordinary key-based SSH remain available.

The current Ubuntu 26.04 scan also reports seven newly disclosed Medium curl
advisories across three installed packages. Canonical still marks all seven as
needing evaluation and publishes no fixed package revision, so the release
does not claim they are fixed or unaffected. Their 21 exact occurrences are
kept in the release SBOM evidence and the expiring
`server/security/vendor-pending.json` register. One additional Medium zlib
finding is likewise vendor-pending, for a total of eight tracked findings and
22 package occurrences. Publication still fails on any
Critical or High finding, any available-but-unapplied fix, any unregistered or
changed occurrence, an expired review date, or any detected secret.

The `v1.6.358` control-plane security update restricts serialized schema
loading to an explicit class allowlist with bounded object graphs and prevents
console-session targets from carrying attacker-controlled URL authority data.

Authoritative host-port and volume preflight protects create and upgrade
operations without weakening project ownership checks. Managed-network checks
cover every eligible host in the environment, while bridge and host-network
checks remain scoped to the selected host. Stopped owners produce an explicit
warning and unknown live-inspection state is never reported as safe. The
runtime registers the complete volume-preflight schema set and rejects an
image that cannot resolve the live action schemas.

Server `v1.6.429` fixes MFA policy saving through the live `/v2-beta` API.
Administrators can update `mfaSettings/global` with `PUT`; all 37 policy and
read-only status fields are retained without enabling create or delete.
The matching Web Console opens security confirmation when required instead
of masking the API code with a generic transport error. Unexpected errors
retain localized text and bounded HTTP diagnostics. Ordinary users cannot
modify global policy; SMTP secrets are not echoed and confirmation remains
expiring and single-use. The release smoke test runs these real API flows
against a fresh disposable database before publication.

The Engine retains the frozen `v1` hardware contract introduced in `0.183.297`
for both direct containers and service `launchConfig` payloads. Both `/v1`
and `/v2-beta` clients can discover `runtime`, `shmSize`, and typed GPU
`deviceRequests` with the correct role-specific create and update permissions;
both API versions retain the shared service create, upgrade, and Docker
conversion path.

The Web Console keeps storage pagination, selected-volume removal, direct host
container routes, relationship refresh, natural sorting, column selection,
search, and live statistics synchronized. It also retains readable WCAG AA
Catalog documentation, reactive Catalog upgrade versions, localized
questions, writable OpenID Connect configuration, broker-aware terminal
recovery, single-owner project WebSocket reconnect, API Explorer `1.1.18`,
administrator-controlled MFA, and all 13 reviewed production locales. SMTP is
configured once per installation; individual accounts store only their own
verified recovery address. Passing compatibility gates does not by itself make
a deployment production-ready.

The embedded MariaDB configuration keeps the established transaction behavior
by disabling MariaDB 11.8 snapshot isolation. This avoids error 1020 during
concurrent system-stack creation while retaining the control platform's own
optimistic locking and retry logic. External MariaDB deployments must use the
same compatibility setting.

## GitHub distribution model

PastureStack is designed not to require operators to host a separate download site, container registry, or catalog server. Reviewed container images are published through the public GitHub Container Registry and operational references use semantic version tags. Digests remain release-verification evidence and are never written into Catalog, Compose, API, or web-console image fields. Versioned binary and web assets are published as flat attachments to the matching `PastureStack/server` GitHub Release. Catalog templates are read directly from the public [`PastureStack/catalog-templates`](https://github.com/PastureStack/catalog-templates) Git repository and must be verified against a full pinned commit SHA.

Catalog stack definitions, their documentation, and referenced public images must remain usable directly from GitHub and GHCR. Catalog entries pin images by semantic version tag and may not require an operator-maintained HTTP mirror, GitHub Pages site, catalog service, or private registry. GitHub Release assets are reserved for immutable Runtime payloads; the catalog itself remains a commit-pinned Git source so stack discovery and version history stay auditable.

Version coordinates are available only when the matching GitHub Release and public GHCR package both exist. Each release is held until its assets, checksums, SBOM, license records, anonymous downloads, and isolated-VM gates pass.

Server `v1.6.429` registers the complete live volume-preflight schema model and preserves the project-scoped authorization required by driver-aware volume configuration, accessible
path completion, and an authoritative `volumepreflight` check. The server
validates container and service create or upgrade requests again at save time,
including storage-driver state, host coverage, existing volume ownership, and
the `pasturestack-nfs` environment-wide `multiHostRW` contract. The Web Console
keeps at most eight naturally sorted path suggestions and combines port and
volume checks with deterministic status precedence.

The Web Console formats schema-validation field names without legacy String
prototype extensions, so a missing localized field label cannot leave a
container or service form stuck in the saving state.

Web Console `1.6.122` preserves the Server `v1.6.358` authenticated visual and
layout contract through a provenance-bound presentation layer while retaining
Ember 7.2, the Bootstrap 5.3.8 JavaScript runtime, current security fixes, MFA,
and adds permission-scoped incident filters and XLSX, CSV, and JSON export to
the audit-log builder without changing result data or column order. Its time-range editor
uses separate hour, minute, and AM/PM columns with smooth deceleration and exact
value snapping; the earlier whole-range 15-minute animation is removed.
The service resource form keeps the init checkbox in its own field instead of
overlapping the process-limit input, and create plus upgrade requests retain
the complete shared-memory, runtime, CPU, device, GPU, and advanced-option
payload rather than silently dropping hardware settings.
First-time service creation and service upgrade pass receiver-bound completion
callbacks through the shared form. While the API store merges a newly created
resource, the live service collection can briefly contain an unreadable entry;
the page-header observer and navigation-tree rebuild now ignore only those
transient entries. Completion no longer performs the unrelated service reload
introduced during diagnosis. The four
top-level container and virtual-machine entry routes retain their controller
receiver, route selection continues to use the immutable stack query input, and
a successful operation leaves the form exactly once without inviting duplicate
submission. Empty link sets no longer invoke a redundant API action. The same
stable query-input routing applies to virtual-machine, load-balancer,
external-service, and alias creation routes.
Advanced key/value inputs also show the localized value hint instead of an
untranslated key.
Authentication ownership is now explicit per browser generation. Only a
user-initiated logout can revoke the bound server token; stale 401 responses,
403 permission failures, storage notifications, timers, route errors, and
WebSocket disconnects cannot send token DELETE requests. A successful login
commits the cookie before generation metadata, and other same-origin tabs
validate and adopt that session without repeating OIDC, TOTP, or Passkey.
JWTs remain in the cookie and per-tab memory only; localStorage stores only the
non-secret generation, account ID, and commit time.
OIDC site-access updates now follow the same explicit ownership boundary.
Changing only `accessMode` or `allowedIdentities` on an already enabled,
unchanged OIDC provider does not rerun discovery or require a fresh local
recovery ceremony. Initial enablement, provider switches, and identity-source
changes still require fresh local recovery. Broadening access consumes a
single-use MFA confirmation bound to the administrator,
`oidcAccessPolicyUpdate` purpose, and canonical request digest. `unrestricted`
always stores an empty allowlist;
restricted policies accept only deduplicated `oidc_user` and `oidc_group`
principals. Stable API error codes distinguish recovery, MFA, and invalid
identity failures.
The Engine advertises `oidc_user` and `oidc_group` in the default external
identity and `projectMember.externalIdType` contracts, restores provider state
from persisted settings after restart, and rejects types outside the configured
allowlist instead of treating provider presence as an unrestricted bypass.
External-service API hydration now stores `healthState` as writable model data,
including `null`, so direct reload cannot fail on a getter-only property. The
load-balancer service selector writes through the owning `PortRule.serviceId`;
the selected backend therefore survives editing PUT, reload, and subsequent
editing instead of remaining a DOM-only value.
The shared resource-action menu closes before its selected action is
dispatched, so opening account editing or another modal cannot leave the row
menu layered above the form. The same lifecycle rule covers every resource
table which uses the global action menu.
The Host details view keeps its CPU, memory, network, and storage chart series
and colors stable between initial rendering and live updates. Dense area charts
do not create per-sample point nodes, Billboard-specific styles apply to both
initial and updated SVG content, and CPU and memory axes start from the Host's
actual capacity. The audit-log filter completes reliably when clearing or reapplying an
unchanged query, and clearing restores the same visible bounded 24-hour range
that is sent to the API. The result table's final authentication/IP heading
keeps its longer-locale wrapping protection while receiving a wider default
column; the identity column uses a compact default so the rightmost heading is
not forced to wrap in shorter locales. Result rows, column order, and other
page regions are unchanged.
The Service log page adds service-scoped time, severity, named-container,
event-scope, event-type, and description filters without changing its existing
table. Container restarts now emit an explicit `service.instance.restart`
record linked to the owning service, while the administrator audit log retains
the corresponding API action record.
The complete filter interface is translated in all 13 selectable locales;
non-English locales no longer inherit the English filter-builder copy.
The audit date calendar is rendered by the application, so month names,
weekdays, date formatting, and week starts follow the selected application
locale instead of the browser UI language. The footer language menu opens
upward, stays aligned to its trigger, and remains inside the viewport.
Server `v1.6.358` is used only as visual
authority; no application code, dependency, security fix, or feature is rolled
back. The current console also retains the classic locale observer contract
required by Ember Intl 9, so the login language selector and audit-log route
initialize reliably before and after locale bootstrap. It retains the global dropdown
destination, so environment and user selectors render their actual options,
keeps inactive full-screen overlays from intercepting controls, and prevents
the legacy positioning shim from throwing on Bootstrap 5 events.
The login card now keeps the language selector visually integrated, centers a
full-width submit button, and provides an accessible show/hide password control
without changing authenticated tables or application pages.
It also preserves each selected text operator in the query-backed audit filter
state. It retains the audit-log filter builder, existing audit table, Bootstrap runtime
boundary, and deterministic loading-overlay lifecycle and
distinct rectangular PastureStack stack-panel loading state. Only the newest
route transition may change its state; successful, rejected, aborted, and overlapping transitions
release it safely, with a 30-second watchdog as a final recovery path. The
retired grass, celestial-body, and orbit scene is rejected by the packaged
image gate. Reduced-motion mode retains a low-displacement layer pulse and
progress-colour cycle instead of leaving the overlay visually frozen.
The release also patches the transitive build dependency `nanoid` to `3.3.18`,
pins Node.js `24.20.0` and npm `12.0.2`, and fails closed when the current
npm advisory service reports a Critical or High finding.

Authentication Service `0.4.42` is installed from its checksum-verified public
release without replacing the established launch wrapper. The packaged image
requires the reviewed archive digest, extracted-binary digest, exact source
commit, static binary, and exact version output before publication.

The embedded Catalog snapshot is pinned to commit
`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates
`v0.3.12`). It retains prior immutable template revisions and adds reviewed
Network Services, IPsec Overlay, per-host subnet, L2 and VXLAN revisions with an explicit firewall backend
choice (`auto`, native nftables, iptables-nft, or iptables-legacy). The network
plugin manager owns its NAT and host-port rules; IPsec owns its XFRM and route
state. Neither is allowed to write another plugin's firewall chains merely to
make an acceptance check pass.

The Create button remains disabled during an ordinary live volume check. If a
same-tick recheck races with a click, it no longer becomes a stale client-side
error; the create or upgrade request proceeds to the authoritative server-side
volume and storage-driver validation.

## Quick start

The versioned image is public and does not require a registry login:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 ghcr.io/pasturestack/server:v1.6.452
```

Keep operational image references in semantic `vMAJOR.MINOR.PATCH` form. The matching GitHub Release records the resolved digest for verification without exposing digest-qualified strings to the platform UI. Persistent database and platform state use the image-declared Docker volumes; manage or bind those volumes explicitly before relying on the container for durable workloads.

When TLS terminates at a reverse proxy, give the internal WebSocket/API proxy
the exact public origin. This keeps API-generated absolute links on HTTPS
without trusting arbitrary forwarded headers:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.452
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      PROXY_PLATFORM_PUBLIC_ORIGIN: https://stack.example.com
    volumes:
      - pasturestack-cattle:/var/lib/cattle
      - pasturestack-mysql:/var/lib/mysql
      - pasturestack-mysqllog:/var/log/mysql

volumes:
  pasturestack-cattle:
  pasturestack-mysql:
  pasturestack-mysqllog:
```

Use only the origin (`scheme://host[:port]`), with no credentials, path,
query, or fragment. The configured authority is applied only when the request
Host matches it. Authentication and platform API responses are marked
`private, no-store`; static fingerprinted assets keep their existing cache
policy.

JVM heap, bounded GC logs, and embedded MariaDB buffer-pool, redo-log,
query-cache, and durability settings can be configured through typed Compose
environment variables without replacing image files or mounting a custom
MariaDB configuration. See the
[Server performance settings](docs/performance/README.md) for the complete
Compose example, validation rules, and the separate host-kernel boundary.
Server `v1.6.429` also keeps the embedded-database startup context explicit, so
its internal `localhost` handoff cannot be mistaken for an operator-configured
external database when `PASTURESTACK_MARIADB_*` settings are present.

Existing databases can retain old image, download, and Catalog coordinates even
when the new image contains correct defaults. Audit and migrate only the
reviewed allowlist with
[`scripts/migrate-approved-runtime-coordinates.sh`](scripts/migrate-approved-runtime-coordinates.sh)
after first restoring the latest database into an isolated environment. The
default action is read-only; apply and rollback require `--yes` and use a
checksum-protected rollback bundle. See the
[upgrade and persisted-coordinate migration guide](docs/upgrades/README.md).

The versioned Windows node-agent ZIP is an artifact candidate only. Windows host support remains unavailable until its replacement bootstrap runtime and privileged Windows VM validation have passed; artifact validation alone must not be represented as working Windows host support.

The machine-management dependency is supplied by the independently maintained `PastureStack/machine-driver-bundle` artifact. Its two licensed upstream executables, full license texts, source coordinates, deterministic archive, and provider-plugin handshake are verified before assembly. Real provider provisioning, deletion, upgrade, and rollback remain release gates.

The vSphere command-line dependency is supplied by the independently maintained `PastureStack/vsphere-cli-bundle` artifact. Server `v1.6.429` consumes the pure numeric `0.55.2` successor, built from the exact Apache-2.0 upstream commit with Go 1.27.0 and `golang.org/x/text` 0.39.0. Image assembly verifies the release archive digest, extracted `govc` digest, exact version output, source record, and complete license records. Offline command checks do not prove authenticated vSphere inventory, clone, power, delete, upgrade, rollback, or failure recovery; those remain isolated-VM release gates.

Secret encryption and rewrap operations are supplied by the `PastureStack/secret-delivery-api` GitHub fork. Release `v0.3.1` preserves the official `v0.2.2` history, carries complete Apache-2.0 and third-party license text, rejects malformed keys and path-like key names, and passes a loopback local-key API smoke test. Server installs the neutral executable and exposes the historical `secrets-api` filename only as an internal compatibility symlink; database key continuity, restart persistence, backup restore, and Vault integration remain isolated-VM release gates.

Optional aggregate usage reporting is supplied by the true fork `PastureStack/usage-telemetry-agent`. The Go 1.27.0 `v0.4.1` artifact carries its Apache-2.0, source, third-party, and privacy records; Server verifies both archive and executable digests, installs the neutral executable, and retains `telemetry` only as an internal launcher symlink. Publishing is disabled without a new explicit HTTPS target and never inherits the retired destination.

Webhook-driven service scaling, host scaling, service upgrades, and controlled forwarding are supplied by the true fork `PastureStack/webhook-automation-service`. Server installs the Go 1.27.0 `v0.10.1` artifact, verifies the deterministic archive and static executable digests, moves its license and source records into the PastureStack license tree, and retains the historical filename only as an internal compatibility link. The launcher no longer exposes the control-plane private key to this child process.

Metrics mapping uses the unchanged official Prometheus Graphite Exporter `v0.2.0` Linux AMD64 release asset. Server pins the archive, executable, source commit, license, and notice digests; installs the executable from the official archive layout; and retains its Apache-2.0 license and notice under `/usr/share/licenses/graphite-exporter`. PastureStack does not claim authorship of this external component.

Process supervision uses the unchanged official s6-overlay `v1.19.1.1` AMD64 release asset. The build pins its archive digest and source commit, validates the required init and supervision entries, and carries the upstream ISC license in the Runtime license bundle. The public filename adds only a version suffix; the archive bytes remain identical to the upstream GitHub Release asset.

Binary-only compatibility archives are accompanied by the deterministic `pasturestack-runtime-licenses-1.6.278.tar.xz` release asset. It maps every flat Runtime asset to an exact public source commit, preserves tracked license, notice, patent, privacy, and origin files, includes legal files already embedded in archives, and carries its own internal checksum list. The Server image verifies and installs this bundle under `/usr/share/licenses/pasturestack-runtime`.

Automatic CI/CD triggers remain disabled. The single current publication
entrypoint is the manually dispatched `Publish Current Server` workflow
(`.github/workflows/publish-current-server.yml`). It runs source gates, builds
the exact merged commit, compares and flattens the runtime, starts and restarts
the candidate, scans the merged root filesystem, creates the SBOM, publishes
the immutable image, and records release evidence. Publication is not a
production-readiness claim.

## Build and validation

The repository is a packaging layer. Build inputs must be pinned to reviewed source commits and verified artifacts. Run source and shell checks locally before any container build:

```sh
bash scripts/test
bash scripts/check-server-source-gates.sh
```

Full startup, database migration, node registration, web console, backup/restore, upgrade, and rollback checks require isolated VMs. See [COMPATIBILITY.md](COMPATIBILITY.md), [SECURITY.md](SECURITY.md), and [ORIGIN.md](ORIGIN.md).

## Language support

The assembled web console provides English, German, Persian, Filipino, French,
Hungarian, Japanese, Korean, Brazilian Portuguese, Russian, Ukrainian,
Simplified Chinese, and Traditional Chinese for Taiwan. The console owns its
complete message contract, regional date formatting, and right-to-left layout.

New server bootstrap messages use `PASTURESTACK_LOCALE=en-US` or `zh-TW`;
protocol fields, persisted identifiers, and third-party output are not
translated.

## License and attribution

The inherited project remains licensed under [Apache License 2.0](LICENSE), with additional attribution in [COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md). Bundled components retain their own licenses and notices. PastureStack contributors claim authorship only for their own changes.
