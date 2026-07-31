# PastureStack Server v1.6.320

This release retains the complete `v1.6.319` authentication, account,
authorization, database, catalog, and runtime changes while replacing the
embedded Web Console with the reviewed `.32` artifact.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.319`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.320`
- Orchestration Engine: `0.183.272`, built with Java `25`
- Authentication Service: `0.2.5`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.32`
- Newest supported Docker Engine remains `29.6.2`.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Web Console production correction

The Web Console now deterministically generates all 13 production locale JSON
assets from the reviewed YAML catalogs. This restores the established
lazy-loading contract used by immediate language switching and includes
Traditional Chinese. The development-only `none` locale and all source maps are
excluded from the public artifact.

When the base image already contains the reviewed Orchestration Engine,
assembly uses a revision-qualified document root instead of deleting and
recreating the same hash-named path.

The exact release source passed 265 Chromium tests. Two clean production builds
produced byte-identical packages, and every emitted locale file exactly matched
its canonical YAML source.

## Preserved security and account behavior

The platform account remains the stable authorization principal. Exact external
identity matching continues to use provider, identity type, issuer and subject.
Permission reassignment may retain, transfer, or discard its direct permissions
without copying passwords, API keys, sessions, MFA factors, recovery codes, or
audit history.

An account holder uses `/account/security` to register and verify their own
factors and recovery destination. Attempts to enroll authentication material
for another account remain rejected with `MfaAccountHolderRequired`.

PastureStack retains one system-wide SMTP delivery configuration controlled by
an active administrator; non-administrators are rejected with
`SystemAdministratorRequired`. Email recovery is not an MFA factor. The local
administrator emergency path always completes platform MFA and never creates a
password-only session.

Sensitive changes continue to require a short-lived, one-use security confirmation.
Federated MFA is trusted only with fresh signed amr, acr, and auth_time claims
that satisfy the configured policy.

The incremental credential migration preserves pre-migration credential rows.
Rollback to the previous application image does not shrink the column or discard a pending credential.

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
  `d7c6293865a9b723be345024e442a74b2412d9c1`
- Web Console artifact SHA-256:
  `56e2d089da5c52573c4fd458542ba110f558cb25b18d3846a5e3c8cdef8572e2`

## Release acceptance requirements

- All 265 Web Console browser tests, locale and ICU checks, source gates, and
  two byte-identical production packages must pass.
- Browser acceptance must prove immediate language switching and that all 13
  locale endpoints return valid JSON without missing-translation markers.
- Browser acceptance must also begin a real TOTP enrollment, exercise passkey
  registration and sign-in where the origin permits it, and expose
  `Cannot use your authenticator or passkey?` only through the recovery path.
- Isolated API acceptance must prove account-holder boundaries, administrator
  policy, one-use step-up confirmation, account lockout, session revocation,
  centralized SMTP notices, and destructive recovery behavior.
- OIDC acceptance must prove safe provider activation, exact identity matching,
  stale-claim fallback, replay rejection, and local administrator recovery.
- Database acceptance must prove `MEDIUMTEXT` credential-secret capacity,
  preserve pre-migration credential rows, and remain readable by the previous
  image used for rollback.
- The formal endpoint must remain on `v1.6.319` until an isolated `v1.6.320`
  candidate passes with a copy of the formal data. Cutover must preserve the
  exact data volumes, Docker socket, bridge networking, port `8080`, and restart
  policy while retaining an explicit rollback container.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
