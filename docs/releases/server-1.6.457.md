# Server v1.6.457

PastureStack Server v1.6.457 preserves the local recovery administrator while
OpenID Connect uses required site access. It packages Orchestration Engine
0.183.316 with Authentication Service 0.4.42 and Web Console 1.6.122 while
preserving existing data volumes, HTTPS origin, OIDC, TOTP, Passkey, session
ownership, MFA confirmation, performance settings, and the selected firewall
backend.

## Root cause and correction

Required site access correctly applies the configured OIDC user or group
allow-list to durable provider-bound tokens. The local password plus MFA
recovery flow also creates a durable token under the active provider, so the
generic external-service check applied the OIDC allow-list a second time and
could lock out the recovery administrator after policy changes.

Orchestration Engine 0.183.316 recognizes only the server-encrypted
`localAuthJWT` payload produced by the existing recovery flow. On every
request it rechecks that platform security and local recovery are enabled and
that the stable principal resolves to an active administrator. Only that
session bypasses the external OIDC allow-list. Non-administrators, inactive
accounts, disabled recovery, malformed payloads, and ordinary OIDC sessions
remain fail-closed under the unchanged user or group policy.
The supported external identity types remain exactly `oidc_user` and
`oidc_group`; this release does not widen the identity contract.

## Immutable component coordinates

- Orchestration Engine `v0.183.316`, commit
  `023a95f542f037617fb4de5a528dd02c73b28d7c`, release JAR SHA-256
  `5439563f2e2c1be5ac0e00965080a06df92f35680c816d4e9219a1a1f903d161`,
  and CycloneDX SBOM SHA-256
  `01d1a20c73ca6965cdac036f6a34bbdc9998c185b8aa9762ba74d37735a2ce9b`.
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

The Engine source gate, 38-module reactor, 96 auth-logic tests, CodeQL, Maven
dependency submission, and source, artifact, dependency, SBOM, and Dapper
image security gate pass on the release source. The security gate reports zero
source secrets, zero applicable Critical or High artifact findings, and zero
applicable Critical or High Dapper findings.

The six-account runtime acceptance uses distinct temporary Authentik users and isolated
incognito browser contexts. It covers first and repeated OIDC plus TOTP login,
restricted, required-group, required-user, and denied site access; local
administrator recovery under each policy; owner, member, read-only,
restricted, and no-access environment roles; v1 and v2 APIs; allowed and
denied operations; WebSocket; explicit logout; and complete test-resource
cleanup. An `externalIdType` error, local recovery lockout, internal-account
session, permission mismatch, or leaked temporary resource fails acceptance.

## Upgrade and rollback

Upgrade from v1.6.456 by changing only the image tag to `v1.6.457`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.457 and starting the preserved v1.6.456 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
