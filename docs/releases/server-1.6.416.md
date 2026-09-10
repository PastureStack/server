# PastureStack Server v1.6.416

This release updates the bundled Web Console to `1.6.106` and closes the
remaining first-service creation completion failure reproduced against the
real two-host environment.

## Operator-visible result

- A successful first service create leaves the form after one submission;
  operators are no longer shown a false JavaScript error after the service is
  already active.
- The common empty service-link set no longer sends a redundant
  `setservicelinks` action after persistence.
- A non-empty link update cannot erase the saved stack route identity when its
  action response contains only a partial service resource.
- The route keeps its original stack identifier independently from the mutable
  response, so create and upgrade completion use the intended stack.
- The `1.6.104` resource-form layout and payload contract remain intact: init,
  shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, and host placement are not
  changed or dropped.

## Regression coverage

Web Console `1.6.106` passes 429 browser tests, the Docker-hosted browser gate,
the Node 24 release-lock install, and a reproducible double build. The immutable
release artifact is bound to commit
`e7bad722f4853cab90c8f564982bf6d37507315c` and SHA-256
`7ad72153076a11a706f23c2ef3e9f1993d114a549dd1f0155a7709f064a892d5`.

Before this Server release was prepared, a real service creation on
`ranchernode22` was inspected at the Docker boundary. Its 80 MiB shared-memory
mount, private IPC, containerd runtime, CPU quota and period, PID limit,
`/dev/dri/renderD128` mapping, supplementary GID, tmpfs, sysctl, ulimit and init
process all matched the submitted API values. The final release still requires
a fresh create-and-upgrade lifecycle after the new image replaces port 8080.

## Compatibility and security

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and runtime dependencies are unchanged from `v1.6.415`.
The runtime security base and existing OpenVEX decisions are inherited without
weakening any release gate.
