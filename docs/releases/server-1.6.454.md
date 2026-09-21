# Server v1.6.454

PastureStack Server v1.6.454 fixes the fresh OpenID Connect account lifecycle
race found by the six-account runtime matrix. It packages Orchestration Engine
0.183.313 with Authentication Service 0.4.42 and Web Console 1.6.122 while
preserving the existing volumes, HTTPS origin, OIDC, TOTP, Passkey, session
ownership, MFA confirmation, performance settings, and selected firewall
backend.

## Root cause and correction

Server v1.6.453 corrected the reported `Identity externalIdType is invalid`
boundary. Its first fresh-user Authentik matrix progressed beyond that point
and then failed with `MfaVerificationFailed`. Java Flight Recorder evidence
showed `MfaService.requireActiveAccount` rejecting the new account before MFA
challenge creation. The Authentication Service exchange and external identity
types (`oidc_user` and `oidc_group`) were valid; the platform account remained transiently `registering`
because `AuthDaoImpl.createAccount` scheduled `account.create` in the
background and returned immediately.

Orchestration Engine 0.183.313 executes the external account's standard create
process synchronously. A new account is therefore active before the token flow
enters MFA. The MFA service remains unchanged and continues to reject every
non-active account. Existing-account login, external identity allowlists,
stable platform identity ownership, OIDC access policy, session generation,
and session-bound logout are not relaxed.

## Immutable component coordinates

- Orchestration Engine `v0.183.313`, commit
  `78a73cb4b6c42ba5b10b46abd846a62abbd3fc35`, release JAR SHA-256
  `0725da73f2fe67d2e3b9788b8e9d11c62cb47d99fd2b94c9da3c0dea05532faa`.
- Authentication Service `v0.4.42`, commit
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

The related Engine reactor passes all 38 modules. The auth-logic module runs
89 tests with zero failures and zero errors, including a regression test that
requires synchronous account creation and rejects the background scheduling
path. The clean source gate, CodeQL verification, CycloneDX SBOM, release JAR
scan, and Dapper image scan pass with zero applicable Critical or High
findings.

The immutable Server publication gate must compare layered and flattened
configuration, publish one rootfs layer, start and restart fresh volumes,
exercise the authenticated API, validate the Host API SHA-256 chains, produce
a CycloneDX SBOM, and scan the merged filesystem. Runtime acceptance then uses
six distinct fresh Authentik accounts and isolated browser contexts. It covers
unrestricted, group-restricted, user-restricted, and denied site access;
owner, member, read-only, restricted, and no-access environment roles; `/v1`
and `/v2-beta`; project visibility; allowed and denied create, update, and
delete operations; WebSocket, explicit logout, and complete cleanup. A failed
matrix supersedes this patch rather than being recorded as success.

## Upgrade and rollback

Upgrade from v1.6.453 by changing only the image tag to `v1.6.454`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced.

Roll back by stopping v1.6.454 and starting the preserved v1.6.453 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
