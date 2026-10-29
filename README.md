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

[Server `v1.6.554`](https://github.com/PastureStack/server/releases/tag/v1.6.554) is published.
It integrates Web Console `1.6.196` and Engine `v0.183.355` for optional,
scoped AI collaboration. New pages start with tools off. Upgrade execution
requires an authenticated owner's separate confirmation; ordinary API Keys
retain their existing permissions. It also includes qualified security updates
for secret delivery and host provisioning. See the [release note](docs/releases/server-1.6.554.md)
and [verified publication identities](COMPATIBILITY.md#server-v16554-webmcp).
Scoped deployment and data-retention acceptance on port 8080 remain pending.

Personal API Keys remain available without an accessible environment. See the [Host guide](docs/hosts/README.md) before enrolling a host.

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
Maintained CLI `0.6.20` propagates rejected requests as nonzero errors. Legacy `0.6.14` can silently exit zero; see [client compatibility](COMPATIBILITY.md#maintained-cli-error-reporting) and check HTTP status explicitly for automation.

## Optional AI collaboration

The Web Console provides seven bounded service tools, an explicit per-page
on/off control and human review of upgrade plans. An optional stdio bridge lets
compatible clients use a dedicated scoped API Key. Both reuse current account
permissions; a Key cannot approve its own upgrade. See the
[AI collaboration guide](docs/ai-collaboration.md) for activation, supported
operations, audit records and rollback.

## Quick start

These examples use the published numeric version. Public downloads do not require
a registry login. Keep all three named volumes.

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 \
  -v pasturestack-cattle:/var/lib/cattle \
  -v pasturestack-mysql:/var/lib/mysql \
  -v pasturestack-mysqllog:/var/log/mysql \
  ghcr.io/pasturestack/server:v1.6.554
```

For HTTPS termination at a reverse proxy, set the exact public origin:

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.554
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

### First use

1. Open `http://<host>:8080`, or your configured HTTPS origin. Access control is
   initially disabled; keep the Server on a trusted network while completing setup.
2. In **Admin > Access Control > Local Authentication**, create the first
   administrator and choose **Enable Local Auth**. Sign out and back in to confirm
   that the account works.
3. In the **Default** environment, confirm the four system stacks:
   `network-services`, `ipsec`, `scheduler`, and `healthcheck`. With no Host yet,
   their services remain inactive while waiting for a Host.
4. Choose **Add Host** and the **Custom** option. On first use, confirm that the
   **Host Registration URL** is a Server address reachable from the node. Follow
   the [Host compatibility guide](docs/hosts/README.md), then copy and run the
   registration command generated by the UI on that Host.
5. Wait for the Host to become **Active**. The four system stacks should start
   their required networking, Metadata, DNS, scheduling, and health services
   automatically, without manually installing additional system stacks.
6. Before using the environment, check that a managed test workload can resolve
   internal service names and public DNS names, reach its required external
   endpoints, and report healthy through its configured health check.

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
