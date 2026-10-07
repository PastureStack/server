# PastureStack Server documentation

This documentation covers the community-maintained Server source and validated
versioned releases. Public images and Release assets exist only for tags whose
published checksums, SBOM, licenses, anonymous-download checks, and isolated
runtime gates have passed.

## Release notes

- [Server v1.6.518](releases/server-1.6.518.md) — source candidate pinning published Catalog v0.3.13 / Network Plugin Manager v0.8.22 for Metadata-driven CNI configuration migration, plus published Web Console 1.6.180 / audit broker full-retained-time query and export; Server publication and real-host acceptance pending.

- [Server v1.6.517](releases/server-1.6.517.md) — officially published with Web Console 1.6.179; isolated start/restart, browser login and focused API acceptance passed. Known limits remain in the versioned release note.

- [Server v1.6.516](releases/server-1.6.516.md) — candidate packaging published
  Web Console 1.6.178 (848/848 CI tests, reproducible archive, 13 localized inactive
  environment hints) and normally merged Catalog IPsec Overlay 12 / v0.14.38;
  inactive global view/edit/member/delete capabilities preserved without forbidden
  scoped reads; Server publication, isolated deployment and native acceptance pending;
  explicit catalog overrides and historical HOLD preserved; full matrix INCOMPLETE
- [Server v1.6.515](releases/server-1.6.515.md) — published Web Console 1.6.177
  ended-workspace lifecycle repair; Web CI passed 841 tests, lightweight numeric tag
  bound to signed source, identical archives and anonymous bytes verified; Server
  publisher 37256753740 and independent artifact/runtime/security readback passed;
  isolated QA 515 / Web 177 deployment/readback passed, reaching HTTP 200/pong after
  10 initial-start and 11 restart polling attempts; runtime/environment, three named
  volumes, five core-table counts and 514 rollback preserved; no Docker Healthcheck
  or healthy claim; native acceptance pending, latest Project v2 run HOLD after
  deactivate response/UI timeout with native removal and database cleanup incomplete;
  Quick Start pins 515; Engine 333 / Catalog 0.20.12 / plugins unchanged;
  full matrix INCOMPLETE,
  historical HOLD unchanged
- [Server v1.6.514](releases/server-1.6.514.md) — published Catalog Service0.20.12/Web Console1.6.176; Catalog CI39 twice/Web CI824/824 and immutable component bytes verified; official publisher37179046649 and independent readback verified; Quick Start pins514; QA125/8080 upgrade/readback passed with first-start11/restart9 HTTP200/pong, unchanged runtime/volumes/five core-table counts and512 rollback retained; two real eight-table catalog migration captures agreed, removing12 blank Git stubs and2 README-only items while preserving valid semantics; native acceptance remains in progress; full matrix INCOMPLETE and historical HOLD unchanged
- [Server v1.6.513](releases/server-1.6.513.md) — published Web Console 1.6.175 image-validation aggregate repair; Web CI821/821, signed numeric tag, identical archives and anonymous bytes verified; immutable Server image, publisher37164995463, 23 assets/22 checksums, SBOM/security and public readback verified; isolated start13/restart7, 34 MFA/API and TLS gates passed; actual scan raw52/VEX51/vendor8 Medium package findings/4 CVEs, review2026-10-20 and no zero-CVE claim; Engine333/base460/four stages/single runtime layer unchanged; Quick Start pins513, QA remains512/513 not deployed; full matrix INCOMPLETE, historical HOLD unchanged
- [Server v1.6.512](releases/server-1.6.512.md) — published Web Console 1.6.174 VM boot-image form safeguards and localized required-image errors; Web CI817/817, signed numeric tag and anonymous archive bytes verified; immutable Server image, isolated start12/restart8, 34 MFA/API checks, SBOM/security and public artifact readback verified; Quick Start pins512, Engine333/base460/runtime contract unchanged; full functional matrix incomplete, historical scoped/HOLD evidence unchanged
- [Server v1.6.511](releases/server-1.6.511.md) — published Web Console 1.6.173 native Project Template card-name repair; official Web CI812/812, identical builds, signed numeric tag and anonymous archive readback verified; Server immutable image, isolated start/restart, SBOM/security and public artifact readback verified; QA125/8080 upgrade and independent read-only checks passed with first-start11/restart10, unchanged runtime/DB counts; no Docker healthy claim; existing Template117 native read-only proof passed with 3 Full17/14 guards, 0 resource writes and source-bound same-ID empty stacks/services, not a native-create finalizer; Process native list/link/detail and same-ID direct GET passed for one current ID, 12/12 six-role/two-root cells and 0 resource writes, not all-ID/write acceptance; fresh key1c6998 independently derived scoped verified (4 native writes, 13 guards, 6 cookie-free issued Basic GETs before deactivate/delete, 4 barriers, 18 first-delivery checks), original parent identity-schema HOLD retained without rewriting or write replay; Project/Host native acceptance pending, full matrix INCOMPLETE; historical HOLD unchanged
- [Server v1.6.510](releases/server-1.6.510.md) — published Web Console 1.6.172 request-local create-only first delivery; exact official image, build/start/restart, SBOM/security and anonymous component/artifact readback verified; QA deployment and fresh native key/Host lifecycle pending, full matrix incomplete; 509 scoped evidence and key6982 HOLD unchanged
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
