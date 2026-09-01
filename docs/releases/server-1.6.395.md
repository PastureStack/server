# PastureStack Server v1.6.395

Server v1.6.395 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.97`. It closes the remaining native click-bubbling race in shared
resource action menus while retaining the route-independent container charts
introduced in v1.6.394.

## Operator-visible result

- A Container or Service three-dot menu remains bound to the trigger that was
  clicked, including rapid switching between header and row menus.
- The opening or switching click is ignored while it bubbles through the
  document. Only a real click outside the current trigger, toggle, and menu
  closes it.
- Scroll and resize still close the menu, preventing it from drifting away
  from its trigger.
- CPU, memory, network, and storage charts keep their shared stream and visible
  history while the lower container detail tabs change.

## Verification

- Web Console validation run `33462271536` passed `398/398` browser tests, all
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
- Web Console release: `1.6.97`
- Web Console source: `07ca6f3a32276f66abd1e5bfe8f74600bffc2b9c`
- Web Console archive SHA-256:
  `d033bfb0a5f361b2ed97774c460aba29b9e91ce7a81a8062fbe686249f39e0b8`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support,
the refreshed 2026-09-01 Ubuntu security snapshot, the current OpenVEX
closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

An unmatched vulnerability at any severity remains a release blocker.
