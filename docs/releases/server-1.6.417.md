# PastureStack Server v1.6.417

This release bundles Web Console `1.6.107` and closes the remaining false
post-save failure found by creating a real service on `ranchernode22` with the
full hardware and runtime form.

## Operator-visible result

- The first successful service submission leaves the form and returns to the
  intended stack; it does not display an error after the API already persisted
  the service and started its container.
- Navigation is derived only from the immutable stack query input. A partial,
  replaced, or unreadable saved API resource is never used as route authority.
- The saved service remains available to the completion chain so non-empty
  service links are still persisted before navigation.
- Empty service-link sets continue to avoid the redundant action introduced in
  older completion paths.
- The existing resource and hardware form remains intact: init, shared memory,
  IPC, runtime, CPU and PID limits, supplementary groups, tmpfs, sysctls,
  ulimits, device mappings, GPU requests, and host placement retain their create
  and upgrade payload contract.

## Reviewed Web Console input

Web Console `1.6.107` is the pure numeric immutable release built from GitHub
verified main commit `9820bf1842066449f4d84bcdaf5cdf56603b2c07`. Its release
artifact `web-console-1.6.107.tar.gz` has SHA-256
`fd7f70adc596c76a2895de15f800b0980fe644111238a55f7c3d8182776803f7`.
The pinned Node 24 workflow passed 429 browser tests, the Docker-hosted Chromium
gate, the dependency and localization gates, and two byte-identical production
builds before publication.

## Compatibility and security

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and non-Web-Console runtime dependencies are unchanged
from `v1.6.416`. The finished image is still subject to the standard restart,
merged-rootfs vulnerability, SBOM, provenance, attestation, and real two-host
create-and-upgrade acceptance gates before deployment is considered complete.
