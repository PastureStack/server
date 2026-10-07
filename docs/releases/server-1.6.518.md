# Server v1.6.518

Status: Server source candidate; Catalog `v0.3.13` and Web Console `1.6.180`
are published and pinned. Server publication and real-host acceptance remain pending.

## Scope

Pins published Catalog `v0.3.13` source commit
`b6b658888fce50d3ec217eb4eba0f26ab0113baf`, with Network Services revision `10` / template
`v0.3.8` referencing Network Plugin Manager `v0.8.22`. The manager reconciles
the CNI configuration supplied by Metadata during a managed infrastructure
upgrade. A historical `10-rancher.conf` can otherwise remain active after
Metadata switches to `10-pasturestack.conf`, causing both configurations to
be executed.

The candidate manager validates and serializes all desired configurations
before changing active files. It installs each desired file atomically, then
retires the unrequested historical file only when its network name, bridge
type and IPAM type exactly match the known legacy triplet:
`rancher-cni-network`, `rancher-bridge`, `rancher-cni-ipam`. The requested native
counterpart must match `pasturestack-cni-network`, `pasture-bridge`,
`metadata-cni-ipam`.

The retired file retains its original contents as
`10-rancher.conf.pasturestack-retired`, outside the active `.conf` / `.json`
set. The reverse transition to the exact legacy Metadata contract retires
the known native counterpart as `10-pasturestack.conf.pasturestack-retired`.
Legacy Metadata remains supported. Unrelated administrator configurations
are preserved; malformed or ambiguous old configurations, non-regular files
and conflicting backup contents fail reconciliation explicitly.

Atomicity applies to each file replacement, not to the complete configuration
bundle. Desired files are installed sequentially, and retirement follows
successful desired-file writes. A failure during a multi-file update can
leave earlier replacements in place for the next reconciliation attempt.
The recoverable retired copy does not make the whole update transactional.

The audit broker accepts explicit `timeScope=all` to query all retained audit
log time without the implicit 24-hour lower bound. Requests without that
marker or explicit dates retain the default 24-hour window. Explicit dates
remain authoritative even with `timeScope=all`: both boundaries are required,
the interval remains `[from,to)`, and the maximum explicit range is 366 days.
Unknown time scopes return HTTP 400 with `invalid_time_scope`.

Query and export use the same token-owner authorization, environment and
record filters. The 20,000-row scan cap and 10,000-row export cap remain in
place; database retention is unchanged. JSON and XLSX exports describe the
all-retained scope without inventing date boundaries. Web Console `1.6.180`
forwards the all-time marker through both the audit query and export routes;
explicit date filters remain intact.

Server assembly also prepares the reviewed Catalog source pin and release
identity. Orchestration Engine `v0.183.333`, Catalog Service `0.20.12`,
Authentication Service `0.4.42`, HAProxy and OIDC contracts remain unchanged.
The Web Console pin is `1.6.180`, source
`637604b38401b19d2c9ef73d5729d356bb80c8e6`, with archive
`web-console-1.6.180.tar.gz` SHA-256
`a367bd6907281298a8e2bf0f3ad0444083db06062f3a1521db573cc5606d274e`.
Four build stages and the existing single final runtime layer publication flow
are retained.

## Publication and acceptance boundaries

No Server `v1.6.518` image digest, publication run or real-host acceptance is
claimed here. Component source tests do not establish a passing managed
infrastructure upgrade, workload traffic, Metadata/DNS, host-port behavior,
restart recovery or rollback on actual hosts. Those acceptance results remain
pending. Existing historical HOLDs and incomplete coverage remain unchanged.

Catalog PR #17 was normally merged, and
[Catalog CI 37564407383](https://github.com/PastureStack/catalog-templates/actions/runs/37564407383)
passed at the pinned source. The fixed Web source passed
[Validate 37564108185](https://github.com/PastureStack/web-console/actions/runs/37564108185);
the official numeric [Web Console 1.6.180 release](https://github.com/PastureStack/web-console/releases/tag/1.6.180)
contains the pinned archive. No placeholder commit is submitted. Operator
Catalog overrides and deployed
infrastructure stacks are not automatically upgraded by changing the image
defaults. VEX and vendor-pending metadata change only their Server release
identity; vulnerability decisions and existing review deadlines are retained.

README and Compose install examples continue to use the actually published
numeric tag `v1.6.517` until the official `v1.6.518` image and release have been
published and verified. Candidate preparation is separate from that install
contract. Existing volumes, environment overrides and prior rollback evidence
must be preserved; see [the upgrade guide](../upgrades/README.md).
