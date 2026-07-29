# PastureStack Server v1.6.319

This release makes multi-factor authentication follow a conventional sign-in,
enrollment, recovery, administration, and federation workflow. It also prevents
an unavailable external identity provider from locking every administrator out
without creating a password-only recovery path.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.318`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.319`
- Orchestration Engine: `0.183.272`, built with Java `25`
- Authentication Service: `0.2.5`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.31`
- Newest supported Docker Engine remains `29.6.2`.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Conventional sign-in and recovery workflow

The normal sign-in path completes the configured password or external-provider
step first, then accepts an enrolled authenticator application or passkey. A
browser session is not created until both required steps have completed.

When policy requires enrollment, the account registers and verifies an
authenticator application or passkey before the first session is created. New
recovery codes are displayed once and stored only as one-way hashes.

Daily authentication presents registered factors first. Recovery codes and
verified-email account recovery are behind the explicit
`Cannot use your authenticator or passkey?` path. Email recovery is not an MFA factor.
Successful email recovery revokes existing factors and sessions and requires
fresh enrollment. PastureStack uses one system-wide SMTP delivery configuration
controlled by an active system administrator; accounts store only their own
verified recovery destination.

## Administrator policy and account boundary

An active system administrator can configure whether MFA is optional, required
for administrators, or required for every account. The same policy surface
controls the passkey limit, maximum failed attempts, account lockout duration,
step-up lifetime, WebAuthn relying-party values, passkey counter handling,
federated-MFA trust, security-notice locale, and the system-wide SMTP service.
Non-administrators cannot read or change global settings and are rejected with
`SystemAdministratorRequired`.

The global policy and SMTP configuration is one updateable settings resource.
Changing one field preserves every omitted field, so an independent locale or
policy change cannot reset the shared mail service or another security control.

OIDC sign-in can produce an encrypted, short-lived pending-login payload larger
than the historical credential limit. A new incremental database migration
expands only `credential.secret_value` to `MEDIUMTEXT`; it leaves the historical
baseline change set intact and preserves existing rows. Application rollback to
the previous server remains compatible with the expanded column and
does not shrink the column or discard a pending credential.

An account holder uses `/account/security` to register and verify their own
factors and recovery destination. An administrator can inspect or revoke another account's
authentication material but cannot enroll a factor, verify a recovery address,
or retrieve recovery codes for that account. Such attempts are rejected with
`MfaAccountHolderRequired`.

Adding or replacing factors, regenerating recovery codes, changing a recovery
address, changing global policy, and administrator resets require a short-lived,
one-use security confirmation from an already enrolled factor. Account-level
failed-attempt throttling persists across newly created login challenges so a
new challenge cannot reset the counter. Changes affecting account access or
recovery material revoke affected sessions; ordinary factor registration keeps
the current setup session. A security notice is sent when the centralized mail
service is available.

The platform account remains the stable authorization principal. Exact external
identity matching continues to use provider, identity type, issuer and subject.
Permission reassignment may retain, transfer, or discard its direct permissions
without copying passwords, API keys, sessions, MFA factors, recovery codes, or
audit history.

## Federated MFA and emergency local administration

The default federated policy requires PastureStack MFA after external sign-in.
An administrator may instead trust an upstream provider only when it supplies
fresh signed amr, acr, and auth_time claims matching the configured allow-list
and maximum age. Missing, stale, unsigned, or untrusted claims fall back to the
platform MFA challenge.

Before an external provider can become active, PastureStack verifies a current
password for an active local system administrator that already has an
authenticator application or passkey. The resulting readiness proof is accepted
for five minutes and is not stored in the provider configuration.

If the external provider later becomes unavailable, only an active local system
administrator can select the emergency path. The administrator must supply the
local password and always completes platform MFA, even when the global policy
would otherwise be optional. Provider-switch tickets cannot bypass an enrolled
factor, and the emergency path never creates a password-only session.

## Reviewed component coordinates

- Orchestration Engine source:
  `336d48b1104593d4fc28311944824b9b421fe4dd`
- Orchestration Engine artifact SHA-256:
  `95073ce4ed95c0d23c675e012fc6c62b6889a09cd449c5db5a79bd8c42aea388`
- Authentication Service source:
  `62726c0b03b64848ff9d0e1d8ff5e965007efe61`
- Authentication Service artifact SHA-256:
  `109e293092260d788acb3d7fcf4d78cccdf72c268d1728f263efc4075a69241c`
- Web Console source:
  `c4dcfecd8c821044e85d53b661225b656cc64625`
- Web Console artifact SHA-256:
  `0ccf8baa15a91850670030256f3ee005abe35e08874b067c80d59e873e12f7c0`

Each component package must be rebuilt twice from the reviewed source commit and
produce byte-identical artifacts.

## Release acceptance requirements

- All 258 Web Console browser tests, locale and ICU checks, source gates, and
  two byte-identical production packages must pass on the Linux candidate path.
- Browser acceptance must prove the ordinary factor-first flow, the separate
  account-recovery path, begin a real TOTP enrollment, complete WebAuthn
  registration and login, display one-time recovery codes, exercise
  administrator policy controls, and switch languages immediately.
- Isolated API acceptance must prove that every administrator policy field and
  every step-up operation is present in the published API schema, persists
  through save and reload, and remains hidden from non-administrators. It must
  also prove account-level lockout across new challenges, one-use step-up
  confirmation, account-holder boundaries, session revocation, centralized
  SMTP notices, and destructive email recovery.
- OIDC acceptance must prove the platform default, accepted fresh trusted
  claims, stale and missing claim fallback, safe provider activation, provider
  switch replay rejection, and an unreachable provider followed by successful
  local administrator password and MFA sign-in.
- Database acceptance must prove that the incremental migration produces a
  `MEDIUMTEXT` credential-secret column, preserves pre-migration credential rows,
  and remains readable by the previous application image used for rollback.
- The formal endpoint must remain on the previous image until the isolated
  candidate passes. Cutover must preserve the exact data volumes, Docker socket,
  bridge networking, port `8080`, and restart policy, and must retain an explicit
  rollback path.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
