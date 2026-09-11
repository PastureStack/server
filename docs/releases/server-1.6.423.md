# PastureStack Server v1.6.423

This release bundles Web Console `1.6.113` and closes the post-save navigation
failure reproduced by the formal `ranchernode22` service-create acceptance
test.

## Operator-visible result

- A newly persisted service is force-loaded through the API store by its stable
  service ID before the destination stack renders. This does not depend on a
  sparse create response already carrying a usable self link.
- The successful create remains authoritative if only that optional readback
  fails transiently, so the form does not encourage a duplicate submission.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, init, and target-host
  placement retain the established create and upgrade payload contract.
- The init-process checkbox remains visually separated from the adjacent PID
  limit input; the authenticated layout and unrelated Server behavior remain
  unchanged.

## Reviewed Web Console input

Web Console `1.6.113` is the pure numeric immutable release built from GitHub
verified main commit `0c7a004da82c546d9d7660433411918b1fc334d0`. Its release
artifact `web-console-1.6.113.tar.gz` has SHA-256
`fe914873fc4bc5a80cae0ca3a3157916acb417644e9305d45d85929aafec4840`.
The pinned Node 24 workflow run `34555833447` passed 435 Chrome 152 browser
tests, the Docker-hosted Chromium gate, dependency and localization gates, and
two byte-identical production builds before publication. The high-severity npm
audit gate reports zero vulnerabilities.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, typed Java and MariaDB Compose settings, and non-Web-
Console runtime dependencies are unchanged from `v1.6.422`. The finished image
must still pass restart, merged-rootfs vulnerability, SBOM, provenance,
attestation, and real `ranchernode22` create and upgrade acceptance before
production deployment is considered complete.
