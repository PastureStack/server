# Server v1.6.462

PastureStack Server v1.6.462 packages Orchestration Engine 0.183.319 and Web
Console 1.6.126. It closes the shared-Default membership race, completes the
zero-environment browser state, and makes OpenID Connect account identities
both useful to administrators and safe to update.

## Atomic shared Default membership

The Engine performs the shared-Default membership lookup and conditional
insert while holding the same project lock used by administrator membership
updates. Every active direct, group, and stable-account identity is considered
before a baseline `member` link is created. Existing `owner`, `member`,
`restricted`, `readonly`, and `noaccess` decisions therefore remain
authoritative even when first login and an administrator update overlap.

The explicit `shared`, `personal`, and `none` provisioning modes and the
legacy `project.create.default=false` switch remain compatible. Invalid modes
continue to fail closed, existing personal environments are not migrated, and
the stable `adminProject` UUID remains the only shared Default identity.

## Zero-environment and account administration

An authenticated account with no active environment is a supported empty
state. The console clears stale project scope, skips project-scoped catalogs,
secrets, workloads, hosts, and storage reads, and directs obsolete environment
URLs to the environment selector without a loading loop.

Account administration prefers an authoritative `authIdentityLink` name,
login, then external ID. If an inactive historical row has no readable link,
its embedded identity is used locally instead of blanking the row or failing
the full inventory. Descriptions remain operator-owned account data. Loaded
identity links are display-only and are never serialized in an account update.

## Permission-matrix boundary

The runtime acceptance uses independent direct-user and OpenID Connect group
accounts for owner, member, restricted, readonly, and no-access roles, plus
site-denied and fresh-denied identities. Both v1 and v2-beta project and stack
collections are compared as exact sets; direct resource identifiers and
write/delete operations are also checked. The browser matrix validates the
real environment dropdown, a true zero-environment stale-route and reload
flow, the administrator account edit modal, and one explicit session-bound
logout. Passive authentication events must not emit a token DELETE.

The browser harness records no password, JWT, TOTP seed, one-time code, or
client secret. Failure screenshots clear input values first, temporary
Authentik principals and root-only secret files are removed through independent
cleanup paths, and a cleanup failure marks both the run and latest pointer as
failed.

## Immutable component coordinates

- Orchestration Engine `v0.183.319`, commit
  `222552c4b1fad095a5b55756cdca8e02b088ba04`, release JAR SHA-256
  `74ac55939399873eeb9ab0813ca193e373ccf2bdde3e3d884d5491b4d0b7608e`,
  and CycloneDX SBOM SHA-256
  `082af08ce90d7cb9b043452c177c8f60a0c36d52f0797e24baaa37d7c1e087b4`.
- Web Console `1.6.126`, commit
  `5cba85d3ab954c416b86910f760f987ec2bfc526`, release artifact SHA-256
  `a278904a10ce757510ed516507bd3926b02bab42a52a27bd153ff5e94e2998aa`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification and SBOM identity

The Engine focused authorization suite contains 17 passing tests, including a
100-iteration deterministic lock barrier. Its complete security release gate
builds every Maven module and reports zero applicable Critical or High finding
for the source, release JAR, and Dapper image. Web Console validation contains
536 passing browser tests, clean source/dependency gates, CodeQL, and two
byte-identical production builds.

The Server release workflow builds the layered candidate once, compares and
flattens it to one registry layer, starts and restarts the exact candidate, and
checks the Host API SHA-256 chain, public-origin proxy contract, MFA policy API,
VEX, secrets, and vulnerability policy. After the final registry digest is
known, the CycloneDX metadata component is rewritten to the canonical OCI purl
for `ghcr.io/pasturestack/server`, exact release version, and one exact
SHA-256 manifest digest. The same finalized SBOM is checksummed, uploaded, and
attested. Replacing the root `bom-ref` also rewrites the matching dependency
root and inbound references, and the release gate requires exactly one root
edge for the canonical image purl so the component graph cannot be orphaned.

## Upgrade and rollback

Upgrade from v1.6.461 by changing only the image tag to `v1.6.462`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.462 and starting the preserved v1.6.461 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this release
procedure.
