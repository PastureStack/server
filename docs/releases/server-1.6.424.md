# PastureStack Server v1.6.424

This release bundles Web Console `1.6.114` and fixes the exact post-create
exception captured during a real `ranchernode22` service-create workflow.

## Operator-visible result

- The live service collection may briefly contain an unreadable entry while the
  API store merges a newly created service. The page-header observer now ignores
  only those transient entries instead of aborting completion navigation.
- The same guard covers the navigation-tree rebuild path, preventing the same
  collection state from producing a second form of the failure.
- The unrelated post-create service reload introduced during diagnosis is
  removed. A successful save proceeds through the existing receiver-bound
  completion action without another API request.
- Shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, init, and target-host
  placement retain the established create and upgrade payload contract.
- The init-process checkbox remains visually separated from the adjacent PID
  limit input; the authenticated layout and unrelated Server behavior remain
  unchanged.

## Reviewed Web Console input

Web Console `1.6.114` is the pure numeric immutable release built from GitHub
verified main commit `0073eb16fcc746e69657a2d40f1022bb6bc968c2`. Its release
artifact `web-console-1.6.114.tar.gz` has SHA-256
`8aee1a37fca5e025d37d324a872bf97d39d32bc458a82f523ff8fdf38f35d56d`.
The pinned Node 24 workflow run `34559982245` passed 435 Chrome 152 browser
tests, the Docker-hosted Chromium gate, dependency and localization gates, and
two byte-identical production builds before publication. The high-severity npm
audit gate reports zero vulnerabilities.

## Compatibility and release boundary

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, typed Java and MariaDB Compose settings, and non-Web-
Console runtime dependencies are unchanged from `v1.6.423`. The finished image
must still pass restart, merged-rootfs vulnerability, SBOM, provenance,
attestation, and real `ranchernode22` create and upgrade acceptance before
production deployment is considered complete.
