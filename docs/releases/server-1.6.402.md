# PastureStack Server v1.6.402

This release delivers the reviewed Web Console footer and service resource
configuration fixes together with the corrected Compose v3 conversion path.

## Operator-visible result

- The footer language and CLI menus share one right-aligned, upward-opening,
  viewport-bounded positioning rule. Repeated open/close operations and page
  scrolling no longer move the CLI menu to the left edge.
- Service create and upgrade forms keep host guidance attached to the target
  host control, use the responsive resource layout, and expose the translated
  ulimit action in all 13 shipped locales.
- Compose v3 labels and environment mappings retain their typed mapping shape,
  so infrastructure upgrades no longer fail while converting named YAML maps.

## Bound release input

- Immutable runtime base:
  `ghcr.io/pasturestack/server:v1.6.401@sha256:961ea3de0f550a84034bd18c2f2cb39d72822310887c4605f12fa6dcdb9fddcb`
- Web Console `1.6.102`, commit
  `9f754ba35ab0c6eaa7d6cd42304f36bb9aba378c`, artifact SHA-256
  `6269235a9a23a43b025ca78269ea7d807108c36b007f3eb65c5369c639261bb1`.
- Compose Executor `0.14.36`, commit
  `e85545a1bc34cb5c42db62ff90dd82b7ff9f5838`, compressed artifact SHA-256
  `47e2ba1686c1b136c7edcac530495c3e29c351e947f0b4d08ebe68d33f98cf66`,
  binary SHA-256
  `1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d`.

Only the Web Console static package and Compose Executor binary are replaced
on the immutable v1.6.401 base. The publication workflow still requires
source gates, initial and restart smoke, merged-rootfs vulnerability and secret
scan, SBOM, provenance, attestations, and an immutable release.

The runtime retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`. An unmatched vulnerability at any severity remains a release blocker.
