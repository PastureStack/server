# Server v1.6.546 candidate

Security-refresh source candidate. The Server image has not yet been published
or accepted on the 8080 test installation. This document must not be used as
runtime acceptance evidence until those results are added.
Prepared source only; no Server image or release has been published.

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
- Node Agent 0.13.32 includes the matching Host API 0.38.8 supervisor
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
  and installed-package set. APT security refresh uses private index/cache
  directories so it does not remove source indexes needed by other builds.

## Compatibility and evidence

Existing OIDC, MFA, API Key, service-upgrade and permission contracts are not
changed. The publisher must pass the normal source, CodeQL, artifact,
security, startup and restart checks before publication. QA then verifies the
exact image on the isolated QA deployment, including login, authenticated APIs, WebSocket,
host/agent connectivity and retained workload data. Unrelated previously
accepted features are not represented as newly retested.

Raw scans and SBOMs remain separate from vulnerability dispositions. An
officially unfixed LOW/MEDIUM finding is tracked against its exact artifact,
package and version; that is not remediation. Available fixes, unregistered
findings, HIGH/CRITICAL issues and secrets still block publication.

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
