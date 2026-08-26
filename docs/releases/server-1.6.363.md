# PastureStack Server v1.6.363

Server v1.6.363 replaces Ubuntu 26.04's default uutils provider with the
distribution-supported GNU coreutils provider. The final image no longer
contains `rust-coreutils` 0.8.0 or `coreutils-from-uutils`; this closes the
cluster of uutils findings observed in the v1.6.362 merged-rootfs scan while
retaining Ubuntu's supported `coreutils` dependency contract.

The application code, database schema, public control-plane API contract,
Orchestration Engine 0.183.281, Node Agent 0.13.22, Authentication Service
0.4.36, Catalog Service 0.20.11, Web Console 1.6.70, and API Explorer 1.1.17
are unchanged from v1.6.362.

The release workflow builds the committed revision once, verifies the GNU
provider and absence of the Rust provider, starts the image with fresh data
volumes, verifies HTTP 200 / `pong`, restarts it and verifies `pong` again,
then scans the exported final root filesystem. Critical and High findings and
embedded secrets remain release blockers. The workflow publishes the exact
image, CycloneDX SBOM, provenance and SBOM attestations, checksums, and scan
evidence.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
