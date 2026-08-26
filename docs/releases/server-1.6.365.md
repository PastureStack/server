# PastureStack Server v1.6.365

Server v1.6.365 removes unused build and administration tooling from the
production container while preserving the application, database schema,
public control-plane API, orchestration behavior, and bundled PastureStack
service versions.

The final runtime no longer contains the in-container source-build path, SSH
client, tar, privileged mount and login tools, journald, user-mapping tools,
GPG verifier, or `unexpand`. Git 2.53.0 remains because Catalog Service uses
it at runtime for its pinned HTTPS clone, fetch, and checkout operations; the
separate SSH client remains absent. The only coreutils binary rebuilt from
upstream source is `uniq`; it is GNU coreutils 9.11 with upstream fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371` for CVE-2026-56391 and a
multibyte `--check-chars` regression test. The active zlib shared library is
rebuilt from verified upstream zlib 1.3.2 source.

The release evidence keeps the unfiltered merged-rootfs Trivy result and a
separate OpenVEX-filtered result. VEX statements are scoped to exact package
PURLs and explain either the installed fixed version, the replacement binary,
or the exact vulnerable executable path removed from this runtime. Any new or
unmatched vulnerability at any severity remains a release blocker. Embedded
secrets also remain a release blocker.

The release workflow starts the exact candidate with fresh data volumes,
verifies HTTP 200 / `pong`, restarts it and verifies `pong` again, then
publishes the immutable image, CycloneDX SBOM, provenance and SBOM
attestations, checksums, raw and VEX-filtered scan evidence, and the VEX
document used by the gate.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
