# Server v1.6.498

Source assembly candidate; not yet published or deployed. No immutable Server
digest or packaged browser acceptance is claimed until the normal publisher
and QA gates complete. Current QA remains v1.6.497.

This patch consumes Orchestration Engine v0.183.329 to close GenericObject
capability reads by readonly/restricted roles. It uses the existing role-schema
boundary, including the actual frozen v1 schemas; it does not special-case a
plugin or change stored Receiver configuration. Owner/member/service clients
retain storage access. Low-role opaque GenericObject consumers must use the
authorized typed plugin API, which retains safe configuration and hides URLs.

Web Console 1.6.164 and Webhook Automation Service 0.10.3 stay unchanged. The
runtime base, Compose, three named volumes, AppArmor, nftables, OIDC, MFA,
session ownership, database schema and stored data remain unchanged.

Engine v0.183.329 is officially published from CI source
`14e3f0919a33282ff3026c364182f715f5dda634`; its exact WAR SHA-256 is
`9f8e5736898b6d9c51cb96d5f7cdbe8e3831a29ce296909108f5f2d5a68f7ec4`.
The normal build executed 266 suites / 1,123 tests with zero failures, errors
or skips, including four response/overlay cases plus two actual frozen-v1
cases. Build/security and CodeQL gates passed, and the exact CI WAR completed
isolated JDK 25.0.3 / H2 startup with no platform data or network.
The producer verifies only the intended two fields
change in GenericObject and inherited Register snapshots; unrelated contracts
remain identical. Server assembly checks exact WAR and both low-role frozen
schema hashes. Packaged Server role/browser proof remains a separate gate.

The first Server publisher [run `36953191960`](https://github.com/PastureStack/server/actions/runs/36953191960)
failed its security gate after official fixes became available for
[CVE-2026-42772](https://ubuntu.com/security/CVE-2026-42772) and
[CVE-2026-54873](https://ubuntu.com/security/CVE-2026-54873): two Low CVEs across
three OpenSSL packages, or six package findings. That failed run is retained.
This unpublished correction selects official Ubuntu 26.04 package
`3.5.5-1ubuntu3.7` from the signed HTTPS `20261002T000000Z` snapshot. The existing
whole-package install, SHA-256 checks and exact runtime versions remain required.
Only those two CVEs leave vendor-pending; the other four CVEs / eight Medium
package findings and their `2026-10-20` review date are unchanged. No VEX or
fixed-available/security threshold is relaxed. A new publisher/security run and
packaged QA are still required; this source correction is not a release PASS.

The QA497 reproduction used restricted account 1a2512/project 1a2540 to read an
owner-created inert Receiver through v1 GenericObject. No execution endpoint
was called. The historical HOLD remains HOLD, and its fixture was normally
deleted by the verified original owner. No claim of all-role/all-resource,
all-language/full-layout or company-site acceptance is made.

No migration or runtime patch is required. Preserve the v1.6.497 image and
original configuration/volumes for rollback, but note that rolling back restores
the low-role capability exposure. Remaining pending vendor findings and security
thresholds are retained; this release does not claim zero findings of every
severity.
