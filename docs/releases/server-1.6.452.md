# Server v1.6.452

PastureStack Server v1.6.452 removes the remaining timing-sensitive OpenID
Connect token-boundary check with an upgrade-safe validation boundary. It
packages Orchestration Engine 0.183.311 with
Authentication Service 0.4.42 and Web Console 1.6.122 while preserving the
existing volumes, HTTPS origin, OIDC, TOTP, Passkey, session ownership, MFA
confirmation, performance settings, and selected firewall backend.

## Root causes and correction

Authentication Service can successfully validate an OpenID Connect exchange
and return reviewed `oidc_user` and `oidc_group` identities before the
non-secret configured-provider flag has propagated through every Engine cache.
The Engine then re-read that separate flag while converting the same token and
rejected a valid incognito login with `Identity externalIdType is invalid`.
The error was therefore a timing race after successful provider validation,
not an invalid Authentik identity and not a browser-only failure.

Orchestration Engine 0.183.311 treats the successful external token exchange
as the provider boundary only for identities returned by that request. Every
identity must still have a reviewed external type; `oidc_user` and
`oidc_group` are accepted while unknown or missing types fail closed. Generic
identity and project-member paths continue to require current configured
provider state, so this change is not a broad bypass.

## Immutable component coordinates

- Orchestration Engine `v0.183.311`, commit
  `b4507f9e969afd685e0df87902211690e7350075`, release JAR SHA-256
  `24d710e50c44dbf4bbea65d0ce02091d7554643560cc5f28b84e21df08a5be60`.
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

The Engine release gate builds and tests all Maven modules, records resolved
inputs, generates a CycloneDX SBOM, scans the release JAR and build image, and
reports zero applicable Critical or High findings. Focused tests cover a
successful external exchange while the propagated provider flag is stale,
valid OIDC users and groups, and fail-closed unknown identity types without
weakening generic identity or project-member validation.

Runtime acceptance uses a multi-account set of six distinct temporary
Authentik identities and fresh incognito browser contexts. The matrix covers
unrestricted, group-restricted,
user-restricted, and denied site access; owner, member, read-only, restricted,
and no-access environment roles; project visibility; permitted and denied
stack operations; `/v1` and `/v2-beta`; refresh, WebSocket, explicit logout,
and complete cleanup. Any external-type error, privilege escalation,
unexpected denial, passive token deletion, or leaked resource fails the
release acceptance.

The Server publication pipeline preserves the established single-rootfs-layer
release contract, compares layered and flattened runtime configuration,
starts and restarts the candidate with fresh volumes, validates the Host API
SHA-256 chains, generates a CycloneDX SBOM, and scans the merged filesystem.

## Upgrade and rollback

Upgrade from v1.6.451 by changing only the image tag to `v1.6.452`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced.

Roll back by stopping v1.6.452 and starting the preserved v1.6.451 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
