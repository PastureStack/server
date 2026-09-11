# PastureStack Server documentation

This documentation covers the community-maintained Server source and validated
versioned releases. Public images and Release assets exist only for tags whose
published checksums, SBOM, licenses, anonymous-download checks, and isolated
runtime gates have passed.

## Current release

- [Server v1.6.428](releases/server-1.6.428.md)
- [Performance settings](performance/README.md)
- [Build and source POC](build-and-source-poc.md)

Older immutable release records remain under [`releases/`](releases/) for
audit and rollback context; they are not the current installation guide.

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
