# Server v1.6.517

Status: officially published; scoped isolated-QA deployment/browser checks passed.

Immutable image:
`ghcr.io/pasturestack/server:v1.6.517@sha256:2bf411c5828b7090f9dab950942befcc22295c7dce9a5db2e3d2d6c9dfd2f7d8`.
Signed Server source/tag: `352f1097c002224e84a1719a0df50e4ae4a1219a`.
Image config digest: `sha256:2240353892f9b98cd4b9b1a36ef127092b9124b6f025076c59bd5e3a003ab1d7`
(not the registry manifest digest).

## Scope

Packages Web Console `1.6.179`, including the merged dependency updates and the
official shell-quote `1.11.0` security fix (CVE-2026-102422). Both the installed
dependency and the browser vendor copy are updated. The current command-field
caller only parses; catalog previews quote one answer at a time. Those callers
do not establish the advisory's comment-followed-by-another-token exploit path.
The affected library is nevertheless removed from the shipped console.

No authentication, authorization, OIDC, MFA, API or firewall behavior is changed.
The existing generation/mutex and session-bound logout protection is retained.
Orchestration Engine `v0.183.333`, Catalog Service `0.20.12`, the other component
pins, four build stages and the single final runtime layer remain unchanged.

The publication gate now checks the concise README's current release and exact
immutable install reference against versioned release/compatibility records.
Historical evidence remains in those records instead of being duplicated in
the README. Stale tags, digest mismatches and suffixes are still rejected.

## Verification

Web Console source `826bff55b8885efc9ff1faec0272ef442e4ff702` passed
[formal CI 37502593612](https://github.com/PastureStack/web-console/actions/runs/37502593612):
851 tests, zero failures/skips/todos, and two byte-identical production archives.
The 2,987,712-byte archive SHA256 is
`1bb7e0acf7040738f2c6413046553609cbbaf14b833abb6ef2c7237b453eaf90`.
This is component evidence, not a claim of Server deployment success.

[Official publication run 37505065403](https://github.com/PastureStack/server/actions/runs/37505065403)
passed exact component verification, 56 source gates, artifact scan/SBOM,
disposable startup/restart (12/7 bounded probes), 34 MFA/API checks and release
readback. An independent anonymous download/checksum and registry manifest hash
readback also agrees. Final scan: 53 raw findings, 51 retained VEX statements,
nine vendor-pending Medium package findings / five CVEs; untracked,
Critical/High, available-fix and secret findings are zero. QA deployment and
browser checks are separate and are not inferred from image publication.

Existing vendor-pending findings and review deadlines are not reset. Publication
does not mean zero CVEs or completion of the historical resource/role/hardware
matrix; earlier HOLD and untested hardware evidence remains unchanged.

The first publication attempt, run 37503831627, correctly stopped before image
publication when the live scan added Medium `CVE-2026-46675` for Ubuntu
`libpng16-16t64` `1.6.57-1`. [Ubuntu's current record](https://ubuntu.com/security/CVE-2026-46675)
lists resolute's libpng1.6 as vulnerable without a released fixed version.
The exact finding is tracked with the existing 2026-10-20 review deadline;
Critical/High, available-fix, secret and exact-set checks are unchanged. The
candidate contains nine unresolved package findings across five CVEs, not zero.

## Scoped QA deployment and browser acceptance

The isolated operator QA host was updated to the exact published manifest and
source above. First start and one restart passed HTTP 200/pong after 11/9 bounded
probes. Runtime configuration, environment overrides, named volumes and five
core-table counts remained unchanged; the prior 516 container and database
backup were retained. The image has no Docker Healthcheck (`health=null`), so
this is application-ping evidence, not a claim of Docker health status.

A real Chrome login using the existing local OTP EXE passed Authentik TOTP and
platform TOTP. Token, schemas, projects, userpreferences and settings each
returned 200; two WebSockets connected, passive token DELETE count was zero,
explicit logout sent one DELETE, and JWT was absent from Web Storage. The
existing browser diagnostic gate passed. The actual loaded vendor rejected
all four hostile line-terminator cases and preserved three legitimate
round-trips. Host receipts and screenshots are retained locally rather than
committed to this public repository.

The company production site, proxy, OIDC settings and host firewall were not
modified. This dependency/release verification does not rerun or complete the
historical full role/resource/hardware matrix.

## Upgrade and rollback

No migration or runtime patch is required. Preserve existing environment
variables, volume names, restart policy, AppArmor, HTTPS origin, OIDC settings
and host firewall/backend selection. Retain the prior image and database/volume
backups; see [the upgrade guide](../upgrades/README.md). The install README pins
the verified published image above; existing named volumes must be retained.
