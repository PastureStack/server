# Server v1.6.442

PastureStack Server v1.6.442 carries forward the cross-tab authentication and
OIDC site-access policy fixes from v1.6.441, and corrects the public release
evidence contract discovered during post-publication readback.

## Runtime composition

- Web Console `1.6.118`, commit
  `63ff73bc26103ab32de5ba30768391caa3af9f6a`; release archive SHA-256
  `4ffbfcb787ca28651a7dcb59e294bd236d5d1a35a0087ec33a3f375ecd1b51b4`.
- Orchestration Engine `v0.183.303`, commit
  `accb664b674fd0391e858bfd9a7748641e6440ab`; release JAR SHA-256
  `6b26237379fca106500dedf310bb7d43c09a25e08c0ff421a0b3468d6e4a647b`.
- Authentication Service `v0.4.37`, commit
  `48c3f9e850b4f91f8ea8ee78bf7c3b206464a4cb`; release archive SHA-256
  `5f749bc205443c27d696523ad470242365061bb25ab79fd1a09a1510465dbfa6`;
  extracted binary SHA-256
  `11a61ce9c85350207374b1552dd60a0b44c87bea1a8727925ff5c286b8f3f47f`.
- Catalog remains pinned at commit
  `e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates
  `v0.3.12`).

## Browser session ownership

The Web Console keeps a high-entropy generation per successful login, captures
it for asynchronous work, and uses one fail-closed cross-tab mutex for login
commit and explicit logout. Passive authentication failures can reconcile or
stop stale work but cannot revoke the current server token. Other same-origin
tabs validate and adopt the committed session without storing JWTs in Web
Storage, URLs, or logs.

## OIDC site-access policy updates

Authentication Service separates identity-source changes from policy-only
updates. Existing OIDC providers can save access policy without repeating
discovery or requiring fresh local recovery; unrestricted access clears the
allowlist, restricted identities are validated and deduplicated, and access
expansion consumes an actor-, purpose-, and request-digest-bound one-use MFA
confirmation. Initial enablement and identity-source changes retain the local
recovery and provider-initialization requirements.

## Server-side compatibility guard

New tokens are bound to the client session generation. A bound explicit logout
must present the matching session identifier; missing, mismatched, stale, or
repeated deletes are idempotent and cannot expire a newer cookie. Legacy
unbound tokens retain their established behavior.

## Release evidence correction

The v1.6.441 `SHA256SUMS` file included `server-secrets.tsv`, while GitHub
Releases rejects zero-byte assets. The security gate correctly required that
file to be empty, but the publication command intentionally did not upload it,
leaving the checksum manifest and public asset set inconsistent.

v1.6.442 keeps the zero-byte file as internal workflow evidence and excludes it
from the public checksum manifest. Publication now reads the complete public
asset list back from GitHub and compares every asset name and API-reported
SHA-256 digest with the generated manifest. Any missing, extra, or mismatched
asset fails the workflow.

## Security and compatibility boundaries

- JWT, OTP, OIDC codes, and session secrets are not written to Web Storage,
  URLs, or logs.
- Passive 401/403, storage, WebSocket, timer, and route events do not revoke a
  server token. Only an explicit user logout may issue the bound DELETE.
- Existing unbound legacy tokens retain their compatibility behavior.
- OIDC access-policy-only updates do not repeat discovery or require a fresh
  local-recovery window. Identity-source changes still do.
- The release does not weaken cookie, CSRF, Origin, MFA, Passkey, AppArmor, or
  nftables behavior and does not require an HAProxy or runtime patch.

## Validation required by the publication workflow

- Exact clean-source and immutable component-coordinate gates.
- Full source contract suite, including deterministic cross-tab race and OIDC
  access-policy contracts.
- Candidate startup, restart, reverse-proxy HTTPS-origin and private-cache
  checks.
- v1/v2 hardware API and MFA/policy API smoke tests.
- Finished-rootfs vulnerability, secret, CycloneDX, OpenVEX, and
  vendor-pending gates.
- Registry digest, one-layer runtime image, provenance/SBOM attestations, and
  exact public-release asset manifest readback.

## Upgrade

Back up the database and all three existing named volumes. Update only the
Server image reference to the immutable v1.6.442 digest and retain the current
environment variables, named volumes, `restart: always`, AppArmor profile,
public HTTPS origin, OIDC settings, performance settings, and firewall mode.
Verify `/ping`, authenticated API reads, WebSocket reconnect, TOTP and Passkey
login, cross-tab adoption, explicit logout, and OIDC access-policy persistence.

## Rollback

Keep the prior immutable image and backup checkpoint until acceptance is
complete. If rollback is necessary, restore the previous image reference with
the same Compose configuration and named volumes. Restore the database/volume
checkpoint only when a data rollback is explicitly required. No production
deployment is part of this release workflow.
