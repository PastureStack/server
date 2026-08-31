# PastureStack Server v1.6.389

Server v1.6.389 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.92`. It retains the Service restart event and advanced log filters from
v1.6.388 while fixing the shared time wheel so a device-pixel remainder cannot
leave the animation running without committing the selected time.

## Operator-visible result

- A Service-owned container restart writes an explicit
  `service.instance.restart` record with the readable container name.
- The Service log page filters by time range, severity, named container,
  parent/detail scope, event type, and description.
- Time columns keep their smooth infinite-wheel animation and now commit once
  they are within one visually indistinguishable pixel of the target.
- Clearing or reapplying a query completes reliably; the existing Service log
  table, columns, and row actions remain unchanged.
- The complete filter interface remains translated in all 13 production
  locales.

## Verification

- Orchestration Engine affected Maven reactor: `48` modules passed; the
  service-discovery server suite passed `59/59` tests.
- Orchestration Engine security release gate `33368261212` passed build, test,
  source/product/Dapper scans, and zero applicable Critical/High enforcement.
- Web Console validation run `33374644099` passed `387/387` browser tests,
  all source gates, and two byte-identical production builds on Node.js
  `24.20.0`.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.92`
- Web Console source: `900e68c66644a28a3084463c97ca56a4b547c32c`
- Web Console archive SHA-256:
  `70833ef6115fe8b0413f25ee43feab855c2edaeed30679e1f16f73d5bf12c472`

This release retains the Server `v1.6.358` authenticated presentation, Host
chart fixes, Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL `3.5.8`,
zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support, the current
OpenVEX closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow performs the merged-rootfs vulnerability scan,
SBOM, start/restart smoke, provenance, SBOM attestation, image publication, and
immutable release; unmatched vulnerability at any severity remains a release blocker.
