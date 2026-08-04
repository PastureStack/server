# PastureStack Server v1.6.346

Server v1.6.346 strengthens environment-wide host-port preflight for service
upgrades while retaining the reviewed host-storage pagination and bulk-removal
behavior from v1.6.345.

## Runtime components

- Orchestration Engine: `0.183.276`
- Orchestration Engine source: `90581d62c885eb56a0b1464ad2c8ed3743891695`
- Orchestration Engine artifact SHA-256:
  `64bc18a1654b73116dce89f29ede7b4c629a8c5af236b482ef95f50a78ed6376`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.57`
- Web Console source: `4888d0470836f120c526961d81552d969f5de24a`
- Web Console artifact SHA-256:
  `bc1f924dad134d99aa80eaa40e2c9762438b26a068c585ae35efc70a7d319f04`

## Corrected behavior

Active host-port owners anywhere in the environment block conflicting service
upgrades. Stopped owners remain explicit warnings. Start-first upgrades reserve
the service's current mappings without self-conflict, while changed mappings
remain blocked when the old and new tasks cannot coexist. Runtime inspection
echoes for the exact current container are ignored without weakening other live
host reservations.

The Web Console displays the environment, stack, service, scale, batch size,
start-first policy, requested mapping, and conflict owner through shared
accessible tooltips before saving an upgrade.

Host storage page sizes `10`, `25`, `50`, and `All` remain writable normalized
UI state. Each successful selected-volume removal immediately refreshes the
visible rows, selected count, and action state; failed rows remain visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
