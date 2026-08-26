# PastureStack Server v1.6.362

Server v1.6.362 advances the reproducible Ubuntu 26.04 package snapshot from
2026-08-25 to 2026-08-26. This includes OpenSSL `3.5.5-1ubuntu3.4`, replacing
`3.5.5-1ubuntu3.3` after the final-rootfs scan identified the newer Canonical
security package as available.

The application code, database schema, public control-plane API contract,
Orchestration Engine 0.183.281, Node Agent 0.13.22, Authentication Service
0.4.36, Catalog Service 0.20.11, Web Console 1.6.70, and API Explorer 1.1.17
are unchanged from v1.6.361.

The release workflow builds the committed revision once, starts it with fresh
data volumes, verifies HTTP 200 / `pong`, restarts it and verifies `pong` again,
then scans the exported final root filesystem. Critical and High findings and
embedded secrets remain release blockers. The workflow publishes the exact
image, CycloneDX SBOM, provenance and SBOM attestations, checksums, and scan
evidence.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
