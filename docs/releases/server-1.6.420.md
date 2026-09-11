# PastureStack Server v1.6.420

This release bundles Web Console `1.6.110` and closes the remaining create and
upgrade form failures found during real-host acceptance of the hardware and
runtime settings workflow.

## Operator-visible result

- Every mutable classic form binding now uses a supported closure action, so
  command, environment, runtime, device, host, storage, webhook, and cloud
  driver fields no longer fail with an invalid template-action exception.
- Clipboard handling accepts both the legacy list interface and the modern
  Chrome array-like clipboard type list without throwing during paste or
  automated field entry.
- The init-process checkbox keeps visible separation from the adjacent PID
  limit input while preserving the same launch-configuration binding.
- The `v1.6.419` create and upgrade completion fix remains in place.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, and target-host placement
  retain the existing create and upgrade payload contract.

## Reviewed Web Console input

Web Console `1.6.110` is the pure numeric immutable release built from GitHub
verified main commit `4fa0490b02f154b19d692a649600d709ad3b292f`. Its release
artifact `web-console-1.6.110.tar.gz` has SHA-256
`337278627ab4c7b2abb0d835ac1abb8c15197160a4787a2943fa72756893b766`.
The pinned Node 24 workflow run `34545790725` passed 432 Chrome 152 browser
tests, the Docker-hosted Chromium gate, dependency and localization gates, and
two byte-identical production builds before publication. The high-severity npm
audit gate reports zero vulnerabilities.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and non-Web-Console runtime dependencies are unchanged
from `v1.6.419`. The finished image must still pass restart, merged-rootfs
vulnerability, SBOM, provenance, attestation, and real `ranchernode22` create
and upgrade acceptance before production deployment is considered complete.
