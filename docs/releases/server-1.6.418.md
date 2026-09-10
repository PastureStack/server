# PastureStack Server v1.6.418

> **Retain as the immediate rollback until `v1.6.419` passes real-host
> acceptance testing.** `v1.6.418`
> persisted the service and started its requested container on
> `ranchernode22`, but its completion action could still lose the controller
> receiver and leave the form visible with `undefined.get` or an invalid
> template-action error. It is not the forward deployment target.

This release bundles Web Console `1.6.108` and attempted to close the
first-service completion failure reproduced after persistence. Real-host
testing proved that the remaining failure was in the action receiver contract,
not in the Docker payload or container creation itself.

## Operator-visible result

- Create and upgrade completion invokes the template's closure callback after
  persistence, but real-host testing found that the legacy compatibility path
  can still misroute that callback when a component action target exists.
- The service and its container can be created successfully even though the
  form then displays a false failure; operators must not resubmit the form.
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
