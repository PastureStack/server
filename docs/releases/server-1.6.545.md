# Server v1.6.545

Service upgrade and endpoint identity correction.

Server `v1.6.545` is published from official source
`858ec54df70b8089ef900a16bed1287d94e7f692`.
[Publisher 39893305304](https://github.com/PastureStack/server/actions/runs/39893305304)
completed successfully, and all 26 immutable release assets passed checksum
verification. The manifest is
`sha256:f79279d9d00d0301353663e000dc41b1ed49efe45e4ed878e03d1207cfea2a44`;
the distinct OCI config is
`sha256:6fc2e01d80288d65991b3886cea5390395a754f3d22e3a9acd1576007f62ec6a`.
The linux/amd64 image has one runtime layer, 516,540,955 compressed bytes.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.545@sha256:f79279d9d00d0301353663e000dc41b1ed49efe45e4ed878e03d1207cfea2a44`.

The QA installation now runs this exact image. Its first health check and an
actual Server restart passed with the same three persistent volumes, operator
overrides, restart policy and AppArmor profile. The previous container/image
and a verified consistent pre-upgrade database dump remain available.

The Engine component is now published as
[v0.183.353](https://github.com/PastureStack/orchestration-engine/releases/tag/v0.183.353).
Its tested producer is `e094944cd81da614187dbeba1f06354682af1d45`, with jar
SHA256 `d0a353b40b8b9f739ddd30b9ccae6fbf3ca64d45547cd95e9194aad738538f40`.
The original CI bytes passed anonymous release download verification. Both
frozen readonly/restricted schemas match the prior assembly.
[Engine CI 39804958880](https://github.com/PastureStack/orchestration-engine/actions/runs/39804958880)
passed 3,372 tests with zero failures/errors and one intentional platform skip;
the endpoint suite passed all 26 cases without skips.

## Corrected behavior

[Web Console 1.6.193](https://github.com/PastureStack/web-console/releases/tag/1.6.193)
completes 2,519 missing policy/matrix/audit translations
across 11 locales. Its original full CI passed 1,104 browser tests without
failures or skips and produced two identical static archives
([CI 39890788296](https://github.com/PastureStack/web-console/actions/runs/39890788296)).
The tested producer is
`fa7fd399e3aef2a67282e8fbbe9f3fc83002710d`, with archive SHA256
`07dd68dddecec1d95c6932d4dd31084401ee67d517fb820ecbbe6afaa052a888`.
The browser test image includes CJK and Arabic-script fonts; no product layout
assertion or localization fallback exception was relaxed.

The Web Console service-upgrade path previously performed a generic service
save before sending the upgrade action. That save could return HTTP 422 when
the clone contained a derived `publicEndpoints` entry for a removed instance.
Service upgrades now retain the normal validation/preflight and shared saving
lifecycle, but wait for the upgrade action and send its strategy directly.
Ordinary create/edit persistence is not changed.

The Engine previously compared public endpoints using only address and port.
Replacing an instance while retaining its address/port could therefore leave
the old instance reference in the service. The comparison now uses an
order-independent set of address, port, service, host and instance identities.
Reordering an identical set does not write it again. Reference validation is
not relaxed, and removed resources do not become valid references.

The CA bootstrap package download uses the official locked Ubuntu snapshot
after the moving archive removed the pinned version. Its package version and
SHA256 remain identical, verified against the signed snapshot package index.
The source gate requires that exact snapshot and checksum in all three Server
recipes; this is a source availability repair, not a dependency downgrade or
an exception to the artifact security gate.

## Acceptance boundary

The fresh runtime scan also identifies `CVE-2026-88648` on
`libgnutls30t64` `3.8.12-2ubuntu1.1`. Canonical marks Ubuntu 26.04 as
vulnerable with a deferred fix, and its official OSV data has no fixed version.
This Medium finding is recorded for review on 2026-10-27, not suppressed or
claimed as fixed. The final merged-rootfs-and-active-payloads gate reports 74
raw findings; the exact-match pending register contains 30 unfixed LOW/MEDIUM
package occurrences across 19 CVEs. HIGH/CRITICAL, fixed-available, untracked
findings and secrets are all zero. These categories still block release;
tracking is not remediation or zero risk. See the
[official status](https://ubuntu.com/security/CVE-2026-88648).

The stale-endpoint regressions and complete Web Console and JDK 25 Engine test
suites passed. A real primary service and sidekick upgraded from BusyBox 1.36.1
to 1.37.0. Browser evidence shows zero complete service PUTs, one upgrade 202
and the following service-link update 200. The shipped Finish Upgrade control
returned 202. API, database and actual Docker readback confirmed active/healthy
service state, running new instances, removed old instances, unchanged public
address/port, correct endpoint/expose/port ownership, retained volume marker,
environment, labels, scheduling and primary/secondary launch configuration.
The same new instances and settings survived an actual Server restart.

The first QA harness incorrectly attempted Finish Upgrade using raw fetch
without the application's CSRF header and was correctly rejected with 403.
That failed harness attempt is retained, not described as an uninterrupted
zero-error browser run. Finishing through the real UI produced no browser
errors. No CSRF, authentication or permission control was weakened.

The shipped key-editor preview passed in all 11 completed locales at a
1440-pixel desktop viewport. Both allow/deny states were compared against the
release's own translations, including the Persian RTL layout. The dialog and
document had no horizontal overflow; no Key was created or saved. After the
Server restart, the service detail page loaded again and displayed the new
image and running containers. This is not a mobile or audit-panel layout claim.

## Upgrade and rollback

Keep the three existing persistent volumes, operator-provided environment,
restart policy, AppArmor configuration, HTTPS origin, authentication and
networking settings. Retain the previous official image and a pre-upgrade
database backup. This change does not require a schema migration.

Do not use a runtime JavaScript patch. A production installation with an older
read-only bundle override must not carry that old bundle into the new image;
its removal and deployment require separate authorization and acceptance.
This task does not operate on the company production site, proxy, firewall or
database. The QA Server rollout retains its previous container/image for
rollback and never removes persistent volumes.
