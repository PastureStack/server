# PastureStack Server v1.6.419

This release bundles Web Console `1.6.109` and corrects the create and upgrade
completion contract exposed by real-host testing on the two-host environment.

## Operator-visible result

- Service creation and upgrade pass classic named completion actions through
  the shared form, preserving the controller receiver after persistence.
- The legacy component-action compatibility layer does not forward prototype
  event methods as action names when an action target exists.
- A successful operation can navigate once without displaying the stale
  `undefined.get` or invalid template-action error that could invite a duplicate
  submission.
- The init-process checkbox keeps additional desktop separation from the
  adjacent process-limit input without changing its launch-configuration
  binding.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, and target-host placement
  retain the existing create and upgrade payload contract.

## Reviewed Web Console input

Web Console `1.6.109` is the pure numeric immutable release built from GitHub
verified main commit `954790a108fbfbe4e963c4c7665fc4d98b71016b`. Its release
artifact `web-console-1.6.109.tar.gz` has SHA-256
`1ca04dba5474b09d9403cde3b9f8d0f2a12148d0424f0769ef9b9f5f01634bc5`.
The pinned Node 24 workflow passed 430 browser tests, the Docker-hosted Chromium
gate, zero npm vulnerabilities, the dependency and localization gates, and two
byte-identical production builds before publication.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and non-Web-Console runtime dependencies are unchanged
from `v1.6.418`. The finished image must still pass restart, merged-rootfs
vulnerability, SBOM, provenance, attestation, and real `ranchernode22` create
and upgrade acceptance before production deployment is considered complete.
