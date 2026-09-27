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

The `v1.6.481` release checks passed and its numeric tag is public; a registry
login is not required. Use a fixed
semantic version tag and explicitly retain the database and platform volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.481
```

For TLS termination at a reverse proxy, set the exact public origin so
generated API links and WebSocket requests use HTTPS:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.481
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
