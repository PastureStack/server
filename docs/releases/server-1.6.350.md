# PastureStack Server v1.6.350

Server v1.6.350 restores the project-scoped schema authorization required by
the authoritative volume and storage-driver preflight action while retaining
the reviewed runtime and Web Console from v1.6.349.

## Runtime components

- Orchestration Engine: `0.183.280`
- Orchestration Engine source: `dbcf3b091f686de6339df00d2e20a27cbbfd713a`
- Orchestration Engine artifact SHA-256:
  `9c97c528898e019359b64b6ee44452b8b8e74ac57cdcfe9cabae7c8df955a0a3`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.60`
- Web Console source: `d9e6ad05208ba940304b29312003b0c2849ea686`
- Web Console artifact SHA-256:
  `288b2597526d35fe8db3d31b90d098ff99809ddb7a9b87de19960f0750aa075b`

## Corrected behavior

The project schema exposes `volumePreflightInput` for action requests and keeps
`volumePreflightResult` and `volumePreflightIssue` read-only. The Server image
gate checks these exact permissions inside the packaged Engine artifact, so a
source-only fix cannot be released without the matching runtime schema.

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

Two clean Java 25 Engine release builds produced the same SHA-256 before this
Server release was assembled.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
