# PastureStack Server v1.6.361

Server v1.6.361 packages the security and runtime maintenance merged after
v1.6.360 without changing the stored database schema or the public control-plane
API contract.

The Console Broker now sanitizes attacker-controlled error text before writing
logs. Runtime assembly uses the current digest-pinned Ubuntu 26.04 base and the
2026-08-25 Canonical package snapshot. The default load-balancer service is
v0.9.27, matching the reviewed controller and Orchestration Engine defaults.
Authentication Service 0.4.36, Catalog Service 0.20.11, Orchestration Engine
0.183.281, Node Agent 0.13.22, Web Console 1.6.70, and API Explorer 1.1.17 are
otherwise unchanged.

The release workflow must pass the repository source gates, build the exact
committed revision, start an isolated server with fresh data volumes, verify
HTTP 200 / `pong`, restart it once and verify `pong` again, reject Critical or
High image vulnerabilities and embedded secrets, publish a CycloneDX SBOM,
and attest both provenance and SBOM before creating the GitHub Release.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
