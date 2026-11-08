# PastureStack Server documentation

This documentation covers the community-maintained Server and versioned releases.
Release notes record checksums, SBOM/security evidence and publication status;
operator deployment and business-workflow acceptance are recorded separately.

## Release notes

- [Current Server v1.6.585](releases/server-1.6.585.md) — Engine `0.183.387` /
  Web Console `1.6.227` / optional Bridge `0.2.29`. Immutable publication is complete;
  deployment and affected business acceptance remain separate.
- [Server v1.6.586 source candidate](releases/server-1.6.586.md) — Engine `0.183.388` /
  Web Console `1.6.228` / optional Bridge `0.2.30`. Matching components are published;
  Server build, publication, deployment and affected acceptance remain pending.

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
and [`../SECURITY.md`](../SECURITY.md) before operating a candidate build.
