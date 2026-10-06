# Server v1.6.517

Status: source candidate; immutable publication and deployment are pending.

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

The official publication workflow must verify the exact published Web artifact,
source gates, artifact scan/SBOM, disposable startup/restart and release readback
before this candidate is described as published. QA deployment and scoped
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

## Upgrade and rollback

No migration or runtime patch is required. Preserve existing environment
variables, volume names, restart policy, AppArmor, HTTPS origin, OIDC settings
and host firewall/backend selection. Retain the prior image and database/volume
backups; see [the upgrade guide](../upgrades/README.md). The install README stays
on the latest verified published image until this candidate is published.
