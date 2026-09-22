# Server v1.6.458

PastureStack Server v1.6.458 aligns shared-environment membership, Web Console
entry points, and account identity display with the authorization contract
returned by the Server. It packages Orchestration Engine 0.183.317 and Web
Console 1.6.123 while preserving Authentication Service 0.4.42, existing
volumes, HTTPS origin, OIDC, TOTP, Passkey, session ownership, performance
settings, and the selected firewall backend.

## Shared Default environment

The default provisioning mode is `shared`. Every successful local or external
login reconciles the account into the single Default environment identified by
the stable `adminProject` UUID. A missing membership adds the stable internal
account identity with the baseline `member` role. Existing direct or group
membership is authoritative and is never replaced, including `owner`,
`restricted`, `readonly`, and `noaccess`. The reconciliation is serialized by
the project lock and remains idempotent under repeated or concurrent logins.

Existing personal environments and workloads are retained. Administrators who
need the earlier behavior can explicitly select `personal`; `none` disables
automatic project creation and membership. An unavailable shared Default
environment fails closed instead of silently creating another environment.

## Permission-aware Web Console

Stack, service, load-balancer, alias, external-service, virtual-machine, and
catalog entry points now use the effective project schema for both visible
controls and direct URL navigation. Create requires POST and upgrade requires
PUT. Catalog management additionally requires the project management action
link. Switching environments invalidates the cached capability decision.
The console does not reinterpret roles: owner, member, restricted, readonly,
and noaccess behavior remains the Server's schema contract.

Account administration loads each account's exact `authIdentityLink`
collection and shows name, description, and local or OpenID Connect identities.
Editing an account preserves this identity inventory without writing it back as
account data.

## Immutable component coordinates

- Orchestration Engine `v0.183.317`, commit
  `aeca90a9699089b68691dd863b7fff2ad4744a64`, release JAR SHA-256
  `24d143a2ba674ad0a62bd22c610354ba4e89ab9e84bf5e57eb5d894142c30d01`,
  and CycloneDX SBOM SHA-256
  `3e047c63b9ce0668171ceb1544f94d3ffa3866a78c1007b4932f55e6764bfd18`.
- Web Console `1.6.123`, commit
  `78705efff4b6b850d4ae9f6b06e90e0a62165311`, release artifact SHA-256
  `be9aa07ac82548c6c538850fae1a08482c06a3fafb78efe4d0fe74808d411a4a`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Engine release gate builds all Maven modules, runs focused shared-project
tests, and scans source, the product JAR, dependencies, SBOM, and Dapper image.
The Web Console release gate runs the complete Node 24 browser suite, the
permission route and identity tests, source gates, and two reproducible
production builds.

The Server runtime matrix uses six independent OpenID Connect accounts and
checks owner, member, restricted, readonly, noaccess, and site-denied behavior
through both v1 and v2 APIs. It verifies exact stack visibility, denied direct
UI routes, catalog controls, account identity display, WebSocket access,
repeated login idempotence, no project-count growth, and exact cleanup of all
temporary resources.

## Upgrade and rollback

Upgrade from v1.6.457 by changing only the image tag to `v1.6.458`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.458 and starting the preserved v1.6.457 image with
the same configuration and volumes. Existing environments created before this
release are not deleted or renamed. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this release
procedure.
