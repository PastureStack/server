# Server v1.6.434

This release pins Catalog Templates v0.3.6, whose IPsec Overlay template
version 7 uses the formally published v0.14.32 router. That router requests
one active IKE association per managed peer and cleans up only a superseded
association in the `DELETING` state after confirming a replacement with an
installed CHILD_SA. This addresses duplicate associations after simultaneous
peer reconnects without restarting the shared daemon or changing unrelated
peers, XFRM routes, host NAT, or host-port ownership.

The multi-stage build retains the digest-pinned, single-layer v1.6.431
transitional base. The source candidate remains bounded below 32 layers;
release validation checks runtime configuration, start/restart behavior, and
the final one-rootfs-layer image. The former 228-layer accumulation is not
reintroduced. A dedicated long-lived base remains future architecture work,
not a prerequisite for this fix.

Before updating a live Server, preserve the database, named volumes, prior
image, and rollback configuration. Verify `/ping`, authenticated API, Catalog
pin, managed hosts, and a real peer restart on the active Docker storage
driver. The isolated two-node IPsec tests and firewall-backend matrix do not
replace the live gate.

Security fixes inherited unchanged from v1.6.433 include curl's
`CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, GNU coreutils `uniq` fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, and OpenSSL closure for
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
Vendor-pending findings remain recorded in the matching SBOM and
OpenVEX evidence; unmatched vulnerability at any severity remains a release blocker.
This release does not claim an unpublished upstream fix.
