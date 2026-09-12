# Server v1.6.432

This release advances the pinned PastureStack Catalog for the IPsec overlay
router's bounded host-port handoff, and changes the Server build base to the
digest-pinned, flattened v1.6.431 runtime image. The multi-stage Ubuntu security,
Console Broker, and release-artifact build stages remain separate and reviewed.
The source Docker build must no longer inherit the 207 historical layers of
v1.6.411; the release process still validates the layered candidate, flattens
the final runtime, and checks startup, restart, API behavior, SBOM, and security
evidence. This is a transitional base-chain correction, not a claim that a
dedicated long-lived runtime base has already replaced full-product inheritance.

The Catalog pin and official image digest are recorded in the source and
release evidence. Before changing a live control plane, preserve its database,
volumes, and previous image, then verify `/ping`, authentication, Catalog
availability, and a managed host on the target Docker storage driver.

Security fixes inherited unchanged from v1.6.431 include curl's
`CVE-2026-8932` closure, glibc `2.43-2ubuntu2.4`, GNU coreutils `uniq` fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, and OpenSSL closure for
`CVE-2026-75803`. The unreachable `diff3` path for `CVE-2026-53910` remains
removed. Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute.
Known vendor-pending findings stay in the matching SBOM and OpenVEX evidence;
unmatched vulnerability at any severity remains a release blocker.
