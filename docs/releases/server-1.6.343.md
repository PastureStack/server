# PastureStack Server v1.6.343

This release supersedes `v1.6.342`. Formal browser acceptance of that image
found two Web Console runtime regressions: legacy component action dispatch
could reject port-preflight closure callbacks, and choosing All in the host
storage table could write through a read-only computed preference. The Server,
Orchestration Engine, Node Agent, database, and workload contracts were not
affected.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.341`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.343`
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
- Web Console: `1.6.56-pasturestack.55`
- Web Console source: `b96f433db2cfce1c2c1815f76046f3e707706f2f`
- Web Console artifact SHA-256:
  `2aa211fc58dcd5544116d23f56ce25f7a51c8354fb103eac8f1c8426ced94ed0`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30848892606`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Corrected Web Console behavior

Port-preflight closure actions are invoked directly. Optional callbacks are
safe when absent, so the create, service, and upgrade port editors can report
available, blocked, warning, checking, and unknown states without a legacy
Ember action-dispatch exception.

Page-size preferences expose normalized read/write computed properties. The
host storage table can store the semantic All value, while ordinary tables
continue to reject unsupported values. Selected-volume removal updates rows
and selection count after each successful API response. When removal empties
the current page, the table moves immediately to the last valid page.

The immutable Web Console validation run passed 317 browser tests with zero
failures and produced two byte-identical production packages. Image assembly
also verifies the compiled callback, preference-setter, and page-clamping
markers before publication.

## Preserved runtime behavior

Authoritative host-port conflict preflight remains backed by current
control-plane ownership and live Node Agent inspection. Running conflicts
block submission, stopped conflicts warn, and unknown inspection is never
reported as safe. Managed, host, bridge, wildcard-address, specific-address,
and sidekick combinations use the same normalized evaluation path.

Authentication Service, Catalog Service, API Explorer, vSphere CLI bundle,
WebSocket proxy, terminal broker, persistent volume layout, database schema,
host registration, and existing workload identities remain unchanged from the
reviewed `v1.6.341` base composition.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
