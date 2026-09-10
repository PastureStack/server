# PastureStack Server v1.6.415

> **Superseded by `v1.6.416` for reliable first-create completion.** The
> `v1.6.415` runtime and hardware payload remain valid, while Web Console
> `1.6.106` removes the redundant empty link action and preserves immutable
> stack routing across partial action responses.

This release updates the bundled Web Console to `1.6.105` and closes the
service-creation completion regression found during real two-host production
workflow validation.

## Operator-visible result

- A successful first service create persists links, navigates away exactly
  once, and no longer leaves the form visible with a stale-model error that can
  lead to duplicate submissions.
- Virtual-machine, load-balancer, external-service, and alias creation use the
  same safe saved-resource or stable stack-identifier completion path.
- Advanced key/value inputs display a localized value hint instead of exposing
  an internal translation key.
- The `1.6.104` resource-form layout and payload contract remain intact: init,
  shared memory, IPC, runtime, CPU and PID limits, supplementary groups, tmpfs,
  sysctls, ulimits, device mappings, GPU requests, and host placement are not
  changed or dropped.

## Regression coverage

Web Console `1.6.105` passes 428 browser tests, its Docker-hosted browser gate,
the Node 24 release-lock install, and a reproducible double build. The immutable
release artifact is bound to commit
`1aae2b75ae2ae99845c55bde79336d36f9f8b5f0` and SHA-256
`f2bbdafd98e8a9287584a9fe9dc0b4e3d8c66481425b39010c37b200681b3faa`.

Server source gates bind that exact release coordinate before publication.
The release image must still pass initial and restart smoke tests, merged-rootfs
vulnerability and secret scanning, CycloneDX SBOM generation, provenance and
SBOM attestations, and a real create/upgrade lifecycle on the production host
pair before the deployment is accepted.

## Compatibility and security

The Server API, database schema, ports, volumes, authentication behavior,
host-agent protocol, and runtime dependencies are unchanged from `v1.6.414`.
The runtime security base and existing OpenVEX decisions are inherited without
weakening any release gate.
