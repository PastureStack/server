# PastureStack Server v1.6.316

This release makes the platform account the stable authorization principal.
Local credentials and external identities are independent login links, so
changing an authentication provider no longer requires recreating the account
that owns administrator status and project memberships.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.315`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.316`
- Orchestration Engine: `0.183.270`, built with Java `25`
- Authentication Service: `0.2.4`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.28`
- Newest supported Docker Engine remains `29.6.2`.
- The reviewed Server database, bootstrap, service-authorization, and global
  subscription compatibility overlays are reapplied to the new engine package
  and verified during image assembly.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Provider switching and account ownership

An active system administrator can validate a provider and complete a real
test login before changing the active provider. The verified external identity
is matched only by its exact provider, identity type, issuer and subject.
Username and email claims are display data and are never implicit account
matching keys.

The administrator explicitly chooses whether to bind the verified identity to
the selected account or reassign an existing identity link. A reassignment can
copy direct project memberships and system-administrator status to the target.
The old account can retain its permissions, be disabled, or
discard its direct permissions and administrator status. Source sessions are
revoked.
Passwords, API keys, sessions, MFA factors, recovery codes, and audit history
are never copied to the target account.

A previously disabled matched account can be restored before its identity link
is retained. The last active system administrator cannot be disabled unless
another account retains or receives administrator access.

Provider changes keep access control enabled. Activation and local recovery use
short-lived, single-use tickets bound to the verified account and login
identity. Existing active local administrator credentials remain usable when
an external provider is unavailable. Normal local recovery remains subject to
that account's configured MFA policy. A recovery ticket claims only the login
identity it proved and the stable platform account identity; links owned by an
inactive provider are not imported into that recovery session.

Stable-account sessions import linked external identities only for the
currently active provider. After switching to local authentication, a primary
local session keeps the stable platform identity and does not depend on an
inactive OIDC alias.

Identity links, MFA status, and MFA factors can be filtered by the exact
selected account. This makes administrator review and factor maintenance
account-specific, while API resource identifiers and types remain stable for
the Web Console.

Internal service identities do not need an external identity type. Audit
attribution handles that boundary without interrupting provider-setting
writes, and still prefers a typed user identity when one is available.

## Multi-factor authentication and recovery

- RFC 6238 TOTP uses six digits, 30-second steps, limited clock skew, replay
  prevention, attempt limits, and short-lived challenges.
- WebAuthn validates the exact origin, relying-party ID, challenge, user
  presence, user verification, and authenticator backup state. It supports
  platform passkeys such as Windows Hello and phones, and roaming hardware
  security keys. The per-account passkey limit is configurable from 1 to 20.
- Recovery codes contain 96 bits of entropy, are stored only as hashes, and
  are single-use.
- Email recovery is not an MFA factor. It is an account-recovery operation that
  revokes factors and sessions, then requires fresh enrollment. SMTP
  credentials are encrypted and transport timeouts and TLS behavior are
  administrator-controlled.
- Administrators can review factor status, revoke one factor, revoke all
  factors, regenerate recovery codes, and manage verified recovery email.
- Login and administrator MFA actions bind their disabled state to the live
  request state, so a completed primary challenge immediately enables the
  selected verification action.

The implementation follows
[NIST SP 800-63B-4](https://pages.nist.gov/800-63-4/sp800-63b.html),
[WebAuthn Level 3](https://www.w3.org/TR/webauthn-3/),
[OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html),
[OAuth 2.0 Security Best Current Practice](https://www.rfc-editor.org/rfc/rfc9700.html),
and [RFC 6238](https://www.rfc-editor.org/rfc/rfc6238.html).

## Reviewed component coordinates

- Orchestration Engine source: `da4fe8cf5b0c3379a01fd680be7dd394be2fdf00`
- Orchestration Engine artifact SHA-256:
  `cdd211f4967db35edf7506adb324127ffef5b8704b4c8e8791b158bc2c08c106`
- Authentication Service source: `d71852139b024982311c2555436174a9b30240c9`
- Authentication Service artifact SHA-256:
  `5d775b71ab53b732fb8ae421b8d01f5693f02a3cbf8c54ee6bcc712aadc03de3`
- Web Console source: `eb4905c0edb60a5be3ed18f8269d1c8b8b25d6c6`
- Web Console artifact SHA-256:
  `fdbbfa0d86ff056a1047557a00d5c58e9494f9248891a271ca1119c00b009134`

The Orchestration Engine and Authentication Service packages were each rebuilt
twice from their reviewed source commit and produced byte-identical artifacts.

## Release acceptance requirements

- Every Orchestration Engine Maven module, dependency-hygiene gate, Java 25
  bytecode gate, release-archive gate, and standalone startup gate must pass.
- Authentication Service race-enabled tests, formatting, static analysis,
  Go-toolchain checks, and two byte-identical packages must pass.
- Web Console browser tests, locale and ICU checks, source gates, and two
  byte-identical production packages must pass.
- An isolated Server candidate must validate local login, exact external
  identity binding, permission reassignment with each old-account disposition,
  disabled-account restoration, failed-provider local recovery, TOTP,
  single-use recovery codes, SMTP-backed email recovery, WebAuthn registration
  and login, passkey limits, and immediate language switching.
- The formal Server endpoint must not be upgraded until the isolated candidate
  passes and all temporary containers, volumes, artifact servers, and browser
  fixtures are accounted for.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
