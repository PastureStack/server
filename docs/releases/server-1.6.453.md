# Server v1.6.453

PastureStack Server v1.6.453 completes the upgrade-safe OpenID Connect token
identity boundary. It packages Orchestration Engine 0.183.312 with
Authentication Service 0.4.42 and Web Console 1.6.122 while preserving the
existing volumes, HTTPS origin, OIDC, TOTP, Passkey, session ownership, MFA
confirmation, performance settings, and selected firewall backend.

## Root causes and correction

Server v1.6.452 removed a stale provider-state recheck, but its first
six-account incognito matrix still failed with
`Identity externalIdType is invalid`. The Authentication Service response was
valid: every provider identity had a reviewed `oidc_user` or `oidc_group`
type. The later Engine token path was the defect. After resolving or creating
the platform account, the Engine adds an internal stable `rancher_id`; the
same response-normalization loop then treated that Engine-owned identity as
another external provider identity and rejected it.

Orchestration Engine 0.183.312 validates all provider-supplied identities
before access-policy evaluation, account lookup, or persistent mutation. The
stable identity added after account resolution is handled on a separate
internal boundary and is accepted only when it resolves to the account
authenticated by the same token. A provider-supplied or mismatched
`rancher_id`, a missing type, and every unknown type fail closed. Generic
identity lookup and project-member input continue to require the configured
provider and their existing reviewed type contract.

## Immutable component coordinates

- Orchestration Engine `v0.183.312`, commit
  `8462f1fbe1b034caea1cd10304ec3db2078dbb80`, release JAR SHA-256
  `d4f5003e7e73af6bfc228dc598ade0c49dea22652f30f1d2527cd98de75623e6`.
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

The Engine's related 38-module Maven reactor passes. The auth-logic module
runs 88 tests with zero failures and zero errors, including sanitized
Authentik identities, upgraded database overrides, missing and unknown types,
a forged platform identity, a mismatched stable identity, and the valid
stable identity for the authenticated account. The clean source gate, CodeQL
verification, CycloneDX SBOM, release JAR scan, and Dapper image scan pass;
the applicable Critical and High counts are zero.

The immutable Server publication gate must still compare layered and flattened
configuration, publish one rootfs layer, start and restart fresh volumes,
exercise the authenticated API, validate the Host API SHA-256 chains, produce
a CycloneDX SBOM, and scan the merged filesystem. Runtime acceptance then uses
six distinct temporary Authentik accounts and fresh incognito browser
contexts. Its multi-account matrix covers unrestricted, group-restricted,
user-restricted, and denied site access; owner, member, read-only, restricted,
and no-access environment roles; `/v1` and `/v2-beta`; project visibility;
allowed and denied create, update, and delete operations; WebSocket, refresh,
explicit logout, and complete cleanup. A failed matrix supersedes this patch
rather than being recorded as success.

## Upgrade and rollback

Upgrade from v1.6.452 by changing only the image tag to `v1.6.453`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced.

Roll back by stopping v1.6.453 and starting the preserved v1.6.452 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
