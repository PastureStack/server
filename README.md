# PastureStack Server

Server packages the orchestration engine, web console, node agent,
authentication service, proxy, catalog, and database into a Docker image for
managing environments, hosts, stacks, services, containers, storage, and networking.

PastureStack is an independent community effort to preserve and modernize the
Rancher 1.6 ecosystem. It is not affiliated with Rancher Labs or SUSE.
This fork of [`rancher/rancher`](https://github.com/rancher/rancher) preserves
upstream history, authorship, licenses, and notices.

## Current source

Server `v1.6.519` is an unpublished candidate, packaging Web Console `1.6.181`
and Orchestration Engine `v0.183.334`. API Keys support full, custom and closed
policies, optional expiry, and key-scoped durable audit records. Their permissions
remain bounded by the owner's current role and environment access. Delegated
terminal/log access requires the verified Host API audit capability and the
compatible Linux Node Agent lifecycle.

The console supports OIDC, TOTP and passkeys, role-aware resource operations,
container resource/hardware settings, and movable terminal/log windows.
Hardware options require compatible node software and actual host capabilities;
GPU device access is not exclusive GPU allocation. Audit queries and exports
cover retained records with environment-aware access and bounded pagination.
See the [candidate release note](docs/releases/server-1.6.519.md) for exact
component identities and verification boundaries. A version or packaged feature
does not establish that every resource/role/hardware combination has been tested.

## API Keys in the source candidate

Choose allow-by-default with deny exceptions, or deny-by-default with allow
exceptions, with optional expiry. Without exceptions these retain full or closed
access. Search for resource names; the editor and reviewed changes include a
resource-by-operation policy matrix, not an extra grant of authority. The maximum access
is always the Key owner's current account/environment RBAC; a Key never grants
an additional role. Existing legacy Keys are not automatically narrowed on upgrade.
New Key secrets are shown once at creation and are not returned by later lists or
details. Per-Key audit separates authorization, the HTTP response and any later
job/stream completion. Environment-Key audit rechecks live Engine access in
Engine-verified project contexts; a caller-supplied project header is not a grant.
Open a Key's audit from its action menu; the close control follows the audit
filters, results and details, below the audit block.
Scope options and unselected hints use readable light/dark theme text, including
keyboard highlighting; narrow layouts keep the matrix in its own scroll region.
Errors use the existing API status/code and console error
handling. See the [API Key guide](docs/api-keys.md) for policy and audit contracts.

## Current release

The currently downloadable [Server v1.6.518](https://github.com/PastureStack/server/releases/tag/v1.6.518)
includes Web Console `1.6.180` and Orchestration Engine `v0.183.333`.
The quick-start examples below use this published image until the candidate is
verified and separately released. Its exact artifact identity and verification
boundaries are recorded in the [published release note](docs/releases/server-1.6.518.md).

## Quick start

Public GHCR downloads do not require a registry login. Use the published numeric
version tag and keep all three named volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.518
```

For HTTPS termination at a reverse proxy, set the exact public origin:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.518
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

After using API Key policy or expiry, do not downgrade directly to a
policy-unaware Engine: an older version can treat a restricted or expired Key
as full access. Follow the [API Key rollback safety guide](docs/upgrades/api-key-policy-rollback.md)
before any downgrade or database restore.

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

The component candidate build uses the same release Dockerfile and verification
gates. `server/build-component-candidate.sh` requires actual component commits
and SHA-256 values; it does not publish or deploy. Set
`PASTURESTACK_COMPONENT_ARTIFACT_DIR` to an isolated directory with the five
component assets for an unpublished candidate. Without it, the same hashes
verify the versioned HTTPS release assets. The current published release remains
`v1.6.518` until a candidate is verified and separately released.

## Language and licensing

The console packages thirteen locales, including Traditional Chinese for Taiwan.
Server bootstrap messages accept `PASTURESTACK_LOCALE=en-US` or `zh-TW`;
protocol fields and persisted identifiers are not translated.

The inherited project uses [Apache License 2.0](LICENSE), with attribution in
[COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md). Bundled components retain their own
licenses and notices.
