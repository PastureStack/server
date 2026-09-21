# Server v1.6.455

PastureStack Server v1.6.455 closes the remaining upgraded-installation gap
between the current and frozen v1 OpenID Connect project-member schemas. It
packages Orchestration Engine 0.183.314 with Authentication Service 0.4.42 and
Web Console 1.6.122 while preserving existing data volumes, HTTPS origin,
OIDC, TOTP, Passkey, session ownership, MFA confirmation, performance
settings, and the selected firewall backend.

## Root cause and correction

Server v1.6.454 fixed fresh external-account activation and allowed six new
Authentik users to complete OIDC plus TOTP login. The six-account matrix then reached
environment provisioning: `/v2-beta/schemas/projectMember` exposed
`oidc_user` and `oidc_group`, while the serialized `/v1/schemas/projectMember`
still returned its historical option list. A v1 environment request containing
a reviewed OIDC member therefore failed with `422 InvalidOption` even though
the same identity was valid at login and in v2.

Orchestration Engine 0.183.314 enriches only the frozen
`projectMember.externalIdType` field from the reviewed current schema when the
v1 file schema is assembled. The merge retains historical values first,
de-duplicates in stable order, and does not widen any unrelated schema or
field. Unknown identity types remain rejected by the same runtime boundary.

## Immutable component coordinates

- Orchestration Engine `v0.183.314`, commit
  `68b194b96dadee0f60a4b94e027ea1caac8be018`, release JAR SHA-256
  `e685d6f65b2abd45e36fa28fd3db4223a03a1a1a6e316910e19eb0f84c8bd297`,
  and CycloneDX SBOM SHA-256
  `19330747bd419728d1b14084c7857e07428c4a79287394a4e62bd05fb4d4be12`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Web Console remains `1.6.122`, commit
  `fac6b1f90adf8f6524f6f0745a7f54605cfa6071`, release artifact SHA-256
  `c50ace84d94575c7869dd2c01ff9e741d3ebd54a656ec23d5a94dfeda6e79dba`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Engine framework reactor passes 66 tests with zero failures and errors,
including regressions that prove the scoped v1 option merge and that unrelated
schemas remain unchanged. The app-config contract test also passes. The clean
source gate, full Maven build, CodeQL verification, CycloneDX generation,
release JAR scan, and Dapper image scan report zero applicable Critical or
High findings.

The immutable Server publication gate must compare layered and flattened
configuration, publish one rootfs layer, start and restart fresh volumes,
exercise the authenticated API, validate Host API SHA-256 chains, produce a
CycloneDX SBOM, and scan the merged filesystem. Runtime acceptance then uses
six distinct fresh Authentik users and isolated browser contexts. It covers
unrestricted, group-restricted, user-restricted, and denied site access;
owner, member, read-only, restricted, and no-access environment roles; v1 and
v2 schemas and APIs; allowed and denied project and stack operations;
WebSocket; explicit logout; and complete test-resource cleanup. A failed
matrix supersedes this patch rather than being recorded as success.

## Upgrade and rollback

Upgrade from v1.6.454 by changing only the image tag to `v1.6.455`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced.

Roll back by stopping v1.6.455 and starting the preserved v1.6.454 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
