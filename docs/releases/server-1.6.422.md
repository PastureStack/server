# PastureStack Server v1.6.422

This release bundles Web Console `1.6.112` and closes the remaining post-save
render race found by the formal `ranchernode22` create acceptance test.

## Operator-visible result

- A newly persisted service is refreshed before the destination stack renders,
  so a sparse API response cannot expose a half-hydrated launch configuration
  and trigger `Cannot read properties of undefined (reading 'get')`.
- If only the optional refresh fails transiently, the successful save remains
  authoritative and navigation continues instead of presenting a false failed
  save that encourages duplicate submission.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, init, and target-host
  placement retain the established create and upgrade payload contract.
- The init-process checkbox remains visually separated from the adjacent PID
  limit input; the authenticated layout and unrelated Server behavior remain
  unchanged.

## Reviewed Web Console input

Web Console `1.6.112` is the pure numeric immutable release built from GitHub
verified main commit `dd29657a960fc2843228fc8d9c62716f0b698d5d`. Its release
artifact `web-console-1.6.112.tar.gz` has SHA-256
`cc4919ac01d5857577835da4450c3930ca5cdcdf1b639bcedf1c15f2c285a4a2`.
The pinned Node 24 workflow run `34553644704` passed 435 Chrome 152 browser
tests, the Docker-hosted Chromium gate, dependency and localization gates, and
two byte-identical production builds before publication. The high-severity npm
audit gate reports zero vulnerabilities.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, typed Java and MariaDB Compose settings, and non-Web-
Console runtime dependencies are unchanged from `v1.6.421`. The finished image
must still pass restart, merged-rootfs vulnerability, SBOM, provenance,
attestation, and real `ranchernode22` create and upgrade acceptance before
production deployment is considered complete.
