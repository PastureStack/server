# PastureStack Server v1.6.355

Server v1.6.355 packages Web Console `1.6.66`, the reviewed Catalog snapshot,
and the Resource Scheduler catalog revision without changing the established
Orchestration Engine or Node Agent runtime coordinates.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Web Console: `1.6.66`
- Web Console source: `dd5f6428ae2bebbc3b427569906be43b419c2c99`
- Web Console artifact SHA-256:
  `826f68413598f1fcc8c6983f487cb357a4a1a46af2b65e7059f7c5c8d335054f`
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

The exact Web Console source passed its source, dependency, workspace,
focused transition, production-build, reproducible-artifact, and visible DOM
gates. Server assembly verifies the public release checksum, archive root,
version marker, required licenses, branded loading markers, and absence of the
retired scene before producing the image. Live deployment acceptance also
checks `/ping`, login, authenticated route navigation, overlay dismissal,
Catalog revision discovery, Resource Scheduler continuity, container restart
count, and rollback readiness.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
