# Server v1.6.535

This patch packages immutable Engine `v0.183.349` with unchanged Web Console
`1.6.189` and the existing component set.

## Published artifact

Server producer: `6b7dca3a4d9154e37f9475e7b47d73bce26e1938`.
The normal official workflow
[38672753267](https://github.com/PastureStack/server/actions/runs/38672753267)
and immutable readback of 24 assets passed. The linux/amd64 image has one runtime
layer; its manifest is
`sha256:634613baf631d54e4cf576aeaa2f9f003b035fdfec4a28e28aa3c8f0aa38283d`.
The distinct OCI config is
`sha256:599313735f18cc95330e0bbb76bd76bd74251c8bc4f56cba019afed4a0a3fc31`.
Installation examples use the numeric `v1.6.535` tag, not a digest-pinned command.
Later documentation commits do not replace this producer.

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
tested accounts and operations, not every account, action or matrix row. On 534,
the administrator comparison covered 156 read cases; six OIDC roles used one
existing identity each, with exact visible-set/schema comparisons and bounded
owned writes or foreign-ID rejection according to live capabilities. This is
not a two-identities-per-role or whole-platform permission matrix.

On the official 535 image, ten native cases across v1 and v2-beta passed:
normal/Full compatibility, exact custom update, other-ID rejection and read-only
rejection for Stack outputs. Eight authorization/response audit pairs matched
request IDs. The two empty Stacks and three Keys were normally removed. This
does not claim native coverage of all fifteen new mappings or every API action.

QA startup and restart passed with original volumes and runtime overrides.
An actual 535 -> retained 534 -> 535 stop/start cycle used the same database and
normal session: twelve cases retained exact policy/revision/expiry and rejected
Closed and expired Keys on both API roots. It finished on ready 535 and removed
both test Keys. The expiration barrier uses the server clock; deliberately
expired authentication is rejected before successful principal headers are set.
No old database was restored. Deactivated-Key rollback and a full role/client
rollback matrix are not claimed.

The configured official external CLI `0.6.14` was also exercised without new
headers. Full and stored-null legacy Keys returned identical native `inspect`
data; each issued six HTTP 200 requests with complete audit pairs. A Closed Key
was correctly rejected by Server with 403 `KeyPolicyDenied` and a matching audit
pair, but the old CLI swallowed that error and exited zero with no output. This
is an unresolved client-reporting failure, not authorization bypass or a complete
interoperability PASS. The maintained source already fixes propagation; its
formal release remains a separate required gate. No CLI artifact or release
check was replaced, waived or declared successful by this Server release.

## Upgrade and rollback

There is no database migration. Preserve the existing Compose environment,
volumes, restart policy, AppArmor, public HTTPS origin, OIDC/MFA, performance
settings and actual firewall backend. Retain the last working image. Roll back
code without restoring old Key policy, revocation, expiry or database state.

The existing Ubuntu curl backport and precise OpenVEX decisions are unchanged.
Unfixed LOW/MEDIUM findings remain in the versioned vendor-pending tracker;
none is hidden or promoted to a HIGH waiver. The normal source, CodeQL and
final-image security gates remain required.

The first unpublished attempt was correctly rejected when the vulnerability
feed added CVE-2026-107161 for two Cyrus SASL package versions. Ubuntu lists
26.04 as [Needs evaluation](https://ubuntu.com/security/CVE-2026-107161), with
Medium vendor priority and no fixed package. Its upstream CVSS v3 score is 7.5
High. The exact versions were registered without changing packages, VEX decisions
or security thresholds. The successful final gate records 22 unfixed MEDIUM
package findings across 11 CVEs, review date 2026-10-20; zero untracked,
critical/high, fixed-available and secret findings under the existing policy.
Raw findings and the failed attempt remain evidence, not a zero-risk claim.
