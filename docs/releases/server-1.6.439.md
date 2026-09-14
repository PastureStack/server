# Server v1.6.439

This release pins the official `pasturestack` Catalog at
`b083630a34d1a9a1cf48006389187bcf90a6b4da` (Catalog Templates
`v0.3.11`). Network Services version 7 selects Network Plugin Manager
`v0.8.19`. Historical numeric template versions remain available to existing
stacks, and no duplicate QA Catalog is distributed.

Network Plugin Manager now rejects malformed or conflicting bridge metadata
before touching host firewall state and binds managed forwarding to the exact
bridge and subnet. For published host ports it installs a raw loopback guard
before enabling `route_localnet`, records the operator's original per-bridge
value under `/run`, and restores that value when the bridge no longer requires
the setting. Failed reconciliation leaves the prior working hooks in place.

The module boundary remains explicit: Network Plugin Manager owns platform
host NAT, forwarding, and host-port rules. Network drivers own their CNI,
overlay, and route state; they do not create a second host-NAT owner or patch
the manager's firewall chains.

`FIREWALL_BACKEND=auto` follows Docker's active firewall implementation. A
host using Docker's native nftables backend remains on native nftables; a host
using Docker's iptables driver retains the frontend that owns Docker's active
NAT chain, whether iptables-nft or iptables-legacy. A mismatched or ambiguous
state fails safely. The plugins do not infer from Ubuntu version, load legacy
modules as a fallback, mix backends, or change global forwarding policy.

The isolated Ubuntu 26.04.1 and Docker 29 acceptance covered native nftables,
iptables-nft, and iptables-legacy, including DNS, Metadata, egress,
bidirectional cross-host flat-network traffic, published host ports, loopback
isolation, Docker restart, host reboot, and restoration to the original
backend. Catalog validation additionally renders and indexes all retained
plugin templates and enforces the single firewall-owner contract.

The Server application components and one-layer runtime packaging are
unchanged from `v1.6.438`. The digest-pinned multi-stage build, Host API
SHA-256 chain, runtime smoke checks, SBOM, OpenVEX, and vendor-pending evidence
remain publication gates. Unmatched vulnerability findings are not waived to
force a release.

Before production rollout, preserve the prior image, database, named volumes,
and configuration. Verify `/ping`, authenticated API, the exact Catalog pin,
rendered templates, and managed host health. Keep the previous image until the
replacement passes start, restart, and browser/API smoke checks.
