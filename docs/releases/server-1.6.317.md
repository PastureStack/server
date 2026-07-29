# PastureStack Server v1.6.317

This release completes account-holder multi-factor authentication self-service.
It corrects the previous release acceptance scope, which verified the MFA APIs,
login challenge, and administrator view but did not verify that a signed-in
account holder could manage their own sign-in security from the account list.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.316`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.317`
- Orchestration Engine: `0.183.271`, built with Java `25`
- Authentication Service: `0.2.4`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.29`
- Newest supported Docker Engine remains `29.6.2`.
- The reviewed database, bootstrap, service-authorization, and global
  subscription compatibility overlays are reapplied to the new engine package
  and verified during image assembly.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Account-holder sign-in security

Every signed-in account holder has a **Sign-in security** entry in the user
menu. System administrators also see **Manage my sign-in security** on
`/admin/accounts`. Both links open the root-scoped `/account/security` page for
the current account.

The account holder can:

- enroll an RFC 6238 authenticator with a locally generated QR code or the
  displayed manual secret, then confirm the six-digit code;
- register WebAuthn credentials, including platform passkeys such as Windows
  Hello and phones as well as roaming hardware security keys;
- generate a fresh set of single-use recovery codes after at least one TOTP or
  WebAuthn factor exists;
- copy newly generated recovery codes during the one display opportunity;
- begin, confirm, replace, or remove a verified SMTP recovery address when the
  administrator has enabled SMTP; and
- review and revoke their registered factors.

The passkey limit remains configurable from 1 to 20 and defaults to 5.
Recovery codes contain 96 bits of entropy, are stored only as hashes, and are
single-use. TOTP uses six digits, 30-second steps, limited clock skew, replay
prevention, short-lived challenges, and attempt limits.

The QR image is generated in the browser from the already displayed enrollment
secret. It is not sent to an external QR service.

## Administrator boundary

An administrator may open another account from `/admin/accounts` to inspect
its MFA status, revoke one factor, revoke all factors, reset enrollment, or
remove a recovery address. An administrator cannot register or confirm TOTP,
register or confirm a passkey, verify a recovery address, retrieve recovery
codes, or regenerate recovery codes for another account.

Those account-holder-only API operations return `403` with
`MfaAccountHolderRequired` when the authenticated account does not own the
target account. This prevents an administrator session from silently creating
an authentication factor that the administrator controls.

Email recovery is not an MFA factor. It is an account-recovery operation that
revokes factors and sessions, then requires fresh enrollment. SMTP credentials
are encrypted, and transport timeouts and TLS behavior remain
administrator-controlled.

## Provider switching and stable accounts

The platform account remains the stable authorization principal. Local
credentials and external identities are independent login links. Exact
external identity matching uses provider, identity type, issuer and subject;
username and email claims remain display data rather than implicit matching
keys.

An administrator can validate a provider and complete a real test login before
activation. Reassignment can copy direct project memberships and
system-administrator status. The old account can retain its permissions, be
disabled, or discard its direct permissions and administrator status.
Passwords, API keys, sessions, MFA factors, recovery codes, and audit history
are never copied.

Local administrator recovery remains available when an external provider is
unavailable and remains subject to that account's configured MFA policy.

## Reviewed component coordinates

- Orchestration Engine source:
  `5de92536c6547c24ca9d06087e2e9722eddd9c07`
- Orchestration Engine artifact SHA-256:
  `82b378c87da4c835f4417a858d3a75d998a499a3515c436c4f769b5ee3091787`
- Authentication Service source:
  `d71852139b024982311c2555436174a9b30240c9`
- Authentication Service artifact SHA-256:
  `5d775b71ab53b732fb8ae421b8d01f5693f02a3cbf8c54ee6bcc712aadc03de3`
- Web Console source:
  `ef9630683e62a313d9db892dde721c428bf3ae06`
- Web Console artifact SHA-256:
  `0bc42f6dc8eee44ef127bbef2670af8f4a61e361f33c632380374e69c143b4d2`

The Orchestration Engine and Web Console packages were each rebuilt twice from
their reviewed source commit and produced byte-identical artifacts.

## Release acceptance requirements

- Every Orchestration Engine Maven module, dependency-hygiene gate, Java 25
  bytecode gate, release-archive gate, and standalone startup gate must pass.
- Web Console browser tests, locale and ICU checks, source gates, and two
  byte-identical production packages must pass.
- The assembled image must contain the account-holder authorization marker,
  recovery-email enrollment availability schema, root account-security route,
  self-service UI marker, and Traditional Chinese self-service text.
- Browser acceptance must start at `/admin/accounts`, open the current user's
  sign-in security page, verify the status and enrollment controls, begin a real TOTP enrollment,
  display both the QR code and manual secret, and cancel the enrollment cleanly.
- Browser acceptance must provision an isolated Chromium virtual
  authenticator, register a WebAuthn passkey through the real browser API,
  display the newly generated recovery codes once, sign out, and complete a
  new login with that same passkey.
- Browser acceptance must open another account's administrator view and prove
  that an account-holder-only enrollment request is rejected with
  `MfaAccountHolderRequired`.
- Candidate testing must additionally validate TOTP login, single-use recovery
  codes, SMTP-backed recovery, WebAuthn registration and login, passkey limits,
  revocation, immediate language switching, and failed-provider local recovery.
- The formal endpoint must not be upgraded until the isolated candidate passes
  and all temporary containers, volumes, artifact servers, and browser fixtures
  are accounted for.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
