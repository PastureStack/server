# PastureStack Server v1.6.353

Server v1.6.353 packages Web Console `1.6.56-pasturestack.62` to close the
live volume-preflight save race found by the authenticated browser acceptance
test against v1.6.352.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.62`
- Web Console source: `d1b59b25be45183a36c76b36c89d55c979fed87e`
- Web Console artifact SHA-256:
  `99aed13daa89bccc5043bfc944cf7cbac260f975a4a50ad84274f82542c28f50`

## Corrected behavior

An ordinary pending live check still disables Create. A same-tick volume recheck
that races with an already accepted click no longer becomes a stale
client-side validation error. The create or upgrade request continues to the
authoritative server validation, which repeats the complete path,
storage-driver, active-pool, host-coverage, existing-volume, and access-mode
checks before persisting the workload.

The packaged-image gate rejects both the retired
`String.prototype.dasherize` validation path and the obsolete client-side
`formVolumes.errors.preflightChecking` save blocker. Web Console CI passed
336/336 Chromium tests, including the focused save-race regression, and
produced two byte-for-byte identical production artifacts in GitHub Actions
run 31066699125.

The `volumepreflight` action keeps the real core add-on type set,
project-scoped authorization, authoritative create and upgrade validation, and
the creatable `volumePreflightInput` contract. The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and complete active-host coverage.
Every successful selected-volume deletion continues to refresh the visible
rows, pagination, selected count, and controls immediately; failed rows remain
visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
