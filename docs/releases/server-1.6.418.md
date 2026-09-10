# PastureStack Server v1.6.418

This release bundles Web Console `1.6.108` and fixes the remaining first-service
completion failure reproduced on the real two-host environment after the API
had already persisted the service and started its container.

## Operator-visible result

- Create and upgrade completion invokes and awaits the template's closure
  callback directly instead of routing it through deprecated `sendAction`
  dispatch.
- A successful first create leaves the form exactly once and cannot present the
  stale `undefined.get` error that invited an accidental duplicate submission.
- The saved service remains available through service-link persistence, while
  route selection continues to use the immutable stack query input.
- The existing resource and hardware form remains intact: init, shared memory,
  IPC, runtime, CPU and PID limits, supplementary groups, tmpfs, sysctls,
  ulimits, device mappings, GPU requests, and host placement retain their create
  and upgrade payload contract.

## Reviewed Web Console input

Web Console `1.6.108` is the pure numeric immutable release built from GitHub
verified main commit `862f55818b43e9bbdbc3366c7fe8d763765b9a2f`. Its release
artifact `web-console-1.6.108.tar.gz` has SHA-256
`a45a75bdaab37155b2bcac8ecd5a5e5abd13e64ca631f96b93a144608f98c180`.
The pinned Node 24 workflow passed 429 browser tests, the Docker-hosted Chromium
gate, the dependency and localization gates, and two byte-identical production
builds before publication.

## Compatibility and security

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and non-Web-Console runtime dependencies are unchanged
from `v1.6.417`. The finished image must still pass the standard restart,
merged-rootfs vulnerability, SBOM, provenance, attestation, and real two-host
create-and-upgrade acceptance gates before deployment is considered complete.
