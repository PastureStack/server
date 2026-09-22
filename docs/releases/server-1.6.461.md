# Server v1.6.461

PastureStack Server v1.6.461 packages Web Console 1.6.125 and keeps account
administration usable when the account inventory contains an inactive
historical row whose identity-link lookup returns `AccountNotFound`.

## Account identity isolation

Account administration continues to query `authIdentityLink` with the exact
account ID for every readable row. A successful lookup remains authoritative
for local and OpenID Connect names, descriptions, and identities. HTTP 404 is
isolated to the affected historical row and uses that row's existing embedded
identity fields, so one stale account cannot redirect the entire inventory to
the failure page.

The exception is intentionally narrow. HTTP 401, 403, 5xx, transport, and
unexpected failures still reject the route and remain diagnosable. This release
does not broaden account visibility, change role evaluation, or infer one
account's identity from another account.

## Preserved authorization boundary

Orchestration Engine 0.183.318 is unchanged. The previously verified owner,
member, restricted, readonly, `noaccess`, site-denied, and fresh-denied
decisions therefore remain the server-side source of truth for both v1 and
v2 APIs. Workload create and upgrade controls still use the effective project
schema, direct `/env/:project_id` routes still select only permitted
environments, and required OpenID Connect access remains explicit-allowlist
only.

Session generation, the cross-tab authentication mutex, session-bound logout,
OIDC, TOTP, Passkey, WebSocket, shared Default reconciliation, runtime
resource fields, firewall selection, and persistent data formats are unchanged.

## Immutable component coordinates

- Orchestration Engine `v0.183.318`, commit
  `a06427975095bc37afdccc70be307a76a3adf1d3`, release JAR SHA-256
  `ba919954cfb2a809493499f34d2ecadb69f2dff011d32407309826ed655db593`,
  and CycloneDX SBOM SHA-256
  `ad369a1b9c0c431b392331539052d81096d7a326f8758ed46e4ff44418e483d7`.
- Web Console `1.6.125`, commit
  `c38e9843d663d9d6dbc5afcecd81c875cf79cd08`, release artifact SHA-256
  `3282cc3c09ea591ec9474e77c5fd721b61ad67ced6887acda3fa694954ecb9bf`.
- Authentication Service remains `v0.4.42`, commit
  `5589ef8fda68ae56e1afd64096965d452ee8a17e`, release archive SHA-256
  `f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`,
  and extracted binary SHA-256
  `feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

Web Console validation runs all 529 browser tests, including authoritative
identity links, isolated HTTP 404 fallback, and propagation of non-404 errors.
The release workflow also performs a clean Node 24 install, dependency and
source gates, two byte-identical production builds, and retained artifact
checksum verification.

Server validation verifies the exact Web Console release hash and commit,
version marker, merged root filesystem, one-layer output, restart behavior,
SBOM, VEX, and Critical/High security policy. Runtime acceptance on the QA
server additionally checks the rendered account inventory, absence of passive
token deletion, one explicit session-bound logout, and unchanged permission
sentinels.

The component-only assembly uses the immutable one-layer v1.6.460 runtime as
its digest-pinned base. It therefore reuses the already verified Ubuntu
security packages instead of downloading and reinstalling identical packages
during this Web Console-only patch. Full security-refresh builds retain the
Ubuntu-published CA package SHA-256 gate and fail closed on archive or snapshot
errors.

## Upgrade and rollback

Upgrade from v1.6.460 by changing only the image tag to `v1.6.461`. Preserve
all environment variables, named volumes, restart policy, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. This release does not add a database migration.

Roll back by stopping v1.6.461 and starting the preserved v1.6.460 image with
the same configuration and volumes. Production `stack.ascdc.tw`, its HAProxy,
OIDC provider configuration, and runtime-patched files are outside this release
procedure.
