# PastureStack Server v1.6.354

Server v1.6.354 packages Web Console `1.6.64` to correct a loading overlay
that could remain visible after rapid navigation, an aborted request, or a
failed route transition.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Web Console: `1.6.64`
- Web Console source: `35a04a42dafee88d14c522a5b06d24ee6fb438e8`
- Web Console artifact SHA-256:
  `65f01e4194274353234510c95eac11c070e27e06c808b61522ed25d06e6ce1fc`

## Corrected behavior

The Web Console now uses a deterministic loading-overlay lifecycle. A
monotonic transition identifier ensures that stale completion callbacks from
overlapping transitions cannot show or hide the current overlay. Successful,
rejected, and aborted transitions all release the overlay, and a 30-second
watchdog prevents an unresolved transition from blocking the interface
indefinitely. The packaged-image gate rejects the retired nested fade callback
and verifies the new lifecycle markers in the minified production artifact.

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

The exact Web Console source passed its source, dependency, workspace, focused
overlapping-transition, rejected-transition, production-build, and
reproducible-artifact gates. Server assembly verifies the public release asset
checksum and the corrected minified runtime before producing the image. Live
deployment acceptance additionally checks `/ping`, login, authenticated route
navigation, overlay dismissal, container restart count, and rollback
readiness.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
