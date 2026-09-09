# PastureStack Server v1.6.408

This release keeps the reviewed Web Console, Orchestration Engine, Compose
Executor, catalog, and runtime base from v1.6.407 and fixes the shared console
broker path used by both container logs and interactive shells.

## Operator-visible result

- Container log windows connect to the authenticated WebSocket stream instead
  of stopping at an empty error state.
- Interactive container shell windows use the same repaired connection path.
- The public browser origin is still checked before session creation. The
  broker then binds the internal WebSocket handshake Origin to its fixed,
  operator-controlled dial address so the internal same-origin gate can
  validate the actual connection endpoint.
- Target host, path, session secret, access token, and browser client identity
  validation remain unchanged.
- The existing Web Console HTML, CSS, window layout, translations, charts,
  audit filters, footer menus, and resource actions are unchanged.

## Bound release input

- Orchestration Engine `0.183.293` from immutable first-party release
  `v0.183.293`, signed source commit
  `c8a2e6509f54702ab3bf969f0d92712c00b10e2e`, artifact SHA-256
  `aad8c43e09ab36f63409aada9ad61a24d12ba787ce3d51ebc1dde51a5ca460fa`.
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

The console-broker tests cover external browser-origin validation, rebinding to
the fixed internal dial origin, authenticated session attachment, terminal
input ownership, log framing, replay after disconnect, session capacity, and
termination. The Server publication workflow still requires initial and
restart smoke tests, a merged-rootfs vulnerability and secret scan, SBOM,
provenance, attestations, and an immutable release.

An unmatched vulnerability at any severity remains a release blocker.

The unchanged runtime base retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.
