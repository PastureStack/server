# PastureStack Server v1.6.417

> **Superseded by `v1.6.418` after real-host acceptance testing.** `v1.6.417`
> successfully persists the service and starts its container with the requested
> hardware/runtime HostConfig, but deprecated completion dispatch can then raise
> `undefined.get` before navigation. Keep it only as the immediate tested
> rollback image while moving production to `v1.6.418`.

This release bundles Web Console `1.6.107` and removes the saved-response route
dependency from the first-create completion path. Real-host testing proved that
this narrowed the failure but did not close the later callback-dispatch error.

## Operator-visible result

- A successful service submission keeps the intended stack identifier
  independently from the saved API response.
- Navigation is derived only from the immutable stack query input. A partial,
  replaced, or unreadable saved API resource is never used as route authority.
- The saved service remains available to the completion chain so non-empty
  service links are still persisted before navigation.
- Empty service-link sets continue to avoid the redundant action introduced in
  older completion paths.
- Real-host acceptance created exactly one container on `ranchernode22` with
  the requested shared memory, IPC, runtime, CPU/PID limits, init, supplementary
  group, tmpfs, sysctl, ulimit, device mapping, and host placement, but the form
  remained visible after persistence. `v1.6.418` replaces that final dispatch
  with an awaited closure callback.
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
