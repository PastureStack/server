# PastureStack Server documentation

This documentation covers the community-maintained Server and versioned releases.
Release notes record checksums, SBOM/security evidence and publication status;
operator deployment and business-workflow acceptance are recorded separately.

## Release notes

- [Current Server v1.6.586](releases/server-1.6.586.md) — Engine `0.183.388` /
  Web Console `1.6.228` / optional Bridge `0.2.30`. Immutable publication and
  original workflow checks are complete; deployment-specific acceptance is
  recorded separately.
- [Server v1.6.587 source candidate](releases/server-1.6.587.md) — Engine
  `0.183.389`, Web Console `1.6.230` / optional Bridge `0.2.32` and Compose
  `0.14.44`. Matching component publication is verified; Server build,
  publication and runtime acceptance remain pending.
- [Release archive](RELEASE-ARCHIVE.md) — historical published and candidate notes retain
  their original evidence, acceptance limits and rollback context; these are not
  the current installation guide.
- [Current installation](../README.md#current-release)
- [Performance settings](performance/README.md)
- [Build and source POC](build-and-source-poc.md)

## Operations

- [Upgrade and persisted-coordinate migration](upgrades/README.md)
- [Host compatibility](hosts/README.md)
- [Service compatibility](services/README.md)
- [TLS termination](tls/README.md)
- [High availability](high-availability/README.md)
- [Network ports](network-ports/README.md)
- [Troubleshooting](faqs/README.md)
- [Telemetry](telemetry/README.md)

Read [`../ORIGIN.md`](../ORIGIN.md), [`../COMPATIBILITY.md`](../COMPATIBILITY.md),
and [`../SECURITY.md`](../SECURITY.md) before operating the Server.
