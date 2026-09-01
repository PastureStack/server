# PastureStack Server v1.6.396

Server v1.6.396 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.98`. It makes shared resource action menus reliably switchable while
retaining the route-independent container charts introduced in v1.6.394.

## Operator-visible result

- An open action menu moves beside any other visible three-dot triggers that
  it would otherwise cover. Clicking another row therefore reaches that row's
  trigger instead of executing an action painted over it.
- Header and row action menus can be switched repeatedly without falling back
  to an empty “no actions available” state.
- Window scrolling and scrolling inside any nested page region close the menu
  before it can detach from its trigger or drift down the page.
- CPU, memory, network, and storage charts keep their shared stream and visible
  history while the lower container detail tabs change.

## Verification

- Web Console validation run `33465105252` passed `400/400` browser tests, all
  source gates, and two byte-identical production builds on Node.js `24.20.0`.
- The Web Console release is immutable and its artifact digest is bound below.
- The Server publish workflow performs source gates, isolated start/restart
  smoke, merged-rootfs Trivy scanning, SBOM generation, image publication,
  provenance and SBOM attestations, and immutable release creation.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.98`
- Web Console source: `ee871276309fbc95af85f369eaf2c22174490fbc`
- Web Console archive SHA-256:
  `2e7a34ca1c39cc0f0425bf8a0165496510149e4ef6f9e7938d8871edb96edbff`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support,
the refreshed 2026-09-01 Ubuntu security snapshot, the current OpenVEX
closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

An unmatched vulnerability at any severity remains a release blocker.
