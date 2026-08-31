# PastureStack Server v1.6.388

Server v1.6.388 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.91` so container restarts are visible both in the administrator audit log
and in the owning Service's log.

## Operator-visible result

- A Service-owned container restart writes an explicit
  `service.instance.restart` record with the readable container name.
- The Service log page can filter by time range, severity, named container,
  parent/detail scope, event type, and description.
- Investigation shortcuts cover recent events, restarts in the last 24 hours,
  and errors in the last 24 hours.
- Clearing or reapplying an unchanged query completes reliably; the existing
  Service log table, columns, and row actions remain unchanged.
- The complete filter interface is translated in all 13 production locales.

## Verification

- Orchestration Engine affected Maven reactor: `48` modules passed; the
  service-discovery server suite passed `59/59` tests.
- Orchestration Engine security release gate `33368261212` passed build, test,
  source/product/Dapper scans, and zero applicable Critical/High enforcement.
- Web Console validation run `33369447419` passed `386/386` browser tests,
  all source gates, and two byte-identical production builds on Node.js
  `24.20.0`.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.91`
- Web Console source: `a01255d184c24f5e10aba64cfbab3f36222e7714`
- Web Console archive SHA-256:
  `e93e3c1791286823a5dd841e4af166704f01c42f5eece39a5383b1b10f83040a`

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
