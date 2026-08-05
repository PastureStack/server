# PastureStack Server v1.6.348

Server v1.6.348 adds authoritative volume and storage-driver preflight while
retaining the network-aware port checks and host storage table corrections from
v1.6.347.

## Runtime components

- Orchestration Engine: `0.183.278`
- Orchestration Engine source: `cb212671ccd0a2e91b42c0bf3e0ed62eac862ac6`
- Orchestration Engine artifact SHA-256:
  `b9e2d85575131c78070ba9ea8b9d4757ef3cfbc4e70162c9fcf1797e66634ba8`
- Node Agent: `0.13.22`
- Web Console: `1.6.56-pasturestack.59`
- Web Console source: `0aad50152499619bcef763a130bbc66cae926929`
- Web Console artifact SHA-256:
  `6f56f23d7f45372ea981e257f5145ec5fc4b0c9e92f721a15441d5a417f0841e`

## Corrected behavior

The Web Console provides a storage-driver selector and accessible volume-path
completion. Suggestions are naturally sorted, prioritize prefix matches, and
are limited to eight entries. Live checks include the selected driver, data
volumes, requested host, service or instance identity, stack, scale, upgrade
batch size, and start-first behavior.

The server exposes the project-scoped `volumepreflight` action and repeats the
same validation during container creation, service creation, and service
upgrade. Invalid paths, unsafe bind mounts, duplicate targets, unavailable
drivers, missing storage pools, incomplete host coverage, incompatible existing
volumes, and invalid NFS contracts are rejected before persistence. The
`pasturestack-nfs` driver requires environment scope, `multiHostRW`, and active
coverage on every eligible host.

Storage table page-size selection retains `10`, `25`, `50`, and `All` without
writing to caller-owned inputs. Every successful selected-volume deletion
immediately updates the visible rows, pagination, selected count, and controls;
failed rows remain visible.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
