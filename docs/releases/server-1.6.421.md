# PastureStack Server v1.6.421

This release bundles Web Console `1.6.111` and fixes the post-save completion
failure found during real-host create acceptance on `ranchernode22`.

## Operator-visible result

- A successful service or container create or upgrade leaves the form exactly
  once instead of persisting the resource and then failing with
  `Cannot read properties of undefined (reading 'get')`.
- The four top-level container and virtual-machine entry routes use
  receiver-bound completion and cancel callbacks instead of legacy string
  action dispatch.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, init, and target-host
  placement retain the established create and upgrade payload contract.
- The init-process checkbox remains visually separated from the adjacent PID
  limit input; the authenticated layout and all other Server behavior remain
  unchanged.

## Reviewed Web Console input

Web Console `1.6.111` is the pure numeric immutable release built from GitHub
verified main commit `6cae6394779369aa7883f058447faaf40b9f9107`. Its release
artifact `web-console-1.6.111.tar.gz` has SHA-256
`bbbd732119074f3a8f02083abc5b7552196d920e27b7eabf0397e3c1c23b7d4e`.
The pinned Node 24 workflow run `34550419729` passed 433 Chrome 152 browser
tests, the Docker-hosted Chromium gate, dependency and localization gates, and
two byte-identical production builds before publication. The high-severity npm
audit gate reports zero vulnerabilities.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, typed Java and MariaDB Compose settings, and non-Web-
Console runtime dependencies are unchanged from `v1.6.420`. The finished image
must still pass restart, merged-rootfs vulnerability, SBOM, provenance,
attestation, and real `ranchernode22` create and upgrade acceptance before
production deployment is considered complete.
