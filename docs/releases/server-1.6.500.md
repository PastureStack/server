# Server v1.6.500

Preparing only. No immutable image, QA deployment or browser PASS is claimed yet.

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
No retained rollback container or persistent volume is deleted or manually renamed.

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
Consuming Server image and native Host1 browser initial/reload checks remain required.
Historical failed publication and browser HOLD evidence remain unchanged.

Existing role-schema denials, OIDC/TOTP/Passkey, generation/mutex/session-bound
logout, Compose environment overrides, three named volumes, restart policy,
AppArmor, public origin and nftables architecture must be preserved.
Keep the previous immutable Server499 with its original data/settings for
rollback; restoring 499 restores the stopped-container name limitation.
Publisher smoke, source review and limited name acceptance must not be described
as complete resource/role, all-page/all-locale or company-site acceptance.

The final merged-rootfs scan remains mandatory. Unfixed upstream Medium/Low
findings stay explicitly tracked; no zero-CVE assertion or weakened gate.
