# Server v1.6.449

PastureStack Server v1.6.449 packages Web Console 1.6.121 to stop an expired
browser Cookie and stale shared generation from entering an authentication
loading loop. It retains Orchestration Engine 0.183.309, Authentication
Service 0.4.41, the existing persistent-volume layout, reverse-proxy contract,
session-bound explicit logout, OIDC, TOTP, Passkey, MFA confirmation, and
selected nftables or iptables backend.

## Root cause and correction

The compatible `GET /v2-beta/token` contract returns HTTP 200 in two distinct
states. An authenticated response contains browser identity data. An
unauthenticated response contains the configured provider login options and
has empty `accountId`, `user`, and `userIdentity` fields. Web Console 1.6.120
tested only whether `data[0]` existed, so it adopted the unauthenticated object
as a current session. Protected APIs then returned 401, passive recovery read
and adopted the same object again, and authenticated routes plus `/login`
remained behind the loading overlay.

Web Console 1.6.121 accepts the first current-token entry only when a non-empty
`accountId`, `user`, or `userIdentity` is present. It deliberately does not
require an exposed JWT because valid current-token responses may omit or mask
that field. An identity-free login-options object becomes the existing stable
local rejection `{status: 401, message: "No authenticated session"}`.

The validation failure enters the existing origin-level authentication mutex.
It clears shared and local state only when both the Cookie and generation still
match the request snapshot. The first matching failure clears once; concurrent
duplicates converge on `invalid` instead of being mistaken for a newer session
and triggering a reload. A delayed result still returns `stale` when a newer
Cookie or generation exists. Passive failures send no token DELETE; only a
user's explicit, generation-bound logout may revoke a server token.

## Immutable component coordinates

- Web Console `1.6.121`, commit
  `6b22b34d0451707ec86d6210fd498ccc67c66684`, release artifact SHA-256
  `ff702356b172d679a33f9776345ab44d6daa4bf4b53c13fd90afa2f4d2aed0eb`.
- Authentication Service remains `v0.4.41`, commit
  `1e566c8ba00aa134eb119be9d655625c870b28bc`, release archive SHA-256
  `2980282734e4d87bd92e73b8acef1dfa166df877e504e049c3556b13f66632bd`,
  and extracted binary SHA-256
  `3edeaca6715b2e4096aa0de641ea9b6f2f558a5077b5d533de58076dbea9f35b`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Web Console clean Node 24 release job runs all 496 browser tests. The new
deterministic cases cover HTTP 200 login options with an expired Cookie and
shared generation, direct validation, exactly-once matching-state cleanup,
three simultaneous passive 401 failures, and a newer session committed behind
a deferred old response. Existing tests retain the 100-run delayed TOTP and
Passkey race, three-tab adoption, manual refresh, old OIDC callback, explicit
logout, generation mismatch, 403 permission handling, and failed Cookie
readback boundaries. The release candidate is built twice byte-identically,
contains the expected locale assets, and contains no source maps.

Runtime acceptance uses the unchanged QA Server and data volumes. Before the
upgrade, the same three-tab script must reproduce the old loop with an expired
Cookie and stale generation. After the upgrade, two protected routes and one
direct `/login` tab must settle on the login page within five seconds, remove
the matching Cookie and shared generation, emit no `Loading Error`, stop
current-token retries, and send zero passive DELETE requests. TOTP and virtual
authenticator Passkey login, Authentik OIDC with TOTP, cross-tab adoption,
manual refresh, authenticated token, schema, project, user-preference and
setting reads, WebSocket upgrade, and one generation-bound explicit logout
remain required.

The Server publication pipeline rebuilds the complete image, compares layered
and flattened configuration, publishes one rootfs layer, starts and restarts
the candidate with fresh volumes, validates the Host API SHA-256 chains,
generates a CycloneDX SBOM, and scans the merged root filesystem. Applicable
Critical or High findings, available but unapplied fixes, secrets, component
identity drift, or an unregistered vendor finding fail publication. Existing
Ubuntu 26.04 Medium and Low findings without an installable vendor fix remain
recorded in the expiring vendor-pending register rather than being hidden or
patched outside the distribution.

## Upgrade and rollback

Upgrade from v1.6.448 by changing only the image tag to `v1.6.449`. Preserve
all environment variables, named volumes, `restart: always`, AppArmor policy,
HTTPS origin, OIDC settings, performance settings, and selected firewall
backend. Verify `/ping`, expired-session convergence, TOTP and Passkey login,
OIDC login, three-tab adoption, authenticated API and WebSocket access, and
the single explicit-logout DELETE.

Roll back by stopping v1.6.449 and starting the preserved v1.6.448 image with
the same configuration and volumes. No database migration is introduced.
Production `stack.ascdc.tw`, its HAProxy configuration, and runtime-patched
files are outside this release procedure.
