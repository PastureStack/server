# PastureStack Server v1.6.400

This release completes the host-storage compatibility and resource-form usability
work without changing the service API contract.

## Operator-visible result

- Node Agent `v0.13.27` routes volume activate and remove events through the
  same typed Docker decoder used by instance lifecycle events. Nested current
  Docker inspect values no longer leave volume reconciliation stuck or make a
  connected host appear disconnected.
- Web Console `1.6.101` uses progressive disclosure in the shared Resources and
  Hardware form: the target host is chosen first, then only runtime, GPU and
  device choices available on that host are shown. Advanced manual group
  settings remain available without dominating the common path.
- Create and service upgrade continue to use the same typed deployment fields
  for shared memory, runtime, init, CPU/PID limits, ulimits, tmpfs, sysctls,
  NVIDIA requests and Intel/AMD device mappings.
- The resource controls never implicitly enable privileged mode, host IPC or an
  unconfined security profile.

## Bound release inputs

- Node Agent release: `v0.13.27`
- Node Agent source: `d78a0817214bb21e3537730e68e12ebb74cbdaca`
- Node Agent Linux archive SHA-256:
  `0cbf93ef6f90db8c5f6b8cf7d63c99f452b8fc43e93097a21cdb5bcc3007d475`
- Node Agent Windows archive SHA-256:
  `b6a56f8833c31bc224b7baf20ceb1a252c027021efbe6265c1906f8478d7c2fa`
- Web Console release: `1.6.101`
- Web Console source: `cb5af27e29f166ba71eda7939d0a90b6c6e52255`
- Web Console archive SHA-256:
  `bae2ba7f837f396ea1980d97f5654b2c02cef256bc18926ca1a80992ed542189`

The Server build verifies every downloaded archive before extraction and binds
the exact source identities into image metadata. All other runtime components
remain identical to v1.6.399: Orchestration Engine `0.183.289`, Compose Executor
`0.14.35`, Host Provisioner `v0.39.7`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8` and zlib `1.3.2`.

The runtime retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`. An unmatched vulnerability at any severity remains a release blocker.

Publication requires source gates, initial and restart smoke, a merged-rootfs
Trivy scan with no unresolved vulnerability or secret, an artifact SBOM,
provenance, SBOM attestation and an immutable release. Actual GPU execution is
validated only on a compatible physical host; a non-GPU VM cannot prove CUDA,
ROCm or media-driver availability.
