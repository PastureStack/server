# Server v1.6.438

This release pins the official `pasturestack` Catalog at
`d99c9c79e3f193ab3c252d73c763a72133989677` (Catalog Templates
`v0.3.10`). Network Services version 6 selects Network Plugin Manager
`v0.8.18`; Layer 2 Flat Network version 4 selects the shared CNI runtime
`v0.14.36`. Historical numeric template versions remain available to existing
stacks, and no duplicate QA Catalog is distributed.

Network Plugin Manager restores symmetric VXLAN forwarding when published
host ports coexist with the overlay. The Layer 2 template now packages a
bridge CNI that honors `skipBridgeConfigureIP`; it leaves an
operator-configured bridge address unchanged instead of adding a conflicting
gateway address. These corrections remain within module boundaries: Network
Plugin Manager owns platform NAT, forwarding and host-port rules, while the
network driver owns its CNI, overlay and route state.

`FIREWALL_BACKEND=auto` follows Docker's active firewall implementation. A
host using Docker's native nftables backend remains on native nftables; a host
using Docker's iptables driver retains the frontend that owns Docker's active
NAT chain, whether iptables-nft or iptables-legacy. The plugins do not select a
backend from the Ubuntu version, load a legacy module as a fallback, mix two
backends, or change the host's global forwarding policy.

The Server application components and one-layer runtime packaging are
unchanged from `v1.6.437`. The digest-pinned multi-stage build, Host API
SHA-256 chain, runtime smoke checks, SBOM, OpenVEX and vendor-pending evidence
remain publication gates. Unmatched vulnerability findings are not waived to
force a release.

Inherited security fixes remain part of the exact runtime: curl closes
`CVE-2026-8932`, glibc is `2.43-2ubuntu2.4`, GNU coreutils `uniq` carries the
reviewed upstream fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, and OpenSSL closes
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still lists `CVE-2026-18374` as needing evaluation for Resolute,
so it remains represented in the release evidence rather than being silently
dismissed. Vendor-pending findings remain recorded in matching SBOM
and OpenVEX evidence; unmatched vulnerability at any severity remains a release blocker.

Before production rollout, preserve the prior image, database, named volumes
and configuration. Verify `/ping`, authenticated API, the exact Catalog pin,
rendered templates and managed host health. Network validation must cover the
backend already active on each host, DNS and egress, Metadata, host ports,
cross-host traffic, container recreation, Docker restart and host reboot.
Keep the previous image until the replacement passes start, restart and
browser/API smoke checks.
