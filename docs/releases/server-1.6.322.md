# PastureStack Server v1.6.322

This release retains the complete `v1.6.319` authentication, account,
authorization, database, catalog, and runtime changes while replacing the
embedded Web Console with the reviewed `.34` artifact, updating the embedded
Orchestration Engine and replacing the inherited vSphere CLI. It supersedes
`v1.6.320` and `v1.6.321`, whose Web Console runtimes were not approved for
formal deployment.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.319`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.322`
- Orchestration Engine: `0.183.273`, built with Java `25`
- vSphere CLI bundle: `0.55.1-pasturestack.1`, built with Go `1.26.5`
- Authentication Service: `0.2.5`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.34`
- Newest supported Docker Engine remains `29.6.2`.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Web Console runtime correction

The Web Console restores the compatible Ember runtime required by the existing
application, keeps the login action and API error collection APIs operational,
and always dismisses the initial loading overlay after a completed transition.
It also replaces the browser-bundled Lodash 3 runtime with Lodash 4.18.1 and
updates Shell Quote, Dagre, Graphlib, and WebSocket Driver without adopting the
incompatible Ember 7 runtime.

All light, dark, left-to-right, and right-to-left theme stylesheets are emitted
and checked as non-empty release assets. Server assembly removes the previous
managed Web Console asset tree before extracting the reviewed artifact, so
obsolete hashed chunks cannot survive an upgrade.

The exact release source passed 260 Chromium tests. Two clean production builds
produced byte-identical packages, all 13 locale files matched their canonical
YAML sources, and isolated browser acceptance proved immediate switching
between English and Traditional Chinese.

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

The Orchestration Engine uses Spring Framework `6.2.19`; the release gate
rejects earlier Spring Expression artifacts. Its clean-start database test and
the production migration check both preserve the checksum of the already
executed historical change set while applying the database-specific precondition
only to MySQL, MariaDB, and PostgreSQL.

The vSphere CLI is built from the recorded upstream source with
`golang.org/x/text` `0.39.0`. The Server image verifies the bundle layout,
archive hash, executable hash, build metadata, source record, and retained
Apache and MIT notices before replacing the inherited executable.

## Reviewed component coordinates

- Orchestration Engine source:
  `4d4fabd48a8f4e765159376a574d82564111bc69`
- Orchestration Engine artifact SHA-256:
  `a1df27686239a7251b205f5d7419ccb277f760f6b2b62b920ba23fe20028ad43`
- vSphere CLI bundle source:
  `b819a7eec35bb8c157547c0d541d271908661109`
- vSphere CLI bundle artifact SHA-256:
  `64a2cdf22aa8762c52808315726f19e2970cd1deb86172ca5d611b2943fd2788`
- govmomi source:
  `a668d9c60399552ea96782b8751c956720a0b8fb`
- govc executable SHA-256:
  `4a4766667d710148cdab058f2aba65c5ff3e886758bb4a0cd021e05034b96fb2`
- Authentication Service source:
  `62726c0b03b64848ff9d0e1d8ff5e965007efe61`
- Authentication Service artifact SHA-256:
  `109e293092260d788acb3d7fcf4d78cccdf72c268d1728f263efc4075a69241c`
- Web Console source:
  `629f9935f2544583f0768115f60306039dadd0b2`
- Web Console artifact SHA-256:
  `f001ce909cdf1e9d9ec155f3a6215c7ec4a6b0600b3420a5dc42534640131ca9`

## Release acceptance requirements

- All 260 Web Console browser tests, locale and ICU checks, source gates, and
  two byte-identical production packages must pass.
- Browser acceptance must prove immediate language switching, non-empty theme
  styles, a dismissed loading overlay, and 13 valid locale endpoints.
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
- The formal endpoint must remain on `v1.6.319` until an isolated `v1.6.322`
  candidate passes with a copy of the formal data. Cutover must preserve the
  exact data volumes, Docker socket, bridge networking, port `8080`, and restart
  policy while retaining an explicit rollback container.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
