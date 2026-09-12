# PastureStack Server v1.6.430

This packaging release pins the single official PastureStack Catalog to
`a181a2b86e5862077e62a6201f4bccff4c634ff9` (Catalog Templates
`v0.3.3`). It exposes Network Services revision 4 with Network Plugin Manager
`v0.8.15` and IPsec Overlay revision 4 with IPsec VXLAN Overlay Network
`v0.14.29`. The templates retain earlier revisions for existing installations
and use pure numeric image tags. No separate `pst-nft-qa` Catalog is required.

Both templates offer `auto`, native `nftables`, `iptables-nft`, and
`iptables-legacy` as explicit firewall-backend choices. `auto` detects the
host's existing Docker and firewall mode; it does not force legacy modules on
modern hosts or silently change a host's selected backend. Network Plugin
Manager owns its NAT and host-port rules; IPsec owns XFRM, routing, and tunnel
state. A plugin must not write another plugin's chains merely to pass a test.

The released plugin images and Catalog candidate passed their own source,
schema, rendering, and module-boundary checks. A disposable Ubuntu 26.04 VM
with Docker 29.8 exercised the three firewall modes without mixing their
tables. The 8080 deployment and two-host upgrade are separate operational
acceptance gates; this source note does not claim those gates passed until
their recorded results are available.

All other Server runtime components and Host API SHA-256 packaging remain at
`v1.6.429`. The release workflow still requires first start, restart, exact
image identity, merged-rootfs vulnerability and secret scan, SBOM, provenance,
and artifact attestation. Vendor-pending findings remain disclosed rather than
described as fixed without an upstream package release.

The inherited curl fix for `CVE-2026-8932`, glibc
`2.43-2ubuntu2.4`, and GNU coreutils `uniq` fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371` are unchanged. Ubuntu still
marks `CVE-2026-18374` as needing evaluation for Resolute. The inherited
OpenSSL closure for `CVE-2026-75803` and removal of the unreachable `diff3`
path for `CVE-2026-53910` are unchanged; unmatched vulnerability at any severity remains a release blocker.
