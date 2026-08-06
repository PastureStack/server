# PastureStack Server v1.6.351

Server v1.6.351 registers the complete volume-preflight schema model in the
live runtime type set while retaining the project-scoped authorization and
reviewed runtime from v1.6.350.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.60`
- Web Console source: `d9e6ad05208ba940304b29312003b0c2849ea686`
- Web Console artifact SHA-256:
  `288b2597526d35fe8db3d31b90d098ff99809ddb7a9b87de19960f0750aa075b`

## Corrected behavior

The Engine now registers `volumePreflightInput`, `volumePreflightResult`, and
`volumePreflightIssue` through the real core add-on type set. The project
schema exposes `volumePreflightInput` for action requests and keeps the result
and issue schemas read-only. Source, release-artifact, and Server-image gates
verify both requirements, so packaged authorization text cannot conceal a
missing live action schema.

The Web Console can call `volumepreflight` before saving container and service
forms. The server repeats the same validation during container creation,
service creation, and primary or sidekick service upgrades. Invalid paths,
unsafe bind mounts, duplicate targets, unavailable drivers, missing storage
pools, incomplete host coverage, incompatible existing volumes, and invalid
NFS contracts remain rejected before persistence.

The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and
active coverage on every eligible host. Every successful selected-volume deletion
continues to refresh the visible rows, pagination, selected count, and controls
immediately; failed rows remain visible.

A regression test against the real core add-on type set failed before the
registration fix and passed after it. The complete Java 25 Engine release
reactor and packaged-artifact gate passed before this Server release was
assembled.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
