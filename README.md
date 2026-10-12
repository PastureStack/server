# PastureStack Server

Server packages the orchestration engine, web console, node agent,
authentication service, proxy, catalog, and database into a Docker image for
managing environments, hosts, stacks, services, containers, storage, and networking.

PastureStack is an independent community effort to preserve and modernize the
Rancher 1.6 ecosystem. It is not affiliated with Rancher Labs or SUSE.
This fork of [`rancher/rancher`](https://github.com/rancher/rancher) preserves
upstream history, authorship, licenses, and notices.

<a id="current-release"></a>

## Current release

Server [`v1.6.523`](https://github.com/PastureStack/server/releases/tag/v1.6.523) packages
released Web Console `1.6.183` and Orchestration Engine `v0.183.341`. Registration
tokens use their dedicated Basic authentication route. Add-host access follows
the form's actual operation: Custom requires RegistrationToken POST; built-in
and Other drivers require Host POST. Cancel / Go Back retains the return route
across driver changes and API-host settings refresh, with Hosts as the fallback
for a missing or self-referencing target.
Native project creation with a legacy or full API Key also retains the creator's
initial membership and default networks, without granting unrelated resources.
HA database dumps use the configured connection and a private temporary spool;
the response ZIP is committed only after successful, nonempty SQL output.
Failure and timeout clean up owned files without returning CLI stderr or secrets.
Existing database-export authorization is unchanged.
The immutable release, registry identities and component inputs were verified.
Startup/restart, native MFA and the seven-check registration entry gate passed.
Native HA export checks passed on both API roots: full access returned complete
SQL ZIPs; readonly and read-plus-export Keys were denied, with matching audit
events, unchanged protected resource snapshots and no export jobs.
The complete role matrix and deployment acceptance remain separate gates.
An HTTP entry check is not active-node lifecycle acceptance. See the
[release note](docs/releases/server-1.6.523.md) for exact identities and scope.

The console supports OIDC, TOTP and passkeys, role-aware resource operations,
container resource/hardware settings, and movable terminal/log windows.
Hardware options require compatible node software and actual host capabilities;
GPU device access is not exclusive GPU allocation. Audit queries and JSON, CSV
and XLSX exports preserve environment authorization, explicit date bounds and
bounded pagination. Query/export errors retain filters and successful query
results. See the [Host compatibility guide](docs/hosts/README.md) before enrolling
a host and the [API Key guide](docs/api-keys.md) for policy and audit behavior.
A packaged feature does not establish that every resource, role or hardware
combination has been tested.

## API Keys

Choose allow-by-default with deny exceptions, or deny-by-default with allow
exceptions, with optional expiry. Without exceptions these retain full or closed
access. Search for resource names; the editor and reviewed changes include a
resource-by-operation policy matrix, not an extra grant of authority. The maximum
access is the Key owner's current account/environment RBAC, including live
membership checks; a Key never grants an additional role. Existing legacy Keys
are not automatically narrowed on upgrade.
New Key secrets are shown once at creation and are not returned by later lists or
details. Per-Key audit separates authorization, the HTTP response and any later
job/stream completion. A successful WebSocket upgrade is recorded as a successful
HTTP `101` handshake, not as proof of the stream's later completion.
Environment-Key audit rechecks live Engine access in
Engine-verified project contexts; a caller-supplied project header is not a grant.
Delegated terminal/log access requires the verified Host API audit capability
and a compatible Linux Node Agent lifecycle. Open a Key's audit from its action
menu. See the [API Key guide](docs/api-keys.md) for policy and audit contracts.

## Quick start

Public GHCR downloads do not require a registry login. Use the released numeric
tag below and keep all three named volumes:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.523
```

For HTTPS termination at a reverse proxy, set the exact public origin:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.523
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
`PASTURESTACK_COMPONENT_ARTIFACT_DIR` to an isolated directory whose contents
exactly match the complete `component_assets` list in
[`server/build-api-explorer-patch-image.sh`](server/build-api-explorer-patch-image.sh).
Every asset is verified against its SHA-256 value. Without this directory, the
same hashes verify the versioned HTTPS release assets.

## Language and licensing

The console packages thirteen locales, including Traditional Chinese for Taiwan.
Server bootstrap messages accept `PASTURESTACK_LOCALE=en-US` or `zh-TW`;
protocol fields and persisted identifiers are not translated.

The inherited project uses [Apache License 2.0](LICENSE), with attribution in
[COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md). Bundled components retain their own
licenses and notices.
