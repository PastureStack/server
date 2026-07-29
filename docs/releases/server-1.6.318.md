# PastureStack Server v1.6.318

This release makes the account-recovery mail boundary explicit in the console
and locks it into release acceptance. PastureStack uses one system-wide SMTP delivery configuration.
It does not create an SMTP configuration for each account.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.316`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.318`
- Orchestration Engine: `0.183.271`, built with Java `25`
- Authentication Service: `0.2.4`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.30`
- Newest supported Docker Engine remains `29.6.2`.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## System-wide outgoing email

The server already stores SMTP transport settings in one globally locked
configuration record. Only an active system administrator can read or change
the SMTP server, port, sender, credentials, TLS mode, timeouts, or verification
code lifetime. The ordinary-user API schema hides this resource and returns
`404 Not Found` for direct read or update attempts. If a privileged schema ever
routes such a request for a non-administrator, the resource manager also rejects
it with `403 SystemAdministratorRequired`.

The administration console now presents system-wide sign-in policy and SMTP
delivery before the account selector. The page states that changing the
selected account does not scope or duplicate the outgoing-email settings.

An individual account stores only its own verified recovery destination
address. Its self-service page contains no SMTP server, sender, username, or
password field and explains that delivery is centrally managed.
Email recovery is not an MFA factor: successful recovery revokes existing
factors and sessions, then requires fresh enrollment.

## Account-holder and administrator boundaries

Every signed-in account holder can open `/account/security` to register TOTP
or WebAuthn factors, manage recovery codes, verify their recovery destination,
and revoke their own factors. The platform account remains the stable authorization principal,
and exact external identity matching continues to use provider, identity type, issuer and subject.

An administrator can inspect another account and revoke its factors or
recovery material, but cannot enroll or verify a factor for that account.
Account-holder-only enrollment requests continue to fail with
`MfaAccountHolderRequired`. Provider reassignment can retain, transfer, or
discard its direct permissions without copying passwords, API keys, sessions,
MFA factors, recovery codes, or audit history.

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
  `3305a725f79f0e5e0fafb29a6944dfa10ef44ea7`
- Web Console artifact SHA-256:
  `e5b4538c116febfb50ecc55bcdd23520399fd455cc8ca6a8a70867ac2a427676`

The Web Console package must be rebuilt twice from the reviewed source commit
and produce byte-identical artifacts.

## Release acceptance requirements

- All 253 Web Console browser tests, locale and ICU checks, source gates, and
  two byte-identical production packages must pass.
- Browser acceptance must show system-wide settings before account management,
  prove that `/account/security` exposes no SMTP transport fields, and prove
  that ordinary accounts cannot read or update the global SMTP resource.
- Browser acceptance must begin a real TOTP enrollment, exercise WebAuthn
  registration and login, check passkey limits and revocation, and verify
  immediate language switching.
- Isolated candidate acceptance must use one administrator-configured fake
  SMTP service to verify a separate account's recovery address and complete
  email account recovery.
- The formal endpoint must not be upgraded until the candidate passes and all
  temporary containers, volumes, artifact servers, and browser fixtures are
  accounted for.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
