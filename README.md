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

## Current release

Server [`v1.6.471`](https://github.com/PastureStack/server/releases/tag/v1.6.471)
packages Orchestration Engine `0.183.323`, Node Agent `0.13.27`,
Authentication Service `0.4.42`, and Web Console `1.6.136`. The console bounds
the environment-switcher menu in left-to-right and right-to-left views and
corrects the Persian failure-page direction. On console load it rechecks a
stored environment selection, and the management page refreshes its list so
revoked entries disappear after refresh. An already open view updates on
reinitialization or an explicit environment switch. Site administrators can
still switch to every active environment. The engine
carries FreeMarker `2.3.35`, and the runtime retains signed Ubuntu curl
`8.18.0-1ubuntu2.7`. Read the
[v1.6.471 notes](docs/releases/server-1.6.471.md) and
[earlier releases](https://github.com/PastureStack/server/releases) for the
exact scope, validation, and upgrade history.

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

The versioned image is public; a registry login is not required. Use a fixed
semantic version tag and explicitly retain the database and platform volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.471
```

For TLS termination at a reverse proxy, set the exact public origin so
generated API links and WebSocket requests use HTTPS:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.471
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
