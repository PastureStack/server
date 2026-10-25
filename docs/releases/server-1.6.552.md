# Server v1.6.552

This release consumes the qualified Ubuntu security backports in Server and its
component images. It updates only already-installed packages, preserves the
coreutils provider and configuration, and keeps compilers outside the final
runtime. The root Server image does not add jq, Rust coreutils or development
packages to obtain a clean scan.

The bundle binds the original upstream fixes, native package tests, actual GNU
and uutils installation fixtures, package archives and exact-package OpenVEX.
The published image has its own SBOM and installation verification. These are
separate from the bundle's data SBOM. Raw findings remain available alongside
the interpreted report. Unfixed findings and code-absence determinations are
reported separately from fixed vulnerabilities.

Web Console `1.6.195`, Engine `v0.183.354`, Host API `0.38.8` and Temurin
`25.0.5+8` retain their component inputs. Node Agent `v1.2.33` uses base
`v0.3.7`; Catalog `v0.3.17` records the corresponding component releases.

## Upgrade and rollback

Back up the database and all three named volumes before upgrading. Keep the
existing Compose environment variables, ports, restart policy, AppArmor,
public HTTPS origin and mounts. Use `ghcr.io/pasturestack/server:v1.6.552`;
do not keep old runtime bundle overrides mounted into the new image.

Upgrade existing infrastructure stacks through the normal Catalog workflow and
complete their upgrades after checking health. Preserve the previous image and
matching data backup for rollback. Do not run `docker compose down -v`.

The official release includes the producer commit, immutable image digest,
checksums, SBOMs, vulnerability reports and qualification receipts. Consult
[the compatibility contract](../../COMPATIBILITY.md#server-v16552-runtime-backports)
for the retained runtime boundaries.
