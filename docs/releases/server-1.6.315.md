# PastureStack Server v1.6.315

This release completes transactional OpenID Connect activation and
local-authentication recovery while retaining every compatibility and user
interface change from v1.6.314.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.314`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.315`
- Authentication Service: `0.2.3`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.27`
- Newest supported Docker Engine remains `29.6.2`.

The active platform provider is canonical when Authentication Service reloads
configuration. A remembered external provider can no longer override an active
local provider or make the authentication service depend on an inactive
provider's discovery endpoint.

During activation, the proposed OpenID Connect configuration is first saved
while global security remains disabled. The Web Console suspends the old
provider cookie, exchanges a fresh authorization code, and enables security
only after the new platform session exists. If the exchange fails, the prior
provider is restored before the original administrator session is returned.

## Reviewed component coordinates

- Authentication Service source:
  `88297439772a3a99e1c9ead6fbd2b04ab6da75fd`
- Authentication Service artifact SHA-256:
  `b3b08e2d30682ea0e7fdff6ade1473bfdb6c95e49fe267a839339bf6b94e8fc6`
- Web Console source:
  `51808b142371f841e4ea2196c29d4b11f867ee71`
- Web Console artifact SHA-256:
  `ce722ec55bea49e5186aa8b6766ce45dfd2ca78ff5879d5f5c813a7190de511e`

## Validation

- Authentication Service race-enabled tests, formatting, and static analysis
  must pass before its release is published. Its compiler and binary must both
  report Go `1.26.5`, and the released binary must have zero actionable
  HIGH/CRITICAL vulnerabilities and zero detected secrets.
- Web Console browser tests, locale parity and ICU checks, source gates, and
  two byte-identical production builds must pass.
- All Server source gates must pass.
- Two independent no-cache Server builds must produce the same image.
- Live validation must prove successful test login, controlled failed
  activation with automatic local-provider and administrator-session
  restoration, successful activation, and final local-authentication recovery.

Operational image coordinates use semantic version tags. Artifact and image
hashes are release evidence and are not written into user-facing image fields.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
