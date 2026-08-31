# PastureStack Server v1.6.392

Server v1.6.392 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.94`. It preserves the compact resource menus, first-sample chart
rendering, calendar-month and all-time quick ranges, localized Labels tab,
and explicit all-time audit-log routing delivered by v1.6.391.

## Operator-visible result

- Container and Service three-dot menus remain compact and aligned to the
  selected row instead of expanding across the page.
- Container CPU, memory, network, and storage panels remain in their loading
  state until the first live statistics sample arrives.
- Service and audit log time dialogs include `最近 1 個月` and `所有時間`.
- An explicit audit-log all-time selection remains unbounded after route
  setup instead of being mistaken for the initial 24-hour default.
- The container Labels tab displays `標籤` without a trailing colon.
- The established Server v1.6.358 authenticated page layout is unchanged.

## Provenance correction

This release corrects the image's `PASTURESTACK_WEB_CONSOLE_COMMIT` metadata
to the exact source commit that produced Web Console `1.6.94`. The reviewed
Web Console archive, its SHA-256, and all UI behavior are unchanged from
v1.6.391; only the stale source-coordinate default is corrected.

## Verification

- Web Console validation run `33412165316` passed `391/391` browser tests,
  all source gates, and two byte-identical production builds on Node.js
  `24.20.0`; the PR CodeQL checks also passed.
- The Web Console release is immutable and its artifact digest is bound below.
- The Server publish workflow performs source gates, an isolated start/restart
  smoke, merged-rootfs Trivy scanning, SBOM generation, image publication,
  provenance and SBOM attestations, and immutable release creation.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.94`
- Web Console source: `eb025ef2d5b795de4d9f8da61d344298358c86ff`
- Web Console archive SHA-256:
  `aa93bbdb12ac35048da23bc6244b8b232fc5ff269d268d37a0f709725468bb37`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support,
the current OpenVEX closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

unmatched vulnerability at any severity remains a release blocker.
