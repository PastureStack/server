# Server v1.6.596 candidate

## Candidate boundary

Server build and publication are pending.

## Verified component inputs

Packages immutable Engine v0.183.395, Web Console 1.6.235 and Compose 0.14.45.
Bridge 0.2.37 is an optional client released with Web Console.

Host discovery matches the native hostname and custom name. The Engine retains
role and API Key scope checks, bounded pages and continuation on empty matching
pages. The Engine's CA package update and scoped Dapper tracking apply to its
build. Server runtime package policy is unchanged.

Deployment acceptance covers Host disable and restore, placement eligibility,
actual placement after reactivation, existing workloads and volumes, and native
audit results. Preserve the preceding Server image and persistent attachments
when upgrading.
