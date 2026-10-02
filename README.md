# PastureStack Server

Server assembles the control platform, orchestration engine, web console, node
agent, authentication service, proxy, catalog, and database into a deployable
image. PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

**Upstream:** [`rancher/rancher`](https://github.com/rancher/rancher). This fork
preserves upstream history, authorship, dates, tags, licenses, and copyright
notices. PastureStack maintenance is consolidated after the preserved upstream
boundary.

## v1.6.500

This patch packages Engine `v0.183.331` to correct imported-container name
synchronization for normal stopped/inactive mappings. Only the name-only
full-row CAS lifecycle predicate changes; authentication, permissions, schemas,
managed-service names and Web Console `1.6.164` remain unchanged.
No migration or runtime patch is required. The immutable image is
`ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5`,
from Server source `abdee460eb67c8cd02a2db8e9a55b15f58020d83`.
[Publication run `36973764295`](https://github.com/PastureStack/server/actions/runs/36973764295)
passed exact build/flatten, isolated first start/restart `HTTP 200` / `pong`
(13 and seven attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks with
untrusted certificates rejected. Public readback verified 22 checksummed files
plus their manifest and the one-layer image/component identity. The unchanged
merged-rootfs gate retains 52 raw findings and eight exact Medium vendor-pending
package findings (four unique CVEs), with zero untracked, Critical/High,
fixed-available or secret findings. This is not a zero-CVE claim.
The exact Engine331 WAR is 87,700,088 bytes, SHA-256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`,
from source `515a5d37a1194f827bc3ffde34db729905ecb2b1`; its 268 suites /
1,144 tests passed with zero failures, errors or skips.
QA500 first start/restart returned `HTTP 200` / `pong` (nine and 10 attempts),
with zero runtime-contract or tracked five-table count differences. Original
environment overrides, three named volumes, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved; Docker health is `null`, not
Docker `healthy`. Server499 is retained and stopped for rollback.
Native Host1 initial/reload checks found five unique full Docker IDs, names and
links, with no removed mappings, resource writes or browser/console errors.
WebSocket received a forwarded server message. Visual review still found four
rollback names truncated to indistinguishable prefixes; visual acceptance is
HOLD pending a scoped Web Console layout correction, not a complete fix.
Historical 499 name failure and browser HOLD remain recorded, not promoted;
the full resource/role matrix remains INCOMPLETE. No company-site, all-page or
all-locale acceptance is claimed. See [the release notes](docs/releases/server-1.6.500.md).

## v1.6.499

This release packages Engine `v0.183.330` from source
`3f7320a8063a5471618be5b8be6a168f49559847` to synchronize eligible standalone
imported-container names with fresh, full-ID Docker inspection. Managed-service
logical names and unrelated instance fields are not changed. Web Console
`1.6.164`, existing role/schema protections, authentication, deployment settings
and security thresholds remain unchanged.

The exact CI WAR SHA-256 is
`c01cbbfd63625fc09f39c5494775919aad6db22c92050b217b28b940b57e1de3`.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.499@sha256:8552137dd4e40bf20dee5524cabf09540ed7431328e584ca1e488065e6fec394`,
from Server source `0a656e617c51059b92fb37a9b0571f142e8463aa`.
[Publication run `36969193015`](https://github.com/PastureStack/server/actions/runs/36969193015)
passed the exact build/flatten, isolated first start/restart `HTTP 200` / `pong`
(12 and eight attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks with
untrusted certificates rejected. Independent public readback verified 22
checksummed files plus their manifest, the one-layer image, version/source/digest
labels and SBOM identity. The unchanged merged-rootfs security gate reports 52
raw findings and eight exact Medium vendor-pending package findings (four unique
CVEs), with zero untracked, Critical/High, fixed-available or secret findings.
This is not a zero-CVE claim.
Engine330's signed numeric release and six exact CI assets have been verified;
the exact WAR passed isolated H2 startup without platform data or network access.
QA499 first start/restart returned `HTTP 200` / `pong` (nine attempts each),
with zero runtime-contract or tracked five-table count differences. Original
environment overrides, three named volumes, AppArmor and restart policy were
preserved; Docker health is `null`, not a Docker `healthy` result.
Targeted name acceptance did not pass: Engine330 incorrectly requires an active
mapping for stopped imported containers, whose normal mapping state is inactive.
The retained rollback containers consequently still show their original name;
they were not deleted or manually renamed. The browser HOLD is retained, and
the lifecycle correction requires a new immutable release. These results do
not establish the full
resource/role matrix, all-page/all-locale or company-site acceptance. Historical
HOLDs remain HOLD. See [the release notes](docs/releases/server-1.6.499.md); the
498 evidence below remains historical to that release and is not promoted to
499 proof.

## v1.6.498

This release packages Engine `v0.183.329` to protect GenericObject capability
fields from readonly/restricted roles in v1 and v2-beta. Owner/member/service
storage and the typed Receiver API remain intact. Web Console `1.6.164`,
Webhook Automation Service `0.10.3`, OIDC/MFA/session ownership and deployment
settings are unchanged. The exact Engine WAR passed its normal CI build's
266 suites / 1,123 tests with zero failures, errors or skips. See the
[release notes](docs/releases/server-1.6.498.md) for exact component pins.

The immutable image is
`ghcr.io/pasturestack/server:v1.6.498@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7`,
from Server source `ea58d92167eef31b76c7616f41df4d515530c359`.
[Publication run `36954622994`](https://github.com/PastureStack/server/actions/runs/36954622994)
passed the exact build, flattening, isolated first start/restart `HTTP 200` /
`pong` (10 and six attempts), 34 MFA policy/API checks, and TLS 1.2/1.3 checks
with untrusted certificates rejected. Independent public readback verified
22 checksummed files plus their manifest, the one-layer image,
version/source/digest labels and SBOM identity. The unchanged merged-rootfs
security gate reports 52 raw findings and eight exact Medium vendor-pending
package findings (four unique CVEs) after VEX, with zero untracked,
Critical/High, fixed-available or secret findings. This is not a zero-CVE claim.

The recorded QA498 `8080` upgrade ran this immutable 498 image / Web Console `1.6.164`.
First start/restart returned `HTTP 200` / `pong` (11 and 10 attempts), with zero
runtime-contract and tracked five-table DB-count differences. The original
three named volumes, environment overrides, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved. Docker health is `null`, not a
Docker `healthy` result; count preservation is not a whole-database comparison.
The previous `v1.6.497` rollback container is retained and stopped. Limited
Receiver role/API/header/message gates passed in scoped QA: member retains
privileged reads; restricted/readonly typed reads preserve safe configuration
and hide URLs, while GenericObject exact/list reads omit key/resourceData in
both API versions. No-access exact API requests return 403. Member Add is
visible; restricted/readonly Add is hidden, and direct-create denial and
no-access unavailable messages were checked in Traditional Chinese. Normal
owner fixture creation/deletion and cleanup were verified. This does not
establish all-resource, full-page or all-locale acceptance; Secret and other
resources remain unaccepted for 498. Publisher smoke and QA startup alone do
not establish backend-write authorization or company-site deployment. Historical
HOLD receipts remain HOLD, and the broader resource/role matrix remains
INCOMPLETE. Preserve original volumes/settings for rollback; rolling back to
497 restores the low-role capability exposure.

The first publisher run [`36953191960`](https://github.com/PastureStack/server/actions/runs/36953191960)
failed when official OpenSSL fixes became available; that failed evidence is
retained. This release selects Ubuntu `3.5.5-1ubuntu3.7` from the
signed HTTPS `20261002T000000Z` snapshot, without relaxing security gates.
The tracker retains four unfixed CVEs / eight Medium package findings.

## v1.6.497

This release packages the officially published Web Console `1.6.164`, including
the `1.6.163` state-badge/relative-date locale fixes and Receiver validation-label
fixes. Engine `v0.183.328`, distributed-cache runtime `5.7.5`, the immutable
`v1.6.460` runtime base and all security thresholds remain unchanged.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d`,
from Server source `80d97523052aa86ec761ade8ec487c382a8d5e1d`.
[Publication run `36836319609`](https://github.com/PastureStack/server/actions/runs/36836319609)
passed all 56 source gates, the exact image build, flattening and isolated
first start/restart `HTTP 200` / `pong`, plus 34 MFA policy/API checks.
Independent public readback verified 22 checksummed files plus their manifest,
the one-layer image, version/source/digest labels and SBOM identity. The unchanged
merged-rootfs security gate reports 58 raw findings and 14 exact vendor-pending
package findings (eight Medium and six Low, six unique CVEs) after VEX, with zero
untracked, Critical/High, fixed-available or secret findings. This is not a
zero-CVE claim.

The recorded QA497 `8080` deployment ran `v1.6.497` / Web Console `1.6.164`.
QA first start/restart returned `HTTP 200` / `pong` (10 and nine attempts), with
zero runtime-contract and tracked five-table DB-count differences. The three
original named data volumes, environment overrides, AppArmor and restart policy
were preserved. This is count preservation, not a whole-database row comparison;
Docker health is `null`, and no Docker `healthy` result is claimed. That
deployment did not establish packaged native Receiver browser acceptance.
Publisher smoke evidence
uses a separate disposable database; QA startup does not establish backend-write
authorization or company-site deployment. Historical HOLD receipts remain HOLD;
mobile, all-language/full-layout and the broader resource/role matrix remain
INCOMPLETE. See the [release notes](docs/releases/server-1.6.497.md) for exact
component pins and remaining acceptance. Retain the nearest immutable `v1.6.496`
QA rollback with its original named volumes/settings; the existing `v1.6.495`
image and backups are also retained, while its obsolete stopped container has
been removed.

## v1.6.496

This release packages Web Console `1.6.162` for the Host Add Container capability
gate and translated Secret desktop table headings, plus Orchestration Engine
`v0.183.328` with distributed-cache runtime `5.7.5`. The Engine and embedded
cache include Jackson `2.22.3` / `3.2.3`; numeric Hazelcast cluster runtime
remains `5.7.3`. No API permission or stored-data migration is introduced.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.496@sha256:6c85435b3de8771e5adff0b247274e0f1b9fe9d66c8b91e07d55a444e5589678`,
from Server source `d8e0e898b08aae45e040eb085936d11de14027fb`.
[Publication run `36821096323`](https://github.com/PastureStack/server/actions/runs/36821096323)
and independent public asset/image readback passed: 22 checksummed files plus
their manifest, one filesystem layer, official candidate first start/restart
`HTTP 200` / `pong`, and 34 MFA policy/API checks. The unchanged merged-rootfs
security gate reports 58 raw findings and 14 exact vendor-pending package
findings (eight Medium and six Low) after VEX, with zero untracked,
Critical/High, fixed-available or secret findings. This is not a zero-CVE claim.
The first failed publication run remains recorded and is not promoted.

Isolated QA496 `8080` deployment passed first start/restart `HTTP 200` / `pong`
(10 attempts each), with zero runtime-contract/DB-count differences across the
five tracked tables. Docker health is `null`, not a Docker `healthy` result.
Two zero-resource-write desktop cases passed at `1440 x 1000`: readonly Host
Add Container absence/Edit unavailability and the member Secret table's four
Traditional Chinese headings. Host statistics remained connecting and its
right-side table was not fully reviewed; the Secret body was deliberately
masked. These are not full-layout, backend-write authorization or lifecycle
acceptance. Mobile and all-language acceptance remain pending. Historical
HOLD receipts remain HOLD, the broader resource/role matrix remains INCOMPLETE,
and no company-site deployment is claimed. See the
[v1.6.496 notes](docs/releases/server-1.6.496.md) for component source/hash
identities; retain the immutable `v1.6.495` image and original volumes/settings
for rollback.

## v1.6.495

This patch packages Web Console `1.6.161` to fix existing Certificate
metadata edits blocked by a masked private key. It does not change API
authorization, authentication or stored certificate material. This image is
also refreshed to Ubuntu's official `libdbi-perl` `1.647-1ubuntu0.26.04.3`
security fix; failed candidates were not published. The immutable image is
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`,
from signed Server source `512d4b2377e34ce04a33266af19b62ed45949eda`.
[Publication run `36744673716`](https://github.com/PastureStack/server/actions/runs/36744673716)
and independent public asset/image readback passed. The final image has one
filesystem layer; the unchanged security gate reports 52 raw findings and eight
exact Medium vendor-pending package findings after VEX, with zero untracked,
Critical/High, fixed-available or secret findings. This is not a zero-CVE claim.
Isolated `8080` first start/restart passed with unchanged runtime settings and
database-count baselines. Scoped owner/member Certificate browser checks passed
on isolated `8080`, including Cancel, metadata Save, refresh and the in-use
delete explanation. Earlier HOLD receipts remain HOLD; current scoped evidence
does not resolve their historical foreign-baseline uncertainty. The broader
resource/role matrix remains INCOMPLETE. No company-site deployment is authorized.
See the [v1.6.495 notes](docs/releases/server-1.6.495.md) and retain `v1.6.494`
with the original volumes/settings for rollback.

## v1.6.494

Server `v1.6.494` packages Orchestration Engine `0.183.327` and Web Console
`1.6.160` for Certificate metadata edits and load-balancer reference protection.
The immutable published image is
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`,
built from Server source `c3b50ad6891ebbde4612e89dd5a1114bc731431c`.
Official [publication run `36704785404`](https://github.com/PastureStack/server/actions/runs/36704785404)
passed source, start/restart, security, checksum and publication gates. The 22
checksummed assets and checksum manifest match their published digests; the
final image has one filesystem layer. The merged-rootfs scan reports 52 raw
findings and the exact eight Medium vendor-pending package findings after VEX,
with zero untracked, Critical/High, fixed-available or secret findings. This is
not a zero-CVE claim.

Isolated `8080` deployment start/restart passed with an unchanged runtime
contract and tracked database-count baselines. Certificate API/browser acceptance remains
pending; this does not complete the broader resource/role matrix or establish
a company-site deployment. The runtime base, JDK, official OpenSSL security
packages, security thresholds and all other component coordinates are retained
from `v1.6.493`. Retain that immutable image and its original named volumes for
rollback. See the [v1.6.494 notes](docs/releases/server-1.6.494.md) for exact
component hashes and remaining acceptance boundaries.

## v1.6.493

Server `v1.6.493` packages Web Console `1.6.159`, which preserves
existing Registry passwords on username-only edits and explains that a blank
password input keeps the current password. Project and exact-resource update
checks remain unchanged. A signed Ubuntu package refresh also replaces the
inherited OpenSSL CLI, libraries, engines and provider with the official
`3.5.5-1ubuntu3.6` security fix; the failed first candidate was not published.
The immutable published image is
`ghcr.io/pasturestack/server:v1.6.493@sha256:61067362a2d91b791c7e80cb2ec4a5a907bc03884774d2019dccf1bf0e29788f`,
built from signed Server source `dc17c6f44e0624f0be324bfa0e682bb063674219`.
Official start/restart, runtime security, checksums and component gates passed;
the final image has one filesystem layer. Isolated 8080 start/restart and scoped
Registry credential browser save, password preservation, three-language
control bounds and exact-ID authorization passed. Broader role/resource and
workflow acceptance remains separate; this is not a formal company-site
deployment. See the [v1.6.493 notes](docs/releases/server-1.6.493.md).

## v1.6.492

Server `v1.6.492` packages Web Console `1.6.158`.
That version localizes Service direct-ID and Secrets load failures, and
unavailable responses to save or action requests, including HTTP 405. The
published image is
`ghcr.io/pasturestack/server:v1.6.492@sha256:a50d7859aebb7d08b62a237e42e1323b3da3b9cef51ab8028d4c730d2dd87a03`.
The release workflow passed candidate start, restart and security gates;
isolated 8080 deployment passed its startup/restart and baseline checks.
Broader role/resource and packaged browser acceptance are tracked separately,
and this is not a formal company-site deployment. See the
[v1.6.492 notes](docs/releases/server-1.6.492.md) for the exact source and
verification boundary.

## v1.6.491

Server `v1.6.491` packages Web Console `1.6.157`. Its
authenticated notice mount now runs when the component enters the page, so a
fresh direct-URL permission denial can move into the page flow without waiting
for another route transition. The published Web Console release asset matches
the pinned archive SHA-256. The Server image is published at
`ghcr.io/pasturestack/server:v1.6.491@sha256:c484d298e5bde93b51b44acd476a725bbaa471959d1079d19331c01bc55f8705`.
Isolated 8080 QA passed 14 scoped Stack and Service direct-create notice cases
with zero resource writes; it does not establish the broader role/resource
matrix or formal company-site deployment. See the
[v1.6.491 notes](docs/releases/server-1.6.491.md) for the exact source and
verification boundary.

## v1.6.490

Server `v1.6.490` packages Web Console `1.6.156`, which places authenticated
notices in the page flow between the navbar and main content. See
[v1.6.490 notes](docs/releases/server-1.6.490.md) for the source identity,
official archive identity, and packaged-browser acceptance criteria.

## v1.6.489

Server `v1.6.489` packages the reviewed Web Console `1.6.155` source and
archive with notification placement below the navbar and a viewport width
bound for the growl close control. See
[v1.6.489 notes](docs/releases/server-1.6.489.md) for the exact source and
artifact identity and the packaged-image and browser acceptance criteria.
Subsequent QA showed that the notice could still cover the page title or
sorting controls; `v1.6.490` addresses that layout defect.

## v1.6.488

Server `v1.6.488` packages Web Console `1.6.154`. Direct Stack and Service
create routes now show a localized permission notice before returning a user
without create permission to Stacks. Upgrade routes retain their separate
update permission check and notice. See [v1.6.488 notes](docs/releases/server-1.6.488.md)
for the source and artifact identity, validation scope, and remaining QA limits.

## v1.6.487

Server `v1.6.487` packages Web Console `1.6.153`. This patch tightens
project-bound write controls and localized denial feedback for the isolated
six-role QA matrix, while keeping the existing Engine, runtime base, and API
contracts. See [v1.6.487 notes](docs/releases/server-1.6.487.md) for the
exact Web Console source and artifact, validation scope, and remaining QA
limits. The package is not evidence that every resource-ID action passed.

## v1.6.486

Server `v1.6.486` packages Web Console `1.6.152` from commit
`dae731085d00f209ad4ee9419acd21d0b6d64f2a` and archive SHA-256
`56c147e392d40395690e925e0d8590e44de90bd7d6aaa3e6076ca75f30341486`.
It uses the visible translated name label for required-field errors in Stack,
Service, and Container forms. The runtime base, Engine, API permissions, and
resource payloads remain unchanged. See the
[v1.6.486 notes](docs/releases/server-1.6.486.md) for the exact validation
boundary and isolated browser QA still required before claiming acceptance.

## v1.6.485

Server `v1.6.485` pins the released Web Console `1.6.151` from commit
`dfb9b6e799e6b88ae1bf4dd94e71ccc0a8e357ce` and archive SHA-256
`9cee713690d0f6064bd2490e8cd0a118a7dfb5589d588d50ebb5c443a0eff2b3`.
Its Secret Edit control now follows the active resource, schema `PUT`, and self
link. Web Console main validation run `36416310187` succeeded. The
[v1.6.485 notes](docs/releases/server-1.6.485.md) distinguish that source
evidence from separate Server image, browser, and role-matrix acceptance.

## v1.6.484 release

Published Server `v1.6.484` packages Web Console `1.6.150` from source
`584a548dc30f8d59bcc3f1c9aba17e7b26eff4ef` and archive SHA-256
`9f9de0ab54ef9ad8b4bb1dd7f08e6d4c5c1aa1373e02f231fdad5e27916695b1`.
Its Server source is `32d18dcfac3e557f8c33fa83ce3522b4417a8659`. The
[v1.6.484 notes](docs/releases/server-1.6.484.md) record the source
preparation and its original validation boundary.

## v1.6.483 release

Server `v1.6.483` packages Web Console `1.6.149` with the unchanged Engine and
other components from `v1.6.482`. Secret Edit shows its immutable name
read-only and sends only the editable description. New Secret, Certificate,
and Registry resources refresh their server action links after creation.
Registry credential failures no longer repeat the parent Registry POST; an
uncertain write stays visible for deliberate recovery. The
[v1.6.483 notes](docs/releases/server-1.6.483.md) record exact source and
artifact coordinates, validation, isolated QA, and rollback boundaries.

## v1.6.482 release

Server `v1.6.482` packages Web Console `1.6.147` with the unchanged Engine and
other components from published `v1.6.481`. Service Edit now submits only
`name`, `description`, and `scale` instead of its cloned launch configuration
and upgrade strategy. The scale form preserves an initial zero, while its
separate quick action sends only `scale` after the debounce. See the
[v1.6.482 notes](docs/releases/server-1.6.482.md) for exact inputs, release
evidence, isolated `8080` deployment status, and pending browser write checks.

The published image is
`ghcr.io/pasturestack/server@sha256:e3ac65290f17981201a6cf2857e0f6def3eb79974746bc7110357fd87869a609`,
built from Server source `3d909952d31e8577793acb7e402e10b883e1c8a6`.
The isolated QA deployment is healthy before and after restart and displays Web
Console `1.6.147`. A bounded owner-browser run on fresh resource IDs passed
Service Edit Cancel, Save, and an injected `503` error with retry, plus Container
and Service Remove Cancel/Confirm; it restored the baseline. This run does not
establish the six-role permission matrix or production readiness.

## v1.6.481 release

Server `v1.6.481` packages Web Console `1.6.146` with the unchanged Engine and
other components from `v1.6.480`. Required-field errors on the Secret,
Certificate, and Registry forms use their visible translated labels. The
encrypted-private-key error is localized as well. See the
[v1.6.481 notes](docs/releases/server-1.6.481.md) for the exact scope and
isolated `8080` QA still required for browser and write acceptance.

The published image is
`ghcr.io/pasturestack/server@sha256:013eb045ed669344a67b8ac85d2ce56193abb74f34628281dec503dced8ab415`,
built from signed Server source `9c6914cda01a48dda4fb38f62d1a3f0c4db10be8`.
Publication does not accept the pending isolated `8080` localized validation
and six-role write matrix.

## v1.6.480 release

Server `v1.6.480`
packages Orchestration Engine `0.183.326`, Node Agent `0.13.27`,
Authentication Service `0.4.42`, Web Console `1.6.145`, and Webhook Automation
Service `0.10.3`. Web Console `1.6.145` resolves create capabilities across
mixed-case schema IDs, correcting the Registry Add false denial found in
`v1.6.479` isolated QA. Secret and Certificate Add controls, direct Add denial,
and Secret Edit action-link behavior remain as introduced in `v1.6.479`.
ProjectTemplate writes remain owner-scoped for non-admins:
the Web Console shows edit/remove only for an exact owner account ID match or
an administrator, while the Engine exposes `isPublic` read-only in the frozen
`/v1` user schema and omits misleading remove actions. Direct edit denial
shows consistent English or Traditional Chinese feedback; API-key save errors
stay in the modal without exposing key values. Container, project API-key,
and Receiver Hook write controls follow effective project capabilities.
Receiver cloning leaves the source's issued webhook URL and lifecycle state
behind, while a new private ProjectTemplate does not inherit the catalog
Default's external identity. Denied direct routes show localized feedback;
the container table keeps its actions reachable in narrow and RTL layouts.
New private ProjectTemplates are created from editable fields with deep-copied
stacks; new-resource clones omit server-owned identity and lifecycle fields.
Receiver clones omit inactive driver configuration and block unsupported drivers.
The engine carries FreeMarker `2.3.35`, and the
runtime retains signed Ubuntu curl `8.18.0-1ubuntu2.7`. Read the
[v1.6.480 notes](docs/releases/server-1.6.480.md) and
[earlier releases](https://github.com/PastureStack/server/releases) for the
exact scope, validation, and upgrade history.

The published image is
`ghcr.io/pasturestack/server@sha256:e388b0bddb4cca5a5116ba6862c6c0fffc29ee36b072d577759c43680bb87d39`,
built from signed Server source `ea5cb9f52ddbeb7286f1d0f3706d5f516079f508`.
Publication does not accept the pending isolated `8080` Registry Add role and
write matrix.

Docker Engine `29.4.1` through `29.7.2` is supported as a bounded SemVer
interval, and `29.8.0` is supported explicitly. The effective compatibility
setting is the API's `activeValue`: a value saved in the database can override
a newer image default after an upgrade. Check that value when a host's support
status does not match its installed Docker version.

The Linux runtime remains a compatibility-focused release. Windows node-agent
ZIPs are artifact candidates; Windows host support still requires a validated
bootstrap runtime and privileged Windows VM testing. See
[COMPATIBILITY.md](COMPATIBILITY.md) for the tested boundaries and
[SECURITY.md](SECURITY.md) for security and release evidence.

## Quick start

Before deploying, verify the `v1.6.500` numeric tag and immutable digest in
[Server releases](https://github.com/PastureStack/server/releases/tag/v1.6.500).
A registry login is not required. Pin the version and retain the database and
platform volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5
```

For TLS termination at a reverse proxy, set the exact public origin so
generated API links and WebSocket requests use HTTPS:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5
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

Use only an origin (`scheme://host[:port]`) for
`PROXY_PLATFORM_PUBLIC_ORIGIN`, without credentials, path, query, or fragment.
Set the reverse proxy, HTTPS, backup, and access policies for your deployment
before exposing the service. See [performance settings](docs/performance/README.md)
for supported JVM and embedded MariaDB variables.

## Upgrade and distribution

Existing databases can retain older image, download, Catalog, or Docker
compatibility settings after an image upgrade. Review effective settings and
follow the [upgrade guide](docs/upgrades/README.md) before changing persisted
coordinates. Its migration script is read-only by default; apply and rollback
are explicit, and the guide requires an isolated restore first. Preserve the
same volumes and configuration when changing the image tag or rolling back.

Reviewed images are published on public GHCR under immutable semantic version
tags. Matching [GitHub Releases](https://github.com/PastureStack/server/releases)
hold versioned assets, checksums, and release evidence. Catalog templates come
from the public [`catalog-templates`](https://github.com/PastureStack/catalog-templates)
repository at a pinned commit. Operational image references use version tags;
release records provide digests for independent verification.

## Build and validation

Server packages pinned source commits and verified component artifacts. Local
source and shell checks are:

```sh
bash scripts/test
bash scripts/check-server-source-gates.sh
```

Startup, database migration, node registration, backup/restore, upgrade, and
rollback need isolated VM validation. See [ORIGIN.md](ORIGIN.md) for source
provenance. The publication workflow is manually dispatched; a published image
does not by itself establish production readiness.

## Language and licensing

The web console provides English, German, Persian, Filipino, French,
Hungarian, Japanese, Korean, Brazilian Portuguese, Russian, Ukrainian,
Simplified Chinese, and Traditional Chinese for Taiwan. New server bootstrap
messages accept `PASTURESTACK_LOCALE=en-US` or `zh-TW`; protocol fields and
persisted identifiers remain unchanged.

The inherited project remains under the [Apache License 2.0](LICENSE), with
additional attribution in [COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md).
Bundled components retain their own licenses and notices.
