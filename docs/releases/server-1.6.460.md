# Server v1.6.460

PastureStack Server v1.6.460 corrects the OpenID Connect admission boundary for
returning accounts in restricted site-access mode. It packages Orchestration
Engine 0.183.318 and retains Web Console 1.6.124, Authentication Service
0.4.42, the shared Default environment, existing volumes, HTTPS origin, OIDC,
TOTP, Passkey, session ownership, performance settings, and the selected
firewall backend.

## Restricted and required site access

The Engine now resolves an existing active account from its verified external
identity link before evaluating restricted-site access. Restricted mode may
therefore use that account's existing direct or group project membership,
including shared Default membership. The decision remains fail-closed for an
unresolved or inactive account.

Required mode does not receive the stable account identity during admission and
remains allow-list-only for ordinary OIDC sessions. A project membership cannot
become a required-site allow-list bypass. Explicit project roles, including
`noaccess`, continue to govern project and workload operations after admission.

## Verification boundary

The focused Engine tests cover a returning external identity whose stable
account membership authorizes restricted mode and prove that the same stable
membership does not bypass required mode. The complete dependent Maven reactor,
CodeQL verification, and the security release gate must pass for the exact
merged Engine commit before Server assembly.

The isolated runtime matrix uses six independent OIDC accounts and both v1 and
v2 APIs. It checks unrestricted, restricted, and required site admission;
owner, member, restricted, readonly, `noaccess`, and site-denied roles; project
and stack create/read/update/delete; direct routes; account identities;
WebSocket access; and exact cleanup of temporary identities and resources.

## Immutable component coordinates

- Orchestration Engine `v0.183.318`, commit
  `a06427975095bc37afdccc70be307a76a3adf1d3`, release JAR SHA-256
  `ba919954cfb2a809493499f34d2ecadb69f2dff011d32407309826ed655db593`,
  and CycloneDX SBOM SHA-256
  `ad369a1b9c0c431b392331539052d81096d7a326f8758ed46e4ff44418e483d7`.
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

## Upgrade and rollback

Upgrade from v1.6.459 by changing only the image tag to `v1.6.460`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.460 and starting the preserved v1.6.459 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this release
procedure.
