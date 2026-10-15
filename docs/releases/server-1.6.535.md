# Server v1.6.535

This patch packages immutable Engine `v0.183.349` with unchanged Web Console
`1.6.189` and the existing component set.

## Scoped API Key action repair

Fifteen exact persisted-resource/action pairs are registered centrally, including
Stack outputs and Service continue-upgrade. Queued custom-Key work rechecks the
same resource type and original operation. Owner authority, ancestry, explicit
deny, revision and expiration checks remain in place. Full and legacy Keys keep
the normal authorization path; unsupported multi-target and security/delegation
operations remain fail-closed. No authorization implementation is copied into
plugins.

Engine producer: `0733430fac11892a17ba53749fe02d99d26b1f52`.
`cattle.jar` SHA-256:
`6e61f05598c12941c3b07ebfcf81f40e7fb1bd5439ec4c7d9c34484306378f04`.
The normal required checks, signed merge, original release packager, tested-class
byte comparison and anonymous immutable component readback passed. The focused
Engine suite passed 150 cases without replaying unrelated suites.

## Acceptance boundaries

The previous Server's normal-vs-Full/legacy read comparison and six-role OIDC
normal-vs-Full checks are carried as their original evidence. They cover the
tested accounts and operations, not every account, action or matrix row. Native
packaged action acceptance, official final-image security checks, deployment and
rollback are separate gates; component publication alone does not prove them.

## Upgrade and rollback

There is no database migration. Preserve the existing Compose environment,
volumes, restart policy, AppArmor, public HTTPS origin, OIDC/MFA, performance
settings and actual firewall backend. Retain the last working image. Roll back
code without restoring old Key policy, revocation, expiry or database state.

The existing Ubuntu curl backport and precise OpenVEX decisions are unchanged.
Unfixed LOW/MEDIUM findings remain in the versioned vendor-pending tracker;
none is hidden or promoted to a HIGH waiver. The normal source, CodeQL and
final-image security gates remain required.
