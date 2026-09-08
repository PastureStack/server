# PastureStack Server v1.6.398

This release keeps the hardware-resource implementation and all other runtime
components from v1.6.397, while correcting the embedded Node Agent package
contract used by existing PastureStack host installers.

## Operator-visible result

- Node Agent `v0.13.25` remains compatible with older installers through
  `SHA1SUMS` and `SHA1SUMSSUM`.
- The same Linux archive now also supplies `SHA256SUMS` and `SHA256SUMSSUM`, so
  current host installers no longer reject it as an invalid download.
- Shared memory, runtime, init, CPU/PID, ulimit, tmpfs, sysctl, NVIDIA GPU and
  Intel/AMD device controls are unchanged from v1.6.397.
- Hardware options remain typed and validated; they never implicitly enable
  privileged mode, host IPC or an unconfined security profile.

## Bound Node Agent inputs

- Release: `v0.13.25`
- Source: `5943a98500c0ee2a5847d8fdba3dcf71e3c4e82b`
- Linux archive SHA-256:
  `331f166261c5e8b5a43f4323caf83faf7d81bac202c2dac8eba5bfe314062fff`
- Windows archive SHA-256:
  `79e995b589aaea91735c2676ebe4644507bc46805f38965b8b7ea9804bf279c1`

The Server image verifies both outer release assets before embedding them. The
Linux package additionally verifies its legacy and current checksum chains in
Node Agent CI. The startup environment, compatibility symlink and Windows
package URL all resolve to v0.13.25.

All other bound components remain identical to v1.6.397: Orchestration Engine
`0.183.289`, Web Console `1.6.99`, Compose Executor `0.14.35`, Host Provisioner
`v0.39.7`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL `3.5.8` and zlib `1.3.2`.

The runtime keeps glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910`. An unmatched vulnerability at any severity remains a release blocker.

Publication still requires initial start and restart smoke, a merged-rootfs
scan, artifact SBOM, provenance and immutable release. GPU workload
compatibility remains a physical-host validation concern; a non-GPU VM cannot
prove CUDA, ROCm or media-driver support.
