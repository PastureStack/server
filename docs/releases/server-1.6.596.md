# Server v1.6.596

## Publication

Immutable image digest `sha256:6c2bf310a0308ff0292e74afa29205e81071094a7d7fea6423519f4582c507af`.
Source revision `532de11774d42581f46b936a82a2872bb5e06b4d`.

The [publisher run](https://github.com/PastureStack/server/actions/runs/42940883563)
passed the image build, runtime scan, startup and restart checks.

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

## Upgrade and rollback

Use the numeric `v1.6.596` tag in the documented Docker or Compose installation.
Back up the database and keep the current mounts, persistent volumes,
configuration and previous image. For rollback, stop the replacement before
starting the retained version with its original configuration. Restore the
matching backup if database changes require it.
