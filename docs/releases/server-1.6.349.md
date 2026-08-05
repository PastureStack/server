# PastureStack Server v1.6.349

Server v1.6.349 completes the volume and storage-driver preflight contract and
corrects host-storage pagination and live batch-removal updates while retaining
the network-aware port checks from v1.6.348.

## Runtime components

- Orchestration Engine: `0.183.279`
- Orchestration Engine source: `14c2d25323b5a8fe758dfda197283c1c63c04cb5`
- Orchestration Engine artifact SHA-256:
  `a59d7b8044066fa400d9882ebe6b05832e2b3a5c4d92b966c5b283ffc10cef6e`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.60`
- Web Console source: `d9e6ad05208ba940304b29312003b0c2849ea686`
- Web Console artifact SHA-256:
  `288b2597526d35fe8db3d31b90d098ff99809ddb7a9b87de19960f0750aa075b`

## Corrected behavior

The Web Console provides a storage-driver selector and accessible volume-path
completion. Suggestions combine environment mounts, driver-backed volumes,
current form values, and translated defaults; prefix matches are prioritized,
naturally sorted, and limited to eight entries. Keyboard navigation supports
the arrow keys, Enter, Tab, and Escape.

The server exposes the project-scoped `volumepreflight` action and repeats the
same validation during container creation, service creation, and service
upgrade. Invalid paths, unsafe bind mounts, duplicate targets, unavailable
drivers, missing storage pools, incomplete host coverage, incompatible existing
volumes, and invalid NFS contracts are rejected before persistence. The
`pasturestack-nfs` driver requires environment scope, `multiHostRW`, and active
coverage on every eligible host.

The host-storage controller owns a writable page-size value. Selecting `All`
reports semantic value `0` through an explicit callback rather than writing
through a caller-owned or computed input, preventing Ember argument-setter
failures. Every successful selected-volume deletion immediately updates the
visible rows, pagination, selected count, and controls; failed rows remain
visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
