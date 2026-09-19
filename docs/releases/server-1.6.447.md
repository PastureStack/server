# Server v1.6.447

PastureStack Server v1.6.447 preserves the configured OpenID Connect
site-access mode and allowlist across authentication-service and complete
Server container restarts. It packages Authentication Service 0.4.40 while
retaining Orchestration Engine 0.183.309 and Web Console 1.6.120. This patch
changes no database schema, persistent-volume layout, firewall behavior,
reverse proxy, Web Console session contract, or runtime environment contract.

## Root cause and correction

Authentication Service startup runs a compatibility migration from historical
provider-specific settings into the common access-policy settings. OIDC has no
legacy access-mode or allowlist keys. The migration nevertheless ran on every
startup, so the absent legacy OIDC values overwrote an already-saved common
allowlist with an empty value. A policy save succeeded and read back correctly,
but restarting the same v1.6.446 container cleared the restricted identities.

Authentication Service 0.4.40 first checks for the encrypted `auth.config`
object. Legacy provider settings are imported only while that canonical object
does not exist. Once migration is complete, the common access mode and
allowlist remain authoritative and startup does not touch them. The original
one-time migration path is preserved for older installations.

An installation whose restricted allowlist was already cleared must save the
intended restricted or required policy once after upgrading. The corrected
service then retains that value through subsequent service and Server
container restarts. Unrestricted mode continues to use an explicit empty
allowlist; policy-only changes still avoid discovery and provider reload, and
access expansion still requires the actor-, purpose-, and request-digest-bound
single-use MFA confirmation.

## Immutable component coordinates

- Authentication Service `v0.4.40`, commit
  `25b075bbd6e44f72011501cd4135d161e4c55d7d`, release archive SHA-256
  `58b20efae80e94603fab6afe991a1d6838897d8ec3e29f8b031a02d246a1162e`,
  and extracted binary SHA-256
  `976aa5306a6a42dd11016e70db053486ad0674f89f941029d407919fc9d85add`.
- Web Console remains `1.6.120`, commit
  `20dc8c737b365731b19abb6d71763edd2d8b41f7`, release artifact SHA-256
  `d9ce9310bda50e5eec385fe30ac55dfdf51a1f3162c16aa1480385461eaa14f7`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Authentication Service source regression test provides a canonical
`auth.config` object and fails if startup reads or writes any legacy setting.
The exact reviewed source passed formatting and static validation, the full
race-enabled Go suite, two clean byte-identical package builds, source and
product secret scans, CycloneDX generation, and applicable Critical/High
gates. The published archive and extracted binary are independently
checksum-pinned by Server assembly.

The Server acceptance saves one OIDC user and one OIDC group through the
public configuration API, verifies the database and API readback, restarts the
unchanged Server container, waits for readiness, and verifies the same two
identities again. The existing policy suite also covers restricted and
unrestricted transitions, explicit empty database persistence, principal
deduplication, invalid identity rejection, source-change recovery, stable
error codes, and suppression of OIDC discovery for policy-only changes.

The complete authentication acceptance additionally exercises Authentik OIDC,
TOTP, virtual-authenticator Passkey login, manual refresh, three-tab adoption,
delayed passive failures, API and WebSocket access, and one generation-bound
explicit logout. Passive paths must produce zero token DELETE requests; Web
Storage must contain no JWT, OTP, OIDC code, or session secret.

The Server pipeline rebuilds the complete image, compares the layered and
flattened runtime configuration, publishes one rootfs layer, starts and
restarts the candidate with fresh volumes, verifies component identities,
generates a CycloneDX SBOM, and scans the merged root filesystem. Publication
fails on applicable Critical or High findings, available but unapplied fixes,
unregistered vendor findings, detected secrets, or identity mismatches.

Eight Ubuntu 26.04 Medium findings covering 22 package occurrences remain in
the expiring vendor-pending register. Canonical publishes no installable fix
for the recorded package revisions. They remain explicit evidence rather than
being hidden through a threshold change or an unreviewed upstream patch.

## Upgrade and rollback

Upgrade by changing only the image tag to `v1.6.447`. Preserve every existing
environment variable, named volume, restart policy, AppArmor policy, HTTPS
origin, OIDC setting, performance setting, and nftables architecture. If a
restricted allowlist was previously cleared by startup, save the intended
policy once, restart the container, and confirm the same identities remain.
Then verify `/ping`, TOTP and Passkey login, cross-tab adoption, authenticated
API and WebSocket access, and explicit logout.

Roll back by stopping v1.6.447 and starting the preserved v1.6.446 image with
the same configuration and volumes. The earlier image contains the startup
policy-loss defect, so rollback is an availability measure and its access
policy must be rechecked. No database migration is introduced. No production
deployment, HAProxy change, or runtime patch is part of this release.
