# Server v1.6.459

PastureStack Server v1.6.459 packages the authoritative environment-routing
repair from Web Console 1.6.124. It retains the shared Default and permission
matrix delivered by Orchestration Engine 0.183.317 and Server v1.6.458, while
preserving Authentication Service 0.4.42, existing volumes, HTTPS origin,
OIDC, TOTP, Passkey, session ownership, performance settings, and the selected
firewall backend.

## Shared Default environment

The default provisioning mode remains `shared`. Every successful local or
external login reconciles the account into the single Default environment
identified by the stable `adminProject` UUID only when no direct or group
membership already exists. Existing owner, member, restricted, readonly, and
`noaccess` roles remain authoritative. Existing personal environments and
workloads are retained; `personal` and `none` remain explicit alternatives.

## Permission-aware Web Console

Stack, service, load-balancer, alias, external-service, virtual-machine, and
catalog entry points continue to use the effective environment schema for
visible controls and direct URLs. Create requires POST, upgrade requires PUT,
and catalog management requires its project action link.

Web Console 1.6.124 additionally reads `project_id` from Ember's public
destination RouteInfo tree. A permitted non-default `/env/:project_id` direct
link or refresh is selected before tab-session and saved Default fallbacks, so
the console does not display workloads from another accessible environment.
Missing, inactive, or inaccessible IDs continue through the established
server-authorized fallback path. Account administration continues to show the
exact local and OpenID Connect identity links for each account.

## Immutable component coordinates

- Orchestration Engine `v0.183.317`, commit
  `aeca90a9699089b68691dd863b7fff2ad4744a64`, release JAR SHA-256
  `24d143a2ba674ad0a62bd22c610354ba4e89ab9e84bf5e57eb5d894142c30d01`,
  and CycloneDX SBOM SHA-256
  `3e047c63b9ce0668171ceb1544f94d3ffa3866a78c1007b4932f55e6764bfd18`.
- Web Console `1.6.124`, commit
  `5892b7b11ae0fee5ac67baedca200dec8826d45b`, release artifact SHA-256
  `9894883cfb149986fae7b963941a3d00dec324353da1d7b51482670310788d8f`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Web Console release gate runs all 527 Node 24 browser tests, focused
RouteInfo tests, source gates, and two byte-identical production builds. The
Server gate verifies the exact Web Console archive digest, version marker,
immutable source commit, merged root filesystem, one-layer result, runtime
restart, SBOM, VEX, and Critical/High security policy.

The isolated runtime matrix uses six independent OpenID Connect accounts and
checks owner, member, restricted, readonly, `noaccess`, and site-denied
behavior through both v1 and v2 APIs. It verifies exact project and stack
visibility, direct-route guards, catalog controls, account identity display,
WebSocket access, repeated-login idempotence, no project-count growth, and
exact cleanup of all temporary resources.

## Upgrade and rollback

Upgrade from v1.6.458 by changing only the image tag to `v1.6.459`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.459 and starting the preserved v1.6.458 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this release
procedure.
