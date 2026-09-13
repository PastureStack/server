# Server v1.6.436

This release pins the single `pasturestack` Catalog source at
`4adf274d699a2f4e729f64a951a5846523e19acc` (Catalog Templates
`v0.3.8`). The default network templates select Network Plugin Manager
`v0.8.17` and IPsec/VXLAN Overlay `v0.14.34`; historical template versions
remain available to existing stacks. No `pst-nft-qa` catalog is added.

Network Plugin Manager exclusively owns host NAT, forwarding marks and
host-port hooks. The overlay plugin exclusively owns its IPsec, VXLAN, CNI
and route state. On a host using native nftables, iptables-nft or
iptables-legacy, the plugins must select the existing backend and must not
silently switch or mix backends. Rules are staged before replacing managed
hooks, and unrelated host firewall policy remains outside plugin ownership.

The Server application code and reviewed runtime components are unchanged
from `v1.6.435`. The release retains the digest-pinned `v1.6.431` transitional
build base, separate build stages and verified single-rootfs-layer final
image. Build and publication gates reject mismatched Catalog coordinates,
unreviewed source changes, a layered source candidate above 32 layers, or a
registry manifest that is not one layer. The GitHub Release carries the
matching SBOM, OpenVEX, image manifest and Host API SHA256 evidence.

Security fixes inherited unchanged from `v1.6.435` include curl's
`CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, the GNU coreutils `uniq`
fix `d64e35a8a4c0e4608321433e0d84d917e4e36371`, and the OpenSSL fix for
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
Vendor-pending findings remain recorded in matching SBOM and OpenVEX evidence;
unmatched vulnerability at any severity remains a release blocker.

Before production rollout, preserve the existing Server image, database,
named volumes and configuration. Verify `/ping`, authenticated API, the exact
Catalog pin, template rendering, managed host health and representative
cross-host traffic. Test the firewall backend already selected by each host;
do not enable legacy modules merely to make a new Ubuntu host pass. Keep the
previous Server image available until the replacement passes start, restart
and browser/API smoke checks.
