# Server v1.6.444

PastureStack Server v1.6.444 fixes the final proxy boundary that prevented a
confirmed OpenID Connect site-access policy from being saved through the
public `/v1-auth/config` API. The database schema, Web Console, Authentication
Service, Catalog, network plugins, volumes, and deployment contract are
unchanged.

## Root cause and correction

The generic `/v1-auth` proxy first copied the PastureStack caller's
`Authorization` header, then replaced it with the external identity-provider
access token for every authentication-service request. That behavior is
correct for provider-backed identity reads, but not for
`POST /v1-auth/config`: the Authentication Service must validate the
PastureStack operator and consume the actor-, purpose-, and request-digest-
bound MFA confirmation against the platform API. The substituted token was
therefore rejected before the confirmation could be audited or consumed, and
the client received another `MfaConfirmationRequired` response.

Orchestration Engine `v0.183.309` keeps the caller's platform authorization for
an exact, case-insensitive `POST /v1-auth/config`. Other `/v1-auth` requests
continue to receive the external provider token, including configuration reads
and identity enrichment. Unrelated proxy routes are unchanged. The decision is
method-and-path scoped; it does not weaken CSRF, Origin, MFA, cookie, or token
ownership checks.

## Immutable component coordinates

- Orchestration Engine `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Web Console remains `1.6.119`, commit
  `82211b731a90cdf5d3e213ee70bff34f10f28a63`, artifact SHA-256
  `9079db43bbad557367285fdc0f75286fcf39ba54b57c7ee2adee9d4472774df7`.
- Authentication Service remains `v0.4.38`, commit
  `d6689f6139b4f5edc99a5c3336b80da80f487e16`, release archive SHA-256
  `4715e014599684072fd80da0824db22b21fe40d34dd47a7db3acec66e8d7b29d`,
  and extracted binary SHA-256
  `5e6111fc17f8dd352ca844f66bc8ce3ec0bc0782941de2890cdde2ec825d575f`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Engine unit contract covers the exact POST exception, case-insensitive
matching, provider-token behavior for GET and other authentication routes, and
unrelated or null inputs. Its full Maven release gate builds all modules,
records resolved inputs, emits CycloneDX evidence, and scans the released JAR.
The Server source gate pins that signed release and records
`auth_config_proxy_identity=caller-platform-credential` as an immutable
assembly contract.

The integrated acceptance test uses the isolated Authentik provider on the QA
Server. It signs in through OIDC and platform MFA, saves a restricted policy,
rejects an invalid external identity type, requests a bound confirmation for
the unrestricted transition, consumes it once through public
`POST /v1-auth/config`, verifies that the API and database allowlists are both
empty, and checks that a policy-only update does not repeat provider discovery.
The previous access policy is restored after the test.

The release pipeline rebuilds the complete image, verifies the one-layer
runtime contract, starts and restarts the candidate with fresh volumes, checks
the component inventory, generates CycloneDX SBOMs, and scans the finished
root filesystem. Publication remains blocked on any applicable Critical or
High finding, available but unapplied fix, unregistered vendor finding,
secret, checksum mismatch, or release-asset mismatch.

## Upgrade and rollback

Upgrade by changing only the image tag to `v1.6.444`, preserving the existing
environment variables, named volumes, restart policy, AppArmor policy, HTTPS
origin, OIDC settings, performance settings, and firewall architecture.
Verify `/ping`, one OIDC login, authenticated API access, and one confirmed
policy transition before removing the previous image. Roll back by stopping
v1.6.444 and starting the preserved v1.6.443 image with the same volumes and
configuration. This patch introduces no database migration.

The release workflow records the final GHCR manifest digest and publishes it
with the release evidence. No production deployment, reverse-proxy change, or
runtime patch is part of this release.
