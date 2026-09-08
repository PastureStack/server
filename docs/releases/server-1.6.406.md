# PastureStack Server v1.6.406

This release keeps the reviewed Web Console, Compose Executor, catalog, and
runtime base from v1.6.405 and advances only the pinned Orchestration Engine.

## Operator-visible result

- Service creation and in-service upgrades now preserve the selected Docker
  restart policy through both the API authorization boundary and the
  downstream container launch configuration.
- The resource and hardware form continues to map shared memory, runtime,
  init, PID and CPU limits, tmpfs, sysctls, ulimits, GPU/device mappings, and
  supplemental groups to the Docker host configuration.
- The existing Web Console layout, footer menus, translations, audit filters,
  charts, and action menus are unchanged by this release.

## Bound release input

- Orchestration Engine `0.183.292` from immutable first-party release
  `v0.183.292`, signed source commit
  `63d2d63a2036f569010daaaed701307b1c4f20a5`, artifact SHA-256
  `57362214e72f611b45d0b3a878aeb017282ddc766cf59abc3e5f487714b9a79e`.
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

The engine authorization-schema test, downstream launch-config test, historical
service integration scenario, and complete Maven reactor pass. The Server
publication workflow still requires source gates, initial and restart smoke
tests, a merged-rootfs vulnerability and secret scan, SBOM, provenance,
attestations, and an immutable release.

An unmatched vulnerability at any severity remains a release blocker.

The unchanged runtime base retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.
