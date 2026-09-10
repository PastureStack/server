# PastureStack Server v1.6.414

This release updates the bundled Web Console to `1.6.104` and closes the
remaining service resource-form layout and payload regression gap before
production use.

## Operator-visible result

- The **Use init process** checkbox stays inside its own grid field and no
  longer overlaps the process-limit input at desktop or responsive widths.
- The checkbox uses an explicit native change binding, so its visible state and
  the saved `runInit` value cannot diverge.
- Both service creation and upgrade retain shared-memory size, IPC mode,
  container runtime, init, PID and CPU limits, supplementary groups, tmpfs,
  sysctls, ulimits, direct device mappings, GPU device requests, and the chosen
  target host.
- Existing fields, navigation, authenticated layout, and application data are
  otherwise unchanged.

## Regression coverage

The Web Console release runs its complete 425-test browser suite, a focused
layout assertion against the rendered checkbox, and a field-complete create and
upgrade payload test. Its reviewed Linux release build is produced twice with
identical bytes before the immutable `1.6.104` archive is published.

Server source gates bind the exact Web Console source commit, release archive,
archive SHA-256, package version, and all existing runtime components. Server
publication then builds the image once, starts and restarts the embedded
database stack, verifies the public-origin and private-cache contracts, scans
the merged root filesystem, creates a CycloneDX SBOM, and publishes provenance
and SBOM attestations.

## Compatibility and security

The Server API, database schema, ports, volumes, authentication behavior, and
host-agent protocol are unchanged from `v1.6.413`. The release keeps
Orchestration Engine `0.183.295`, WebSocket Proxy `0.23.14`, API Explorer
`1.1.18`, Compose Executor `0.14.36`, Node Agent `0.13.27`, and vSphere CLI
Bundle `0.55.2`; only the reviewed Web Console changes to `1.6.104`.

The runtime security base and OpenVEX decisions are inherited unchanged. Any
unmatched vulnerability at any severity, any detected secret, a non-reproducible
Web Console archive, or a failed initial/restart smoke remains a release blocker.
