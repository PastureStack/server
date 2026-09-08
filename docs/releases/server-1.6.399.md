# PastureStack Server v1.6.399

This release completes the host-recovery and resource-form work carried by
v1.6.398 without changing the service API contract.

## Operator-visible result

- Node Agent `v0.13.26` decodes current Docker inspect event types, including
  exposed ports, gateway/IP addresses and MAC addresses. This prevents a live
  host from appearing disconnected or leaving infrastructure containers in a
  stale transition state after Docker 24/29 events.
- Web Console `1.6.100` reorganizes the shared Resources and Hardware form into
  essential, hardware, limits and advanced sections. Shared-memory value/unit
  controls remain aligned, host-bound runtime/GPU/device choices remain
  discoverable, and rare options no longer dominate the page.
- Create and update continue to use the same typed deployment fields for shared
  memory, runtime, init, CPU/PID limits, ulimits, tmpfs, sysctls, NVIDIA requests
  and Intel/AMD device mappings.
- The resource controls never implicitly enable privileged mode, host IPC or an
  unconfined security profile.

## Bound release inputs

- Node Agent release: `v0.13.26`
- Node Agent source: `325e3324271b7a2be86d78977f7b6c32ca3a680c`
- Node Agent Linux archive SHA-256:
  `c198fdcbe870a8b7c3dbaefe7d5a3a100c4be11790c7dd75c649ae17980773c1`
- Node Agent Windows archive SHA-256:
  `1247a13a8af77c7d9bacb6828cab64e364b60165bddacf80e94b88830f7c9d45`
- Web Console release: `1.6.100`
- Web Console source: `310b96e5dd6ce2ab51fae0bf8bd0b6f138d0fd2d`
- Web Console archive SHA-256:
  `c1e74481ec79f6d2d752b069955d1d4e1cd8bd4123d58c3ba13ca8c2e458c0bd`

The Server build verifies every downloaded archive before extraction and binds
the exact source identities into image metadata. All other runtime components
remain identical to v1.6.398: Orchestration Engine `0.183.289`, Compose Executor
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
