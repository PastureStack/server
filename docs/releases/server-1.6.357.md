# PastureStack Server v1.6.357

Server v1.6.357 packages Web Console `1.6.70` with its reviewed build-chain
security fix while retaining Authentication Service `0.4.35`, the Catalog
snapshot, Resource Scheduler catalog revision, Orchestration Engine, and Node
Agent coordinates from the preceding release.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Authentication Service: `0.4.35`
- Authentication Service source:
  `b5f50c57407fcc1b789bff680084226fba2e3171`
- Authentication Service archive SHA-256:
  `17c10c2d907d75cc2ead63b9b7ec7c3535b9d45e812afede94c0df799251172b`
- Authentication Service binary SHA-256:
  `a49f60048d841b5e164a3f9d60f52f125e8d6b663f337b4aafb7a20b4e4034dd`
- Web Console: `1.6.70`
- Web Console source: `8a93d712a15dd4e57ae16e7e2cd8f9b4af230339`
- Web Console artifact SHA-256:
  `d9d62bfd9869283a0ee30405b9abe4d5d5cf81d74ff17c2037cc58a861ecf5af`
- Catalog snapshot: `bc446236c16f1170eb9130b4901af3d57dd82db4`
- Resource Scheduler catalog release: `v0.8.16`

## Security correction

Web Console `1.6.70` resolves `GHSA-2v37-7h3g-55p8` /
`CVE-2026-67213` by locking the transitive build-only `nanoid` dependency to
patched version `3.3.17`. The reviewed toolchain is pinned to Node.js
`24.18.1` LTS, its bundled npm `11.16.0`, the official Node archive checksum,
and an immutable official Node container manifest. Release CI now also queries
the current npm advisory service and fails on any Critical or High finding.

The exact Web Console source passed 340 Chromium tests, all source and
dependency gates, 13-locale validation, a clean lock restoration, and two
byte-identical production builds. The complete dependency graph reported zero
Critical and zero High findings; the shipped browser Runtime reported zero
findings at every severity.

## Retained behavior

The deterministic loading-overlay lifecycle and rectangular PastureStack stack-panel loading state
remain intact. Only the newest route transition may
change the overlay state; successful, rejected, aborted, and overlapping transitions
release it safely. Reduced-motion mode remains visible without
restoring the retired landscape, celestial-body, orbit, or rotating-ring
scene.

The `volumepreflight` action retains the real core add-on type set,
project-scoped authorization, authoritative create and upgrade validation, and
the creatable `volumePreflightInput` contract. The packaged-image gate still
rejects the retired `String.prototype.dasherize` path. A same-tick volume recheck
cannot become a stale client-side save failure. The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and complete active-host
coverage. Every successful selected-volume deletion refreshes the visible
rows, pagination, selected count, and controls immediately; failed rows remain
visible.

Authentication Service `0.4.35`, the embedded Catalog snapshot, Resource
Scheduler `v0.8.16`, API Explorer `1.1.15`, broker-aware terminal recovery,
single-owner project WebSocket reconnect, OpenID Connect, MFA, and all 13
reviewed production locales remain unchanged.

## Publication gates

Server assembly verifies the public Web Console release checksum, source
commit, archive root, numeric version marker, required licenses, loading
markers, and absence of source maps before producing the image. The manual
publication workflow builds two clean candidates, compares their Runtime
payload and image configuration, rejects Critical or High image findings and
embedded secrets, emits a CycloneDX SBOM, and publishes provenance and SBOM
attestations for the GHCR image.

Live deployment acceptance still requires `/ping`, local login, OpenID
Connect, MFA, authenticated route navigation, transition dismissal, Catalog
revision discovery, container restart count, persistent volume identity, and
rollback readiness in the isolated VM before formal cutover.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
