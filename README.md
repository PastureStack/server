# PastureStack Server

Server packages the orchestration engine, web console, node agent,
authentication service, proxy, catalog, and database into a Docker image for
managing environments, hosts, stacks, services, containers, storage, and networking.

PastureStack is an independent community effort to preserve and modernize the
Rancher 1.6 ecosystem. It is not affiliated with Rancher Labs or SUSE.
This fork of [`rancher/rancher`](https://github.com/rancher/rancher) preserves
upstream history, authorship, licenses, and notices.

## Current release

[Server v1.6.516](https://github.com/PastureStack/server/releases/tag/v1.6.516)
includes Web Console `1.6.178` and Orchestration Engine `v0.183.333`.
The console supports OIDC, TOTP and passkeys, role-aware resource operations,
container resource/hardware settings, and movable terminal/log windows.
Hardware options require compatible node software and actual host capabilities;
GPU device access is not exclusive GPU allocation.

The current patch fixes inactive-environment view/edit loading and explains why
network settings are unavailable there. Active-environment authorization and
global member/metadata capabilities are unchanged. See the
[release note](docs/releases/server-1.6.516.md) for component identities,
verification results, and known limits. A published image is not a claim that
every resource/role/hardware combination has been tested.

## Quick start

Public GHCR downloads do not require a registry login. Pin the immutable image
and keep all three named volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.516@sha256:3741b7d87273387f36b49e44d407c240658db0ab7fc7fb8d518ae08f55ac733c
```

For HTTPS termination at a reverse proxy, set the exact public origin:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.516@sha256:3741b7d87273387f36b49e44d407c240658db0ab7fc7fb8d518ae08f55ac733c
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

`PROXY_PLATFORM_PUBLIC_ORIGIN` accepts only `scheme://host[:port]`, without
credentials, path, query, or fragment. Configure HTTPS, authentication, backups,
and access policies before exposing the platform. Supported JVM and embedded
MariaDB environment variables are in [performance settings](docs/performance/README.md).

## Upgrade and rollback

Back up the database and volumes, test a restore, then follow the
[upgrade guide](docs/upgrades/README.md). Preserve existing volume names,
environment variables, restart policy, AppArmor, and reverse-proxy configuration.
Do not replace existing volumes with new empty ones or run `docker compose down -v`.

Persisted image/download/catalog/Docker compatibility settings can outlive an
image upgrade; review their effective values. The migration tool is read-only
by default and requires explicit apply/rollback. Keep the previous image and
backup: after a database migration, rollback may require restoring matching data,
not merely selecting an older image tag.

[GitHub Releases](https://github.com/PastureStack/server/releases) contain
versioned assets, SHA-256 checksums, and release records. Built-in templates come
from pinned [`catalog-templates`](https://github.com/PastureStack/catalog-templates)
source. Historical changes belong in [release notes](docs/releases).

## Development

Server consumes pinned source commits and verified component artifacts.
For local source/shell validation:

```sh
bash scripts/test
bash scripts/check-server-source-gates.sh
```

Runtime, database migration, registration, backup/restore, and upgrade validation
use isolated hosts. Publication is a separate, manually dispatched workflow.
See [ORIGIN.md](ORIGIN.md) and [SECURITY.md](SECURITY.md).

## Language and licensing

The console packages thirteen locales, including Traditional Chinese for Taiwan.
Server bootstrap messages accept `PASTURESTACK_LOCALE=en-US` or `zh-TW`;
protocol fields and persisted identifiers are not translated.

The inherited project uses [Apache License 2.0](LICENSE), with attribution in
[COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md). Bundled components retain their own
licenses and notices.
