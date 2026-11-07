# Server v1.6.580

Published image: `ghcr.io/pasturestack/server:v1.6.580@sha256:231f073df5bbcdbcc82ed4a2f10c714093237e4e9099db294b6eb08c5c56aff8`.

Source commit: `eb3154723f22d357784a36f385f16d16a4734f77`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

Packages published Engine 0.183.382 to repair authorization for platform-managed
load-balancer Agent creation, upgrade, Stack activation and cleanup. The exact
native dependency identities remain bound to the caller's current role and API
Key permissions; this adds no general Agent access or Full/system bypass.

Web Console 1.6.222 / optional Bridge 0.2.24, Compose 0.14.43, Catalog 0.20.17,
all other components, build-layer instructions, APT19 and security gates remain
unchanged. Web222 retains its published Engine380 compatibility metadata; this
assembly separately verifies its fourteen-input ABI against Engine382. The
later ordinary-Service dependency-links feature is not included.

Engine382's original CI passed 451 suites and 4,101 tests, with zero failures or
errors, one inherited skip and all 286 required methods. Its published JAR,
compiled role schemas and immutable release evidence were verified. Component
and publication checks do not establish deployment-specific native TCP,
weak-model or complete frontend acceptance.

Preserve the operator's environment, origins, JVM options, feature opt-ins,
mounts, named volumes, restart policy, AppArmor and firewall configuration.
This repair introduces no data migration. Retain the qualified Server579 image,
operator configuration and matching database backup for rollback; restore the
complete assembly rather than replacing a running Engine or Web bundle.
