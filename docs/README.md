# PastureStack Server documentation

This documentation covers the community-maintained Server and versioned releases.
Release notes record checksums, SBOM/security evidence and publication status;
operator deployment and business-workflow acceptance are recorded separately.

## Release notes

- [Current Server v1.6.583](releases/server-1.6.583.md) — Engine385 / Web225 /
  optional Bridge0.2.27; immutable publication and full normal readback completed.
  Isolated deployment/restart/smoke passed; affected business/native/weak-model
  acceptance and whole-frontend coverage remain pending or incomplete.
- [Release archive](releases/) — historical published and candidate notes retain
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
