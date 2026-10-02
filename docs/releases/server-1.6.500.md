# Server v1.6.500

Published immutable image:
`ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5`.
Server source: `abdee460eb67c8cd02a2db8e9a55b15f58020d83`.
[Publication run `36973764295`](https://github.com/PastureStack/server/actions/runs/36973764295)
and public asset/image readback passed. This is not complete resource/role or
company-site acceptance; the matrix remains INCOMPLETE.

## Bounded correction

Server `v1.6.500` packages Engine `v0.183.331` from source
`515a5d37a1194f827bc3ffde34db729905ecb2b1`. Web Console stays `1.6.164`.

Engine330 rejected normal stopped/inactive instance/host mappings during native
container-name synchronization. Retained rollback containers therefore kept
their old platform names even though Docker had different names. The shared
selection and full-row name-only CAS now accept exactly running/active or
stopped/inactive, preserving account, active Host/Agent, full Docker ID, unique
nonremoved mapping and managed/service/stack guards.

No authentication, session, OIDC, MFA, permission, API status, database schema,
Agent/plugin or instance lifecycle change. No migration or runtime patch is required.
This Engine correction does not delete retained rollback containers or persistent
volumes, or manually rewrite their platform names.

## Publication evidence

The official build/flatten and isolated first start/restart returned `HTTP 200` /
`pong` (13 and seven attempts). All 34 MFA policy/API checks and TLS 1.2/1.3
checks passed, with untrusted certificates rejected. Independent public readback
matched 22 checksummed files plus their manifest, the one-layer image,
version/source/digest labels, exact Engine331/Web164 pins and SBOM identity.
The unchanged merged-rootfs gate reports 52 raw findings and eight exact Medium
vendor-pending package findings (four unique CVEs), with zero untracked,
Critical/High, fixed-available or secret findings. The existing review deadline
remains `2026-10-20`; this is not a zero-CVE claim.

## Verification boundaries

The source-generated production SELECT passed 84 synthetic CTE cases on MariaDB:
56 lifecycle pairs and 28 authority/mapping/exclusion cases. No real platform
table or SQL mutation was used; this is not a live CAS-race or browser claim.
Exact Engine CI source passed 268 suites / 1,144 tests with zero failures,
errors or skips, including 22 native-name and six frozen-role response cases.
The official WAR is 87,700,088 bytes, SHA256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`.
The exact WAR completed isolated JDK25.0.3 / H2 startup and exited 0, without
network, exposed ports or platform-data mounts. The signed immutable numeric
[Engine331 release](https://github.com/PastureStack/orchestration-engine/releases/tag/v0.183.331)
publishes six exact CI assets; checksum, revision and test-results content were
also anonymously read back. Artifact/build-image Critical and High findings
are zero; CodeQL retains four lower-severity findings, not an all-findings-zero claim.
The published Server image consumed this exact WAR. Native Host1 browser
initial/reload checks matched five unique full Docker IDs, names and links,
without removed mappings. This proves name synchronization, not readable layout.
Historical failed publication and browser HOLD evidence remain unchanged.

## QA deployment and incomplete visual acceptance

QA500 `8080` first start/restart returned `HTTP 200` / `pong` (nine and 10
attempts). The tracked counts remained account 530, credential 4,068, setting 38,
project_member 14 and host 3 before upgrade, after first start and after restart.
Runtime-contract differences were zero; original environment overrides, three
named volumes, Docker socket, `docker-default` AppArmor and `unless-stopped`
restart policy were preserved. Docker health is `null`, not Docker `healthy`;
count equality is not whole-database row equality. Server499 is retained and
stopped for rollback, and a database backup is present.

Native Host1 initial/reload checks matched five unique full Docker IDs, names
and links and excluded all nine removed mappings. Fresh OIDC and platform TOTP
completed; four Host reads returned HTTP 200. No resource writes, blocked writes,
page errors, console errors, loading errors or unexpected navigation occurred.
Three WebSocket connections were established; one actual server message was
forwarded unchanged to the page. Payloads and credential material were not saved.

Both screenshots were reviewed. Four retained rollback containers still appear
as indistinguishable truncated prefixes even though their complete DOM and model
names differ. Therefore readable visual acceptance remains HOLD. A scoped Web
Console layout correction and new packaged-browser evidence are required; the
technical checks must not be promoted to a fully fixed user-facing result.
The historical Server499 stopped/inactive name
failure and browser HOLD remain recorded; deployment does not promote them.
Full resource/role, all-page/all-locale and company-site acceptance remain
INCOMPLETE and separate from this QA-only startup/restart evidence.

Existing role-schema denials, OIDC/TOTP/Passkey, generation/mutex/session-bound
logout, Compose environment overrides, three named volumes, restart policy,
AppArmor, public origin and nftables architecture must be preserved.
Keep the previous immutable Server499 with its original data/settings for
rollback; restoring 499 restores the stopped-container name limitation.
Publisher smoke, source review and limited name acceptance must not be described
as complete resource/role, all-page/all-locale or company-site acceptance.

The final merged-rootfs scan completed under unchanged thresholds. Its eight
unfixed Medium package findings / four CVEs remain explicitly tracked; no
zero-CVE assertion or weakened gate.
