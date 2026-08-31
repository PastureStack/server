# PastureStack Server v1.6.390

Server v1.6.390 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.93`. This release fixes the resource action menu, container statistics
first-sample state, and log time-range presets without changing the established
Server v1.6.358 authenticated page layout.

## Operator-visible result

- Container and Service three-dot menus remain compact and aligned to the
  selected row instead of expanding across the page.
- Container CPU, memory, network, and storage panels retain their loading state
  until the first live statistics sample arrives; empty axes are not presented
  as usable charts.
- Service and audit log time dialogs add calendar-month and all-time presets.
  All-time omits the backend time bounds instead of fabricating a large range.
- The container Labels tab no longer displays a trailing colon.
- New copy is translated in all 13 production locales.

## Verification

- Web Console validation run `33406789997` passed `390/390` browser tests,
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
- Web Console release: `1.6.93`
- Web Console source: `30378c93e1fdb70404a2ad2793212b61c65e74b1`
- Web Console archive SHA-256:
  `46917e763ba560b13fa55f2e9a6c812ec7849d8daccbbd1bb655edbdf14c48ee`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`,
OpenSSL `3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2`
support, the current OpenVEX closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`. The OpenVEX statements remain bound to the published
runtime components; unmatched vulnerability at any severity remains a release blocker.
