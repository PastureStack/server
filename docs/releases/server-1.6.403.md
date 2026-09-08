# PastureStack Server v1.6.403

This release keeps the reviewed Web Console and Compose Executor bytes from
v1.6.402 and advances only the pinned first-party catalog authority.

## Operator-visible result

- The footer language and CLI menus retain the shared right-aligned,
  upward-opening, viewport-bounded behavior shipped in v1.6.402.
- Service create and upgrade forms retain the reviewed resource layout and all
  13 translations shipped in Web Console 1.6.102.
- The network diagnostics v0.2.1 catalog target emits an explicit TCP protocol,
  preventing a metadata-only catalog update from being mistaken for a fixed-port
  service replacement.

## Bound release input

- Immutable runtime base:
  `ghcr.io/pasturestack/server:v1.6.401@sha256:961ea3de0f550a84034bd18c2f2cb39d72822310887c4605f12fa6dcdb9fddcb`
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
