# Server v1.6.441

This patch release fixes two authentication regressions present in Server
`v1.6.440` (Web Console `1.6.116`, Orchestration Engine `v0.183.301`). A stale
tab could observe a newer tab's shared cookie and run the common logout path
after a delayed 401, storage notification, timer, route failure, or WebSocket
event. That revoked the newer token and returned the browser to login after
OIDC plus TOTP or Passkey had already succeeded. Separately, saving only an
enabled OIDC provider's site-access policy was mistaken for provider
initialization, so an expired local-recovery window produced a generic 400 and
an unrestricted policy could retain a stale allowlist.

## Immutable inputs

- Web Console `1.6.118`, commit
  `63ff73bc26103ab32de5ba30768391caa3af9f6a`; artifact
  `web-console-1.6.118.tar.gz` SHA-256
  `4ffbfcb787ca28651a7dcb59e294bd236d5d1a35a0087ec33a3f375ecd1b51b4`.
- Orchestration Engine `v0.183.303`, commit
  `accb664b674fd0391e858bfd9a7748641e6440ab`; artifact JAR SHA-256
  `6b26237379fca106500dedf310bb7d43c09a25e08c0ff421a0b3468d6e4a647b`.
- Authentication Service `v0.4.37`, commit
  `48c3f9e850b4f91f8ea8ee78bf7c3b206464a4cb`; release archive SHA-256
  `5f749bc205443c27d696523ad470242365061bb25ab79fd1a09a1510465dbfa6`;
  extracted binary SHA-256
  `11a61ce9c85350207374b1552dd60a0b44c87bea1a8727925ff5c286b8f3f47f`.
- Catalog remains pinned at
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates
  `v0.3.12`).

Only pure numeric semantic product tags are release coordinates. This release
does not change HAProxy, firewall providers, CSRF or Origin validation, cookie
security attributes, performance settings, or the nftables architecture. It
changes only the authentication session-ownership and OIDC site-access update
paths described here; it does not weaken MFA or local-recovery requirements.

## Browser session ownership

Successful login now creates a fresh high-entropy session generation even when
the same account signs in again. Local storage contains only the non-secret
generation, account identifier, and commit time. Each tab keeps its adopted
generation and token snapshot in memory; JWTs are never placed in Web Storage,
URLs, or logs.

`acceptLogin`, cookie write/readback, generation commit, and explicit logout
share one cross-tab authentication mutex. Browsers with Web Locks use it
directly; the tested fallback uses a renewable IndexedDB lease and fails closed
instead of running without mutual exclusion. Login rejects missing or empty
JWT values and does not finish until the cookie is readable.

Passive 401 responses, storage events, WebSocket logout notifications, timers,
and route errors can stop work or reconcile the tab, but cannot revoke a token.
A 403 is treated as an authorization failure rather than a global logout.
Every asynchronous path captures the generation that started it and checks
ownership before clearing local state. A stale event adopts the newer committed
session instead of deleting its cookie or shared metadata.

After a generation commit, other tabs validate `GET /v2-beta/token` and adopt
the session automatically. Login, MFA, and callback routes safely replace to
their validated in-site return path (or the authenticated default); already
authenticated pages reload their current route once. Duplicate events are
coalesced to prevent reload loops, and stale OIDC/MFA callbacks cannot overwrite
a newer session. A manual refresh reconstructs the session from the valid
cookie.

Only a user-initiated logout performs
`DELETE /v2-beta/token/current`, and it sends at most one request while holding
the auth mutex until the response completes.

## OIDC site-access policy updates

Authentication Service classifies the canonical incoming configuration before
it mutates provider state. An already enabled `oidcconfig` provider whose
identity-source fields are unchanged can update only `accessMode` and
`allowedIdentities` without repeating discovery, provider initialization, or
the five-minute local-recovery ceremony. Initial enablement, provider changes,
and changes to the discovery URL, client identity, CA, secret, or identity
claims still require fresh local recovery and a successful provider
initialization.

An access-policy expansion consumes the existing one-use security confirmation
bound to the administrator account, `oidcAccessPolicyUpdate` purpose, and a
canonical request digest. It does not reuse the process-wide
`localRecoveryVerifiedAt` timestamp. `unrestricted` is canonicalized to an
empty allowlist in the Web Console and Authentication Service, including an
explicit empty database write. Restricted and required policies accept only
deduplicated `oidc_user` and `oidc_group` principals keyed by
`externalIdType` plus `externalId`. The API returns stable
`LocalRecoveryRequired`, `MfaConfirmationRequired`, and
`InvalidAllowedIdentity` codes instead of collapsing these cases into a
generic 400.

## Server-side compatibility guard

New clients bind issued tokens to their client session identifier. Revoking a
bound token requires the matching
`X-PastureStack-Client-Session-Id`; a missing or mismatched identifier returns
204 without revoking the token or expiring a newer cookie. Missing and already
revoked tokens are also idempotent 204 responses. Existing unbound legacy
tokens retain the previous explicit-logout behavior.

Restricted-session issuance is serialized per account. A newer generation is
committed before an older session is removed, and a stale concurrent issuance
is rejected with 409. Unrestricted concurrent sessions remain independent.
Database migration `core-126` adds the nullable session binding and its index.

## Verification

Web Console passed all 477 unit tests. The deterministic deferred-response
suite covers delayed 401 after TOTP and Passkey acceptance, storage events,
WebSocket events, timers, route failures, same-account relogin, account switch,
three-tab adoption, refresh recovery, simultaneous passive failures, explicit
logout idempotency, invalid JWT values, cookie readback failure, both
concurrent-session settings, and fallback-lock exclusion. The critical
TOTP/Passkey race was repeated 100 times without sleeps.

Orchestration Engine passed its complete Maven build and test workflow,
including database migration checks, session binding, restricted and
unrestricted concurrency, stale-generation rejection, and idempotent logout.
The backend barrier race was repeated 100 times. CodeQL, dependency review,
SBOM generation, and security diff scans completed without reportable
findings.

Authentication Service passed its full test suite and Linux race detector.
Controlled provider tests prove that policy-only saves perform zero discovery,
while first enablement and every identity-source change still require current
local recovery. They also cover actor/purpose/digest-bound MFA consumption,
one-use replay rejection, unrestricted database clearing and readback, strict
principal types, and principal deduplication.

The Server release gate additionally builds from these immutable artifacts,
checks embedded component versions, revisions, hashes, OIDC schema fields and
stable error markers, starts and restarts a disposable candidate on loopback
port 8080, and validates authenticated API plus reverse-proxy contracts. Its
API smoke consumes and rejects replay of a bound policy confirmation and
checks stable recovery and invalid-principal failures. The gate then scans the
merged runtime, emits an SBOM and attestations, and verifies that the published
image remains a one-rootfs-layer multi-stage runtime.

## Upgrade and rollback

Before upgrading, retain the `v1.6.440` image digest and back up the database,
named volumes, Compose file, and environment file. Change only the image
reference to the immutable `v1.6.441` digest; preserve all existing
environment variables, external named volumes, `restart: always`, AppArmor,
HTTPS origin, OIDC, performance parameters, and firewall configuration.

After startup, verify `/ping`, login with both TOTP and Passkey, automatic
adoption by at least two additional same-origin tabs, refresh recovery,
authenticated token/schema/projects/userpreferences/setting APIs, WebSocket
reconnect, and one explicit logout. Also save an unchanged-provider policy with
an expired recovery window, switch restricted to unrestricted, verify the API
and database allowlist are empty after readback, and confirm a new valid OIDC
user can log in. There must be no passive DELETE, unexpected discovery, 401
storm, DELETE storm, reload loop, or secret leakage. The external-provider
login check is a post-upgrade deployment acceptance step and is not claimed by
the disposable release fixture.

Rollback by stopping the new container, restoring the saved database and named
volumes if migration `core-126` has been applied, and starting the saved
`v1.6.440` digest with the unchanged Compose configuration. Do not mix an
older Engine with a database advanced beyond its supported migration state.
