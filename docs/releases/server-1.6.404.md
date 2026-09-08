# PastureStack Server v1.6.404

This release keeps the reviewed Web Console, Compose Executor, and catalog
bytes from v1.6.403 and advances only the pinned Orchestration Engine.

## Operator-visible result

- Infrastructure stack upgrades no longer reject legitimate per-host Docker
  named volumes as an environment-wide ambiguous volume.
- The preflight uses the same shared-or-unmapped lookup as the actual container
  creation path. Multiple resolvable shared volumes, storage-driver mismatch,
  and unusable resolved volumes remain fail-closed.
- No volume is deleted, renamed, migrated, or converted by this change.
- The footer language and CLI menus retain the shared right-aligned,
  upward-opening, viewport-bounded behavior from Web Console 1.6.102.
- Service create and upgrade forms retain the reviewed resource and hardware
  controls and all 13 translations.

## Bound release input

- Orchestration Engine `0.183.290` from immutable first-party release
  `v0.183.290`, signed source commit
  `8cec53e69ea30157273dbd5089edb4a79fad7998`, artifact SHA-256
  `6d1af6126777dfeccf4722f96a049abff1621f217a4a01f9bee6824dedb3fb21`.
- Immutable runtime base:
  `ghcr.io/pasturestack/server:v1.6.401@sha256:961ea3de0f550a84034bd18c2f2cb39d72822310887c4605f12fa6dcdb9fddcb`.
- Catalog commit:
  `06dfff6234ba8bf163d98e148cc61c0ebd0b2656`.
- Web Console `1.6.102`, commit
  `9f754ba35ab0c6eaa7d6cd42304f36bb9aba378c`, artifact SHA-256
  `6269235a9a23a43b025ca78269ea7d807108c36b007f3eb65c5369c639261bb1`.
- Compose Executor `0.14.36`, commit
  `e85545a1bc34cb5c42db62ff90dd82b7ff9f5838`, binary SHA-256
  `1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d`.

The publication workflow continues to require source gates, initial and restart
smoke tests, merged-rootfs vulnerability and secret scans, SBOM, provenance,
attestations, and an immutable release. An unmatched vulnerability at any severity remains a release blocker.

The runtime retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The release is an incremental image over the immutable v1.6.401 runtime. It
verifies and replaces the Orchestration Engine JAR, reapplies the Server-only
schema and bootstrap overlays, and then installs the pinned Web Console and
Compose artifacts. Unchanged glibc, OpenSSL, and operating-system bytes are
inherited from the already scanned base instead of being rebuilt from the
Ubuntu snapshot service.
