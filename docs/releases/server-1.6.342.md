# PastureStack Server v1.6.342

This release retains the complete `v1.6.341` database, authentication,
authorization, Catalog snapshot, API Explorer, terminal broker, storage-table,
and workload behavior. It updates the Orchestration Engine, embedded Web
Console, and distributable Node Agent together to add authoritative host-port
conflict preflight without recreating existing workloads.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.341`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.342`
- Orchestration Engine: `0.183.274`
- Orchestration Engine source:
  `e4bb32f72f409de4fa78079fd28a4eced2dcb681`
- Orchestration Engine artifact SHA-256:
  `9280d338fa4e1f2852c40240997f6eec51db1a01a7920708f8e766689037aec8`
- Node Agent: `0.13.22`
- Node Agent source: `d370dc6772aea00381a97769b9bf827f35440656`
- Node Agent Linux artifact SHA-256:
  `4272c9005ea70c0087668ad9f179bfdc7f277801c938ba55a4fc8c2d1d057b49`
- Node Agent Windows artifact SHA-256:
  `36230c05845c6895988edc06c1d8094cccd66899c2f268e3eb7644ca1e7b7c39`
- Node Agent validation run:
  `https://github.com/PastureStack/node-agent/actions/runs/30843817339`
- Web Console: `1.6.56-pasturestack.53`
- Web Console source: `f1fa37929c134f9adf64e7e8ed4be8f9a7d84bdd`
- Web Console artifact SHA-256:
  `8c036469d3d5bd02cadb1c10d643475c1ee3651159d69cf4400d3d1fb4caebad`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30836616394`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Authoritative port preflight

The project API exposes a `portpreflight` action backed by both current
control-plane ownership records and live Node Agent inspection. The result
identifies environment, stack, service, container, host, state, protocol,
bind address, and public endpoint when those values are available. An unknown
inspection result is reported as unknown and is never treated as proof that a
port is free.

Running conflicts block creation or upgrade. A conflict owned only by a stopped
container remains visible as a warning so an operator can make an informed
choice. Address overlap follows Docker bind semantics: wildcard IPv4 or IPv6
bindings overlap specific addresses, while distinct specific addresses do not.
Managed, host, bridge, and sidekick combinations use the same normalized
evaluation path.

## Web Console behavior

The ports editor performs debounced preflight against the selected host and
current project. It displays available, warning, blocked, checking, and unknown
states without rapidly rearranging the form. Submit stays disabled while a
request is pending or a running conflict is present. The same validation is
used by container creation, service creation, and service upgrade flows.

All 13 reviewed production locales include the new state, conflict, endpoint,
and recovery text. Traditional Chinese uses Taiwan-localized terminology and
layout. Existing natural sorting, pagination, column selection, storage-volume
bulk refresh, and host-container relationship fixes remain compiled into the
same Web Console artifact.

## Embedded Node Agent artifacts

The Linux and Windows Node Agent packages are embedded under
`/usr/share/cattle/artifacts`. Runtime properties point to these local files,
so an operator does not need to run an additional file server. The public
Server image continues to expose semantic version coordinates only. The
Windows package remains an artifact candidate and does not by itself establish
Windows host support.

## Preserved components

Image assembly proves that Authentication Service, Catalog Service, API
Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker are unchanged
from `v1.6.341`. Existing Server-specific schema and database compatibility
overlays are reapplied to the reviewed Engine artifact. No database schema,
account, permission, authentication policy, host registration, Docker socket,
Catalog template, persisted volume, or existing workload identity is changed
by this patch.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Node Agent tests pass with a real disposable block device for per-device I/O
  validation; no character device or skipped compatibility assertion is used.
- Two clean GitHub Actions builds produce identical normalized runtime payload
  and image configuration digests.
- Every downloaded component matches its pinned SHA-256 value and public source
  commit.
- API acceptance covers free, running-conflict, stopped-conflict, and unknown
  inspection results across wildcard and specific bind addresses.
- Browser acceptance covers create, service, and upgrade views in English and
  Traditional Chinese.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
