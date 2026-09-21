# Server v1.6.451

PastureStack Server v1.6.451 repairs the OpenID Connect external-identity
contract on upgraded installations. It packages Orchestration Engine
0.183.310 and Authentication Service 0.4.42 with the existing Web Console
1.6.122, persistent-volume layout, HTTPS-origin contract, OIDC, TOTP,
Passkey, session-bound logout, MFA confirmation, and selected firewall
backend unchanged.

## Root causes and correction

An older installation can have an encrypted OIDC configuration while its
common non-secret settings are absent or stale. Authentication Service
previously skipped that contract after the one-time migration boundary, and a
policy-only save or process reload did not repair it. Authentication Service
0.4.42 now reconciles the provider name, OIDC user type, identity separator,
and external-provider flag in a safe order during startup and after a
policy-only save. It does not repeat discovery, generate a new reload marker,
or rewrite the client secret.

The Engine also allowed the database setting
`auth.service.external.id.types` to replace its packaged defaults. A value
created before OIDC support could therefore omit `oidc_user` and `oidc_group`,
causing a valid OIDC login or project-member assignment to fail with
`Identity externalIdType is invalid`. Orchestration Engine 0.183.310 unions
the reviewed OIDC types with the configured list, still requires the OIDC
provider to be configured, and continues to reject every unknown type. The
dynamic project-member schema and frozen `/v1` schema publish the same stable,
deduplicated options.

## Immutable component coordinates

- Orchestration Engine `v0.183.310`, commit
  `7d9bbb05a12a5527e5f09c3682f6a7c3bbaab5d4`, release JAR SHA-256
  `35ad2a63a5c5ec2b1f569ec473448023557b438613d8027ed3f08ceb1f12ff9e`.
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

The Engine release gate builds all Maven modules, verifies the source revision
and resolved inputs, produces a CycloneDX SBOM, scans the JAR and build image,
and reports zero applicable Critical or High findings. Focused tests cover an
upgrade-safe stale database override, valid OIDC users and groups, an unknown
type rejection, dynamic schema options, and the frozen v1 schema.

Authentication Service tests cover startup and policy-only reconciliation,
setting order, idempotence, and the absence of discovery, secret mutation, or
reload-generation changes. Its release pipeline tests and scans the exact
archive and binary consumed here.

Runtime acceptance uses a multi-account set of temporary OIDC identities
rather than a single
administrator. The matrix covers unrestricted, group-restricted and
user-restricted site policies; owner, member, read-only, restricted and
no-access environment roles; project visibility and permitted/denied stack
operations; both `/v1` and `/v2-beta` schema and membership paths; fresh
browser contexts; logout; and cleanup. Any `Identity externalIdType is
invalid`, privilege escalation, unexpected denial, or leaked test resource
fails the release acceptance.

The Server publication pipeline still compares layered and flattened runtime
configuration, publishes one rootfs layer, starts and restarts the candidate
with fresh volumes, validates the Host API SHA-256 chains, generates a
CycloneDX SBOM, and scans the merged filesystem. Applicable Critical or High
findings, available but unapplied fixes, secret findings, component drift, or
an unregistered vendor finding fail publication.

## Upgrade and rollback

Upgrade from v1.6.450 by changing only the image tag to `v1.6.451`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. No database migration is introduced; reconciliation repairs existing
non-secret settings without replacing credentials.

Roll back by stopping v1.6.451 and starting the preserved v1.6.450 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this
release procedure.
