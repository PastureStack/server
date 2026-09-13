# Server v1.6.437

This release pins the official `pasturestack` Catalog at
`9d487b1cf3681e6718058b456d218b7742d7b96b` (Catalog Templates
`v0.3.9`). Its latest IPsec/VXLAN template selects Overlay `v0.14.35`;
the Network Services template continues to select Network Plugin Manager
`v0.8.17`. Historical template revisions remain available to existing
stacks. No duplicate QA Catalog is distributed.

The overlay update retries a transient TCP port-80 bind conflict during
host-port handoff for at most 90 seconds. It does not change Network Plugin
Manager's ownership of NAT, forwarding marks or host-port rules; the overlay
still owns only IPsec, VXLAN, CNI and route state. A host's actual firewall
backend—native nftables, iptables-nft or iptables-legacy—must be detected
and retained; the plugins must not silently switch or mix backends.

The Server application components are unchanged from `v1.6.436`. The
digest-pinned transitional build base, separate build stages, verified
single-rootfs-layer final image, Host API SHA256 chain, and matching
SBOM/OpenVEX release evidence remain required. Inherited security fixes
include curl's `CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, the GNU
coreutils `uniq` fix `d64e35a8a4c0e4608321433e0d84d917e4e36371`, and
the OpenSSL fix for `CVE-2026-75803`. The unreachable `diff3` path for
`CVE-2026-53910` remains removed. Ubuntu still marks `CVE-2026-18374` as
needing evaluation for Resolute. Vendor-pending findings remain recorded in
matching SBOM and OpenVEX evidence; unmatched vulnerability at any severity remains a release blocker.

Before production rollout, preserve the prior image, database, named volumes
and configuration. Check `/ping`, authenticated API, the exact Catalog pin,
rendered templates and managed host health. On isolated test hosts, verify
host registration, Catalog activation, DNS/egress, Metadata, host ports,
cross-host traffic, container recreation, Docker restart and host reboot
using the backend already active on each host. Keep the previous image until
the replacement passes start, restart and browser/API smoke checks.
