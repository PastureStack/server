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

Before deploying, verify the `v1.6.490` numeric tag and immutable digest in
[Server releases](https://github.com/PastureStack/server/releases). Do not use
this source-tree example until that release exists. A registry login is not
required. Pin the version and retain the database and platform volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.490
```

For TLS termination at a reverse proxy, set the exact public origin so
generated API links and WebSocket requests use HTTPS:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.490
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
