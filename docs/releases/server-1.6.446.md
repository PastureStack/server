# Server v1.6.446

PastureStack Server v1.6.446 closes the remaining same-origin cross-tab login
race by packaging Web Console 1.6.120. Orchestration Engine 0.183.309 and
Authentication Service 0.4.39 remain unchanged, so the session-bound token
delete and OIDC access-policy contracts introduced by the preceding releases
remain authoritative. This patch changes no database schema, persistent-volume
layout, firewall behavior, reverse proxy, or runtime environment contract.

## Root cause and correction

Cookies and `localStorage` are shared by tabs, while delayed requests and route
errors belong to the generation that started them. Web Console 1.6.119 had the
correct ownership model but still read shared cookie and generation state
outside the origin-level mutex in a few paths. An initial Ember transition could
also report a 401 without supplying a transition object. A stale tab could
therefore observe a half-committed login, or try to dispatch passive recovery
through an inactive route, before adopting the newer session.

Web Console 1.6.120 reads shared state inside the same mutex used by login
commit and explicit logout. Storage events and a token-free
`BroadcastChannel` converge through one serialized reconciliation path. Each
request, timer, and subscription retains its captured generation; a stale
passive failure stops old work and adopts the newer committed session without
clearing shared state or deleting a token. Initial 401 handling uses the owning
transition when present and directly enters the same passive-recovery boundary
when it is absent. Login-route refresh revalidates the cookie, direct logout
first adopts the owned generation, duplicate events cannot form a reload loop,
and only a user-initiated logout may send the one coalesced DELETE.

## Immutable component coordinates

- Web Console `1.6.120`, commit
  `20dc8c737b365731b19abb6d71763edd2d8b41f7`, release artifact SHA-256
  `d9ce9310bda50e5eec385fe30ac55dfdf51a1f3162c16aa1480385461eaa14f7`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Authentication Service remains `v0.4.39`, commit
  `3217b783222bcdf9a25ff0ba4a2a64a6b5e99c66`, release archive SHA-256
  `b2def9ebdf819cefa731c1b0a37c904a317d4e3d040738beef3f118f8d8d4e00`,
  and extracted binary SHA-256
  `c28e083eeefc327b3ee58208e15946dd727e77150dced61ec743c28533985dba`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The exact merged Web Console commit runs the complete 491-test suite and builds
the production archive twice from the same source-date epoch. The byte-identical
candidate contains one `1.6.120` root, the expected locale assets, and no source
maps. The release archive and checksum asset are read back from GitHub before
Server assembly.

The deterministic session suite holds a stale 401 behind a barrier until a TOTP
or virtual-authenticator Passkey login commits, repeating the critical ordering
100 times. It also covers storage events, stale WebSocket and timer failures,
route errors, same- and different-account replacement, three-tab adoption,
manual refresh, concurrent passive failures, missing or empty JWTs, cookie
readback failure, and one generation-bound explicit logout.

## Cross-tab acceptance

The production candidate is exercised against the isolated QA Server and its
in-platform Authentik provider. Three same-origin tabs adopt one completed
login, preserve the original in-product path or safely enter the authenticated
home page, and obtain successful token, schema, project, preference, setting,
and WebSocket responses. Passive failures issue zero token DELETE requests;
explicit logout issues one successful DELETE. Web Storage contains no JWT,
OTP, OIDC code, or session secret, and the test rejects 401 storms, DELETE
storms, and reload loops. TOTP and Passkey paths are both included.

The existing OIDC policy acceptance remains required: policy-only changes do
not repeat discovery; unrestricted access writes and reads an empty database
allowlist; restricted identities are deduplicated `oidc_user` or `oidc_group`
entries; invalid types and stale recovery return stable errors; the original
restricted policy is restored after the test.
The authenticated proxy boundary remains
`auth_config_proxy_identity=caller-platform-credential`.

The Server pipeline rebuilds the complete image, verifies the one-layer runtime
contract, starts and restarts it with fresh volumes, checks component identity,
generates CycloneDX SBOMs, and scans the final root filesystem. Publication is
blocked on applicable Critical or High findings, available but unapplied fixes,
unregistered vendor findings, secrets, checksum mismatch, or release-asset
mismatch.

The eight Ubuntu 26.04 Medium vendor-pending entries were rechecked against
Canonical's public CVE status on 2026-09-20. They remain vulnerable or
explicitly deferred without an installable Ubuntu fix, so this release records
them unchanged and schedules the next review for 2026-10-20 instead of
cherry-picking upstream patches or weakening the release threshold.

## Upgrade and rollback

Upgrade by changing only the image tag to `v1.6.446`. Preserve all existing
environment variables, named volumes, restart policy, AppArmor policy, HTTPS
origin, OIDC settings, performance settings, and nftables architecture. Verify
`/ping`, TOTP and Passkey login, three-tab adoption, authenticated API and
WebSocket access, and explicit logout before removing the previous image.

Roll back by stopping v1.6.446 and starting the preserved v1.6.445 image with
the same configuration and volumes. No database migration is introduced. No
production deployment, HAProxy change, or runtime patch is part of this
release.
