# Server v1.6.435

This release targets Catalog Templates v0.3.7, whose IPsec Overlay template
version 8 selects router v0.14.33. A live two-host rollout of v1.6.434 had
left two established IKE associations for one peer even though traffic was
working. The new router leaves missing-CHILD recovery to the existing IPsec
health reconciler and conservatively removes an old, zero-traffic duplicate
only when exactly one other installed association for that managed peer has
traffic. Recent or ambiguous associations are not removed. Network Plugin
Manager remains the sole owner of host NAT, forwarding marks, and host-port
rules; this change does not alter the selected Docker firewall backend.

The release retains the digest-pinned v1.6.431 transitional build base,
multi-stage source packaging, and final one-rootfs-layer image. The build
gate continues to reject source candidates above 32 layers. This is a
bounded correction to the former 228-layer accumulation, not a replacement
for a dedicated long-lived runtime base. Publication also verifies that the
registry manifest has exactly one layer; local flattening alone is not the
release evidence. Registry manifest, image config, and local image IDs are
distinct coordinates and are not substituted for one another.

Before a live upgrade, preserve the current Server image, database, named
volumes, and runtime configuration. First verify the IPsec image and Catalog
revision, then `/ping`, authenticated API, Catalog pin, both managed hosts,
encrypted traffic in both directions, one established IKE/CHILD association
per peer, and recovery after a peer restart. A passing isolated two-node
test does not substitute for that live gate. Keep the prior service usable
as a rollback point until the new image passes its own start and restart.

Security fixes inherited unchanged from v1.6.434 include curl's
`CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, GNU coreutils `uniq` fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, and OpenSSL closure for
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
Vendor-pending findings remain recorded in the matching SBOM and
OpenVEX evidence; unmatched vulnerability at any severity remains a release blocker.
This release does not claim an unpublished upstream fix.
