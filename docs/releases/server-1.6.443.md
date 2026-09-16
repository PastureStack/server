# Server v1.6.443

PastureStack Server v1.6.443 completes the OIDC site-access policy fix while
retaining the cross-tab session-ownership protection released in v1.6.442.
The runtime change is limited to Authentication Service v0.4.38; the database
schema, Web Console, Orchestration Engine, Catalog, network plugins, volumes,
and deployment contract are unchanged.

## Immutable component coordinates

- Web Console `1.6.118`, commit
  `63ff73bc26103ab32de5ba30768391caa3af9f6a`, artifact SHA-256
  `4ffbfcb787ca28651a7dcb59e294bd236d5d1a35a0087ec33a3f375ecd1b51b4`.
- Orchestration Engine `v0.183.303`, commit
  `accb664b674fd0391e858bfd9a7748641e6440ab`, artifact SHA-256
  `6b26237379fca106500dedf310bb7d43c09a25e08c0ff421a0b3468d6e4a647b`.
- Authentication Service `v0.4.38`, commit
  `d6689f6139b4f5edc99a5c3336b80da80f487e16`, release archive SHA-256
  `4715e014599684072fd80da0824db22b21fe40d34dd47a7db3acec66e8d7b29d`,
  and extracted binary SHA-256
  `5e6111fc17f8dd352ca844f66bc8ce3ec0bc0782941de2890cdde2ec825d575f`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Browser session ownership

Web Console 1.6.118 and Orchestration Engine 0.183.303 are unchanged. Login
commit and explicit logout use the same fail-closed cross-tab mutex, passive
401, storage, WebSocket, timer, and route errors never revoke a server token,
and a stale tab cannot delete a newer generation's token. JWTs remain outside
Web Storage. A matching explicit logout is idempotent and bound to the client
session generation.

## OIDC site-access policy updates

Authentication Service 0.4.37 correctly classified policy-only updates but
still wrote `auth.service.config.update.timestamp`. The external reload watcher
treated that write as a provider-source change and reinitialized OIDC, causing
an unnecessary discovery request after a successful policy save.

Authentication Service 0.4.38 removes that provider-reload generation from the
policy-only path. Updating access mode or the normalized OIDC user/group
allowlist now preserves the active provider instance and does not repeat
discovery or local recovery. First enablement, provider switches, and actual
identity-source changes still update the generation, initialize the provider,
and require recent local recovery. Permission expansion still requires the
single-use `oidcAccessPolicyUpdate` MFA confirmation bound to the actor,
purpose, and canonical request digest. `unrestricted` always stores an empty
allowlist.

## Server-side compatibility guard

The Server assembly verifies the Authentication Service release archive,
extracted binary, source commit, static version output, and policy error
markers before publication. The source gate also verifies that v1.6.443 README,
compatibility documentation, OpenVEX, vendor-pending register, and this release
record all name the same immutable coordinates.

The release pipeline rebuilds the complete image, verifies the one-layer
runtime contract, starts and restarts the candidate with fresh volumes, checks
the packaged component inventory, generates CycloneDX SBOMs, and scans the
finished root filesystem. Publication remains blocked on any applicable
Critical or High finding, available but unapplied fix, unregistered vendor
finding, secret, checksum mismatch, or release-asset mismatch.

## Upgrade and rollback

Upgrade by changing only the image tag to `v1.6.443`, keeping the existing
environment variables, named volumes, restart policy, AppArmor policy, HTTPS
origin, OIDC settings, and firewall architecture. Verify `/ping`, one complete
OIDC login, authenticated API access, and a policy-only save before removing
the prior image. Roll back by stopping v1.6.443 and starting the preserved
v1.6.442 image with the same volumes and configuration; this patch introduces
no database migration.

The release workflow records the final GHCR manifest digest and publishes it
with the release evidence. No production deployment or reverse-proxy change is
part of the release operation.
