# Server v1.6.552

Published image: `ghcr.io/pasturestack/server:v1.6.552@sha256:f19a0fdd7340fde910c8eb66311bbe11d682301f5fe2df7768638b866e5ef1f4`.

Source commit: `6be16e0c62473e65e4222e144fba513d61717f34`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

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

## Scoped QA acceptance

The QA Server was updated by exact digest, then restarted once.
The existing environment overrides, three named data volumes, Docker socket
bind, AppArmor and restart policy were preserved. The prior v1.6.551 container
and image remain available for rollback with the consistent database backup.
PCRE2 integrity, runtime library versions, MariaDB regular-expression controls,
/ping and all three active Host/Agent states passed. This is scoped acceptance;
unrelated UI, role and language tests were not rerun. No production site,
HAProxy or firewall was changed.
