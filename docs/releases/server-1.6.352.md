# PastureStack Server v1.6.352

Server v1.6.352 packages Web Console `1.6.56-pasturestack.61` to fix the
save-time validation-label failure exposed by the first authenticated volume
creation acceptance against v1.6.351.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.61`
- Web Console source: `b97d635b61f0daf56cbd20b6d65352a9f8866f20`
- Web Console artifact SHA-256:
  `ee6f8aaf0784823edf57ae8c12e7f7cd861a5c8083a14de96fc655fc96227a1f`

## Corrected behavior

Schema validation no longer calls the retired `String.prototype.dasherize`
extension. A native formatter handles camel-case, acronym, underscore, and
space-separated field names, preventing container and service forms from
remaining in the saving state while formatting an untranslated validation
field label.

The packaged-image gate requires the native acronym boundary and rejects the
legacy prototype call. Web Console CI passed 335/335 Chromium tests, including
the focused `camelToTitle` regression, and produced two byte-for-byte identical
production artifacts.

The `volumepreflight` action keeps the real core add-on type set,
project-scoped authorization, authoritative create and upgrade validation, and
the creatable `volumePreflightInput` contract. The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and complete active-host coverage;
these requirements remain
unchanged from v1.6.351. Every successful selected-volume deletion continues
to refresh the visible rows, pagination, selected count, and controls
immediately; failed rows remain visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
