# PastureStack Server v1.6.431

This packaging release fixes a real compatibility failure in the published
Server image: the inherited `v1.6.430` manifest has 228 filesystem layers,
and a Docker host using the classic `overlay2` image store rejected it with
`failed to register layer: max depth exceeded`. The runtime source, Catalog
pin, plugin versions, and application behavior remain those of `v1.6.430`.

The release workflow exports the exact assembled root filesystem, imports it
as one layer, and reapplies every declared environment variable, port, label,
user, working directory, volume, entrypoint, command, and stop signal. It
rejects unsupported image configuration and compares the resulting runtime
configuration with the layered candidate. The normal first-start, restart,
API, Host API package, merged-rootfs security, SBOM, and provenance gates run
against the flattened candidate before publication. This is an image-format
repair, not a shortcut that changes a host's Docker storage driver.

The firewall-plugin ownership contract remains strict: Network Plugin Manager
owns its NAT and host-port chains; IPsec owns XFRM, routes, and tunnels;
Network Policy Manager owns only its policy table. None may alter another
plugin's chains or globally switch a host's firewall backend to make a test
pass. The two-host, three-backend, and 8080 operational results are separate
acceptance evidence and must not be inferred from the packaging workflow.

The inherited vendor-pending Ubuntu findings are unchanged. They remain
tracked in the matching SBOM/OpenVEX evidence; this release does not claim
upstream security fixes that have not been published.

The inherited curl fix for `CVE-2026-8932`, glibc `2.43-2ubuntu2.4`, and GNU
coreutils `uniq` fix `d64e35a8a4c0e4608321433e0d84d917e4e36371` are
unchanged. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
The inherited OpenSSL closure for `CVE-2026-75803` and removal of the
unreachable `diff3` path for `CVE-2026-53910` are unchanged; unmatched vulnerability at any severity remains a release blocker.
