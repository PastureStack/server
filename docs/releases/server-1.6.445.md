# Server v1.6.445

PastureStack Server v1.6.445 fixes the remaining OIDC unrestricted-policy
persistence defect found by the integrated Authentik acceptance test. The
database schema, Web Console, Orchestration Engine, Catalog, network plugins,
volumes, and deployment contract are unchanged.

## Root cause and correction

Authentication Service v0.4.38 correctly normalized an `unrestricted` policy
to an empty allowlist, but it sent the platform setting through a generated Go
model whose `value` field used `omitempty`. The empty string was consequently
removed from the HTTP request. The platform kept the previous database value,
so the public API reported `unrestricted` while a stale restricted allowlist
remained stored.

Authentication Service v0.4.39 writes the setting with an explicit map field,
so the wire request contains `"value":""`. Its regression server rejects a
request that omits the field, preventing the prior false positive in which a
Go zero value looked equivalent after decoding. The service still forces
`allowedIdentities=[]` for unrestricted access, deduplicates restricted OIDC
users and groups, rejects other identity types, suppresses provider discovery
for policy-only changes, and requires the actor-, purpose-, and request-digest-
bound one-use MFA confirmation when access is broadened.

## Immutable component coordinates

- Authentication Service `v0.4.39`, commit
  `3217b783222bcdf9a25ff0ba4a2a64a6b5e99c66`, release archive SHA-256
  `b2def9ebdf819cefa731c1b0a37c904a317d4e3d040738beef3f118f8d8d4e00`,
  and extracted binary SHA-256
  `c28e083eeefc327b3ee58208e15946dd727e77150dced61ec743c28533985dba`.
- Orchestration Engine remains `v0.183.309`, commit
  `64b94f2a5c74ebf4ca3fa3737717ac02315d1565`, artifact SHA-256
  `f0feb5285146fd7b1f9f2cc4180913c8983dbc8a0edbc996972bec880eb97dfc`.
- Web Console remains `1.6.119`, commit
  `82211b731a90cdf5d3e213ee70bff34f10f28a63`, artifact SHA-256
  `9079db43bbad557367285fdc0f75286fcf39ba54b57c7ee2adee9d4472774df7`.
- Catalog Templates remain pinned to commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (`v0.3.12`).

## Verification boundary

The Authentication Service release gate runs the complete Go test suite and
the configuration-policy suite twice. The empty-allowlist regression test now
asserts that the HTTP object contains the `value` key and that the value is an
empty string. The released archive and executable are both SHA-256 pinned,
scanned, and reverified during Server assembly.

The integrated acceptance test uses the isolated Authentik provider on the QA
Server. It signs in through OIDC and platform TOTP, saves and reads back a
restricted policy, deduplicates repeated principals, rejects an invalid
external identity type, requests an MFA confirmation for the unrestricted
transition, consumes it once through public `POST /v1-auth/config`, verifies
that both the API and database allowlists are empty, and confirms that the
policy-only update does not repeat provider discovery. The original policy is
restored after the test. This preserves the v1.6.444
`auth_config_proxy_identity=caller-platform-credential` contract.

The release pipeline rebuilds the complete image, verifies the one-layer
runtime contract, starts and restarts the candidate with fresh volumes, checks
the component inventory, generates CycloneDX SBOMs, and scans the finished
root filesystem. Publication remains blocked on any applicable Critical or
High finding, available but unapplied fix, unregistered vendor finding,
secret, checksum mismatch, or release-asset mismatch.

## Upgrade and rollback

Upgrade by changing only the image tag to `v1.6.445`, preserving the existing
environment variables, named volumes, restart policy, AppArmor policy, HTTPS
origin, OIDC settings, performance settings, and firewall architecture.
Verify `/ping`, one OIDC login, authenticated API access, and the restricted to
unrestricted policy transition before removing the previous image. Roll back
by stopping v1.6.445 and starting the preserved v1.6.444 image with the same
volumes and configuration. This patch introduces no database migration.

The release workflow records the final GHCR manifest digest and publishes it
with the release evidence. No production deployment, reverse-proxy change, or
runtime patch is part of this release.
