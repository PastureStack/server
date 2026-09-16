# Server v1.6.443

PastureStack Server v1.6.443 completes the OIDC site-access policy and browser
session fixes, then closes the related API-hydration, load-balancer target, and
OIDC project-member defects found during the v1.6.442 hotfix audit. The database
schema, Catalog, network plugins, volumes, and deployment contract are
unchanged.

## Immutable component coordinates

- Web Console `1.6.119`, commit
  `82211b731a90cdf5d3e213ee70bff34f10f28a63`, artifact SHA-256
  `9079db43bbad557367285fdc0f75286fcf39ba54b57c7ee2adee9d4472774df7`.
- Orchestration Engine `v0.183.305`, commit
  `6c3fb21879dd5df01f222392ecb4c66b92b91db5`, artifact SHA-256
  `0dd4afba50f38f17044b84e052a335062fa7842503bd1e7edf7482ebf3470ee7`.
- Authentication Service `v0.4.38`, commit
  `d6689f6139b4f5edc99a5c3336b80da80f487e16`, release archive SHA-256
  `4715e014599684072fd80da0824db22b21fe40d34dd47a7db3acec66e8d7b29d`,
  and extracted binary SHA-256
  `5e6111fc17f8dd352ca844f66bc8ce3ec0bc0782941de2890cdde2ec825d575f`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Browser session ownership

Web Console 1.6.119 keeps login commit and explicit logout under the same
fail-closed cross-tab mutex. Passive
401, storage, WebSocket, timer, and route errors never revoke a server token,
and a stale tab cannot delete a newer generation's token. JWTs remain outside
Web Storage. A matching explicit logout is idempotent and bound to the client
session generation. Orchestration Engine 0.183.305 preserves the create-only
`clientSessionId` through the shipped token authorization overlay, so the
database binding used by that logout contract is present in the assembled
Server rather than only in the base schema.

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

Web Console 1.6.119 accepts stable Authentication Service errors both at the
transport wrapper and top level. MFA request digests therefore reach the same
single-confirmation, one-retry path instead of collapsing to a generic error.

## API hydration, load-balancer targets, and OIDC identities

External-service `healthState` is writable model data again, so healthy,
unhealthy, and `null` API values hydrate without a computed-property setter
exception. The load-balancer service selector now writes through the owning
`PortRule.serviceId`; editing PUT payloads and reloads preserve the selected
backend.

Orchestration Engine 0.183.305 makes the core schema factory wait for completed
configuration startup before parsing public schemas. The reviewed
`oidc_user` and `oidc_group` defaults therefore appear in the integrated v1 and
v2-beta project-member options; base and configured values are merged in
stable order without duplicates. It retains configured-provider restoration
from persisted settings and rejects unknown types outside the configured
allowlist. Provider presence is not an authorization bypass.

## Server-side compatibility guard

The Server assembly verifies the Authentication Service release archive,
Web Console tar, Orchestration Engine JAR, their source commits and SHA-256
coordinates, the token session overlay, OIDC identity defaults, and policy
error markers before publication. The source gate also verifies that v1.6.443 README,
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
OIDC login, authenticated API access, a policy-only save, project membership,
an external-service reload, and a load-balancer target edit/readback before
removing the prior image. Roll back by stopping v1.6.443 and starting the preserved
v1.6.442 image with the same volumes and configuration; this patch introduces
no database migration.

The release workflow records the final GHCR manifest digest and publishes it
with the release evidence. No production deployment or reverse-proxy change is
part of the release operation.
