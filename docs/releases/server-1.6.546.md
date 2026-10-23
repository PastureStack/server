# Server v1.6.546

Published security refresh from producer
`c1b4b335f77f8faaae8239af9e8d5a8189ce07b8` via
[publisher 40000369416](https://github.com/PastureStack/server/actions/runs/40000369416).
The immutable release contains 26 assets with verified SHA-256 checksums;
anonymous registry and asset readback, provenance and SBOM attestations passed.

- Manifest: `sha256:7b29b87ab40f427c2a6a5909330dd859745e9f0780166658ffd0556b6f0873d2`.
- OCI config: `sha256:22fbb5fe50be0317a25571b8d0ac4d1782a0bfae9959d0b72666ed8ca897f2ca`.
- Platform: linux/amd64; one runtime layer. The maintained multi-stage build
  and component verification are retained.

Install with `ghcr.io/pasturestack/server:v1.6.546`; the digests above identify
the artifact, not a replacement for the numeric-tag installation examples.

## Verified component inputs

- Engine v0.183.354: original JAR from producer
  `dc5a8d7bc44131f609f72a6504483b692d47ce16`, SHA256
  `f4889bfb8759a7664f07524bb129d0cda19f35604a06c877b6ca7033246df6fa`.
  JDK 25 tests: 3,372 cases, no failures or errors, one platform-specific skip.
- Web Console 1.6.194 and API Explorer v1.1.20 retain their UI/API behavior
  while refreshing fixed tooling and dependencies. Original published bytes
  are used, not locally rebuilt substitutes.
- Host API 0.38.8, WebSocket Proxy 0.23.18, authentication service 0.4.46,
  host provisioner 0.39.10, telemetry 0.4.4, catalog service 0.20.15 and
  compose executor 0.14.39 use exact published archives and binary checksums.
- Node Agent 0.13.33 includes the matching Host API 0.38.8 supervisor
  contract. Linux and Windows packages retain their independently verified
  checksums; cross-compiling the Windows package is not Windows-host QA.
- CLI 0.6.20 preserves its existing command and authorization behavior and
  provides the original CI-tested platform archives through numeric URLs.
- Machine-driver bundle 0.16.5 replaces the inherited 0.14.0 runtime binary.
  The original archive, both Go executables and legal metadata are verified;
  Packet stays retired for new hosts and explicit operator URLs are retained.
- Catalog v0.3.14 source `28756cdf13f50380e907d37da501e33383a7c217`
  selects the independently verified plugin releases; operator catalog overrides
  are not replaced. Catalog publication and Server runtime verification remain
  separate checks.
- Temurin 25.0.5+8 and fixed Ubuntu 26.04 packages retain the existing ABI
  and installed-package set. The build stage verifies the signed Ubuntu
  snapshot and each package's SHA256. The minimal runtime installs only
  already-present, older packages from that verified offline bundle; it does
  not need network access or an APT signature executable. The package manifest
  is retained under `/usr/share/pasturestack/security/` for inspection.
- Ubuntu's zlib security backport `1:1.3.dfsg+really1.3.1-1ubuntu3.2`
  replaces the formerly preferred upstream 1.3.2 library. This fixes
  [CVE-2026-85091](https://ubuntu.com/security/notices/USN-8954-1) while retaining
  the earlier CVE-2026-27171 fix. Assembly removes the superseded library;
  post-build checks verify the active linker target and package-owned bytes,
  not just the version recorded in the package database.

## Compatibility and evidence

Existing OIDC, MFA, API Key, service-upgrade and permission contracts are not
changed. The publisher passed normal source, CodeQL, artifact,
security, startup and restart checks. Deployment to the isolated QA installation
preserved the existing environment overrides, HostConfig, persistent mounts,
AppArmor and previous rollback container. The running zlib backport's bytes,
MariaDB linkage and a read-only compression roundtrip were verified. Existing
primary/sidekick identities and volume content remained intact.
Unrelated previously accepted features are not represented as newly retested.

Raw scans and SBOMs remain separate from vulnerability dispositions. An
officially unfixed LOW/MEDIUM finding is tracked against its exact artifact,
package and version; that is not remediation. Available fixes, unregistered
findings, HIGH/CRITICAL issues and secrets still block publication.
The OpenPGP module advisory retains the independently reviewed component
dispositions. Before applying them, the publisher verifies each affected
executable path, module version and exact binary SHA256; a new or changed
consumer cannot inherit the exception just by using the same module version.

The complete artifact gate retained 51 raw occurrences. After exact existing
VEX dispositions, 29 officially unfixed LOW/MEDIUM occurrences across 18 CVEs
remain tracked for review by 2026-10-27. There are no HIGH/CRITICAL,
fixed-available or unregistered findings, or detected secrets. No severity or
release check was bypassed; seven rejected publisher attempts produced no
release and remain historical evidence.

## Upgrade and rollback

Preserve the three existing named volumes, all operator environment
variables, restart policy, AppArmor profile, HTTPS origin, OIDC settings and
the host's selected firewall backend. Back up the database before cutover and
keep the previously accepted v1.6.545 image/container. Do not run
`docker compose down -v`. Restore matching data if a rollback requires it.
No production configuration or data is changed by this QA.

An explicitly stored `agent.image` or `bootstrap.required.image` value takes
precedence over the new image defaults. Review those settings when upgrading
an existing installation; selecting the maintained Agent version is separate
from changing the Server image. Custom image choices must not be silently
overwritten. The embedded Host API and Go Agent package URLs are verified
independently through their effective values.
