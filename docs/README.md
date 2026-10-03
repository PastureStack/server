# PastureStack Server documentation

This documentation covers the community-maintained Server source and validated
versioned releases. Public images and Release assets exist only for tags whose
published checksums, SBOM, licenses, anonymous-download checks, and isolated
runtime gates have passed.

## Release notes

- [Server v1.6.510](releases/server-1.6.510.md) — unpublished source candidate for Web Console 1.6.172 request-local create-only first delivery; official component pins, build/publication/SBOM/readback/deployment and fresh native key lifecycle pending; 509 scoped evidence and key6982 HOLD unchanged
- [Server v1.6.509](releases/server-1.6.509.md) — published Engine 0.183.333 canonical create-only redaction with Web Console 1.6.171; immutable artifact readback, QA start/restart and existing Account6974/Project6977 scoped closures verified; fresh key6982 first-delivery HOLD, fresh Host pending; full matrix incomplete
- [Server v1.6.508](releases/server-1.6.508.md) — published Web Console 1.6.171 canonical create-response fix; immutable artifact, QA start/restart, scoped Volume and Registry lifecycle verified; full matrix incomplete
- [Server v1.6.507](releases/server-1.6.507.md) — published Web Console 1.6.170 nullable Volume relation fix; immutable artifact and QA start/restart verified
- [Server v1.6.506](releases/server-1.6.506.md) — source candidate for the Web Console 1.6.169 generated Volume identifier classifier fix; immutable publication and packaged native lifecycle acceptance pending
- [Server v1.6.505](releases/server-1.6.505.md) — published Engine 0.183.332 with Web Console 1.6.168; immutable artifact and QA start/restart verified, broader permission matrix incomplete
- [Server v1.6.504](releases/server-1.6.504.md) — published Web Console 1.6.168 Volume entry and permission repair; immutable artifact and QA start/restart verified
- [Server v1.6.498](releases/server-1.6.498.md) — unpublished source candidate for Engine 0.183.329 low-role GenericObject capability protection; immutable artifact/deployment/browser gates pending
- [Server v1.6.497](releases/server-1.6.497.md) — published Web Console 1.6.164 / Engine 0.183.328 / Cache 5.7.5; official source/build/start-restart/security/public artifact readback verified, QA8080 now497/Web164 first start/restart passed; packaged native Receiver browser acceptance pending, broader matrix INCOMPLETE
- [Server v1.6.496](releases/server-1.6.496.md) — published Web Console 1.6.162 / Engine 0.183.328 / Cache 5.7.5; official artifact readback, isolated QA first start/restart and two scoped zero-write desktop cases passed; mobile/all-language/full-layout pending, broader matrix INCOMPLETE
- [Server v1.6.495](releases/server-1.6.495.md) — published Certificate editor fix and official DBI security update; isolated start/restart and scoped owner/member Certificate browser checks verified, broader matrix INCOMPLETE
- [Server v1.6.494](releases/server-1.6.494.md) — published artifact and isolated start/restart verified; Certificate QA pending
- [Server v1.6.493](releases/server-1.6.493.md)
- [Server v1.6.492](releases/server-1.6.492.md)
- [Server v1.6.491](releases/server-1.6.491.md)
- [Server v1.6.490](releases/server-1.6.490.md)
- [Server v1.6.489](releases/server-1.6.489.md)
- [Server v1.6.488](releases/server-1.6.488.md)
- [Server v1.6.487](releases/server-1.6.487.md)
- [Server v1.6.486](releases/server-1.6.486.md)
- [Server v1.6.485](releases/server-1.6.485.md)
- [Server v1.6.484](releases/server-1.6.484.md)
- [Server v1.6.483](releases/server-1.6.483.md)
- [Server v1.6.482](releases/server-1.6.482.md)
- [Server v1.6.481](releases/server-1.6.481.md)
- [Server v1.6.480](releases/server-1.6.480.md)
- [Server v1.6.479](releases/server-1.6.479.md)
- [Server v1.6.478](releases/server-1.6.478.md)
- [Server v1.6.477](releases/server-1.6.477.md)
- [Server v1.6.476](releases/server-1.6.476.md)
- [Server v1.6.475](releases/server-1.6.475.md)
- [Server v1.6.474](releases/server-1.6.474.md)
- [Server v1.6.473](releases/server-1.6.473.md)
- [Server v1.6.472](releases/server-1.6.472.md)
- [Server v1.6.471](releases/server-1.6.471.md)
- [Server v1.6.470](releases/server-1.6.470.md)
- [Server v1.6.469](releases/server-1.6.469.md)
- [Server v1.6.468](releases/server-1.6.468.md)
- [Server v1.6.467](releases/server-1.6.467.md)
- [Server v1.6.466](releases/server-1.6.466.md)
- [Server v1.6.465](releases/server-1.6.465.md)
- [Server v1.6.464](releases/server-1.6.464.md)
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
