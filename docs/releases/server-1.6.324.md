# PastureStack Server v1.6.324

This release retains the complete `v1.6.323` authentication, account,
authorization, database, catalog, runtime, Orchestration Engine, and vSphere
CLI behavior while replacing the embedded Web Console with the reviewed `.36`
artifact.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.319`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.324`
- Orchestration Engine: `0.183.273`, built with Java `25`
- vSphere CLI bundle: `0.55.1-pasturestack.1`, built with Go `1.26.5`
- Authentication Service: `0.2.5`, built with Go `1.26.5`
- Web Console: `1.6.56-pasturestack.36`
- Newest supported Docker Engine remains `29.6.2`.

Operational image coordinates use semantic version tags. Artifact hashes are
release evidence and are not written into user-facing image fields.

## Restricted Bootstrap runtime boundary

The Web Console no longer ships the aggregate Bootstrap JavaScript runtime.
Only the reviewed transition, collapse, and dropdown modules remain because
those are the Bootstrap behaviors used by the application. Button, Tooltip,
and Popover runtime plugins are excluded, and obsolete Bootstrap data APIs are
rejected by source, package, and Server-image gates. This removes the reachable
runtime paths associated with the reviewed Bootstrap Button and Tooltip or
Popover advisories without changing existing navigation behavior.

Server assembly independently requires `bs.collapse` and `bs.dropdown` in the
embedded vendor bundle and rejects `bs.button`, `bs.tooltip`, `bs.popover`, or
`data-loading-text`. Bootstrap-derived Sass remains a documented migration debt;
this release does not claim that the style dependency has been removed.

The exact Web Console release source passed 261 Web Console browser tests,
all 13 locale checks, Node.js 24 verification, and two byte-identical production
builds. Its packaged artifact also passed the same positive and negative
Bootstrap runtime checks before Server assembly.

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
  `b17901d02b51df462dfd55810193fdb595af5106`
- Web Console artifact SHA-256:
  `bab18039ee378d9afc63421db33f52bc685ff993e0c5dbddd21b4526752347f1`

## Release acceptance requirements

- All 261 Web Console browser tests, locale and ICU checks, source gates, and
  two byte-identical production packages must pass.
- Browser acceptance must prove immediate language switching, non-empty theme
  styles, a dismissed loading overlay, 13 valid locale endpoints, and a 200
  response for `/favicon.ico`.
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
- The formal endpoint must remain on `v1.6.323` until an isolated `v1.6.324`
  candidate passes with a copy of the formal data. Cutover must preserve the
  exact data volumes, Docker socket, bridge networking, port `8080`, and restart
  policy while retaining an explicit rollback container.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
