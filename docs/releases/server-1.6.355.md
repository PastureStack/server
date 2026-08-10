# PastureStack Server v1.6.355

Server v1.6.355 packages Authentication Service `0.4.35`, Web Console `1.6.68`,
the reviewed Catalog snapshot, and the Resource Scheduler catalog revision
without changing the established Orchestration Engine or Node Agent runtime
coordinates.

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
- Web Console: `1.6.68`
- Web Console source: `bcd2e28ef63878be5d3d38c06119395d09a0211f`
- Web Console artifact SHA-256:
  `3f98339b378e2a77a86d3078ba3f1f1448030f58d5ef96b9c6bbfcb13b3f9a24`
- Catalog snapshot: `bc446236c16f1170eb9130b4901af3d57dd82db4`
- Resource Scheduler catalog release: `v0.8.16`

## Corrected behavior

The Web Console retains its deterministic loading-overlay lifecycle and now
uses a rectangular PastureStack stack-panel loading state. A monotonic transition
identifier ensures that stale completion callbacks from overlapping transitions
cannot show or hide the current overlay. Successful, rejected,
and aborted transitions all release the overlay, and a 30-second watchdog
prevents an unresolved transition from blocking the interface indefinitely.
The image gate requires the project mark, three stack layers, and progress rail,
and rejects the retired grass, celestial-body, orbit, and rotating-ring scenes.
Reduced-motion mode retains a low-displacement layer pulse and progress-colour
cycle, so an operating-system accessibility preference does not leave the
transition visually frozen.

Authentication Service `0.4.35` preserves the established route, token,
identity, encrypted-provider configuration, SAML callback, and launch-wrapper
contracts while adding the reviewed provider-neutral OpenID Connect flow and
identity-link proof. Assembly verifies both the release archive and extracted
static binary by SHA-256, rejects unexpected archive members or links, and
requires the exact version output before replacing only
`/usr/bin/authentication-service.real`.

The Catalog snapshot retains every prior immutable Resource Scheduler template
revision and adds `v0.8.16` as a new revision. Its public image reference is
`ghcr.io/pasturestack/resource-scheduler:v0.8.16`; digest evidence remains in
the matching GitHub Release and is not exposed in the user interface. The
snapshot passed its full Python 3.14 integration suite and GitHub CodeQL run.

This release retains the authoritative storage validation introduced by the
previous release. An ordinary pending live check still disables Create. A
same-tick volume recheck that races with an already accepted click continues to
the server-side validation instead of becoming a stale client-side error.

The `volumepreflight` action keeps the real core add-on type set,
project-scoped authorization, authoritative create and upgrade validation, and
the creatable `volumePreflightInput` contract. The packaged-image gate rejects
the retired `String.prototype.dasherize` path. The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and complete active-host coverage.
Every successful selected-volume deletion refreshes the visible rows,
pagination, selected count, and controls immediately; failed rows remain
visible.

## Validation

The exact Web Console source passed 340 Chrome 151 browser tests plus source,
dependency, workspace, focused-transition, production-build,
reproducible-artifact, and visible-DOM gates. The Authentication Service release
passed its full race-enabled suite, two byte-identical builds, zero applicable
Critical or High findings, CycloneDX 1.7 SBOM gate, OpenVEX review, and GitHub
SLSA and SBOM attestation verification. Server assembly verifies the public
release checksums, archive roots, version markers, required licenses, branded
loading markers, and absence of the retired scene before producing the image.
Live deployment acceptance also checks `/ping`, local login, OpenID Connect,
MFA, authenticated route navigation, overlay dismissal, Catalog revision
discovery, Resource Scheduler continuity, container restart count, and rollback
readiness.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
