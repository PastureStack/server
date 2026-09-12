# Server v1.6.433

This release targets the signed Catalog Templates `v0.3.5` commit, whose
IPsec Overlay template version `6` references the formally published
`v0.14.31` router. When one peer is temporarily unavailable during a host or
Docker restart, its missing CHILD_SA is retried by the existing periodic
health reconciliation. The shared charon daemon is not restarted for that
ordinary peer outage, preserving associations with other healthy peers.
The separate stale-local-identity recovery path remains unchanged. IPsec
continues to own XFRM and routes, while Network Plugin Manager alone owns
host NAT, forwarding marks, and host ports.

The multi-stage build retains the digest-pinned, single-layer `v1.6.431`
transitional base. The layered source candidate must remain below 32 layers;
release validation compares runtime configuration, starts and restarts the
candidate, then publishes a one-rootfs-layer final image with SBOM and scan
evidence. This controls the former 228-layer accumulation without claiming a
dedicated long-lived base has already been designed or validated.

Before updating a live Server, preserve its database, named volumes, prior
image, and rollback configuration. Verify `/ping`, authenticated API, Catalog
pin, managed hosts, and a real peer restart on the active Docker storage
driver. Isolated firewall-backend tests do not substitute for that live gate.

Security fixes inherited unchanged from v1.6.432 include curl's
`CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, GNU coreutils `uniq` fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, and OpenSSL closure for
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
Known vendor-pending findings stay in the matching SBOM and OpenVEX evidence;
unmatched vulnerability at any severity remains a release blocker. This
release does not claim an upstream fix that has not been published.
