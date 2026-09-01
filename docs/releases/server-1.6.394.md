# PastureStack Server v1.6.394

Server v1.6.394 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.96`. It closes two remaining client-side race and presentation defects
without changing the established Server v1.6.358 authenticated layout, the
container detail data, or the content of its child tabs.

## Operator-visible result

- Opening or switching a Container or Service three-dot menu can no longer be
  consumed by the same bubbling click. The menu stays bound to the newest
  model and trigger instead of intermittently showing no available actions.
- Scrolling, resizing, and route changes still close an open action menu, so it
  cannot drift away from its trigger.
- CPU, memory, network, and storage charts use route-independent SVG gradient
  references. Their existing data paths, shared statistics stream, colours,
  and visible history remain intact while switching Ports, Commands, Volumes,
  Networking, Security, Healthcheck, Labels, and Scheduling tabs.

## Verification

- Web Console validation run `33458220244` passed `397/397` browser tests, all
  source gates, and two byte-identical production builds on Node.js `24.20.0`.
- The Web Console release is immutable and its artifact digest is bound below.
- The Server publish workflow performs source gates, isolated start/restart
  smoke, merged-rootfs Trivy scanning, SBOM generation, image publication,
  provenance and SBOM attestations, and immutable release creation.
- The runtime is rebuilt from the `20260901T000000Z` Ubuntu snapshot and
  rejects GNU coreutils older than `9.7-3ubuntu2.1` or util-linux-family
  packages older than `2.41.3-3ubuntu2.2` before publication.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.96`
- Web Console source: `b6129724e622fb81142efcb5dce205a094314a2a`
- Web Console archive SHA-256:
  `65d12b28e8431977a741091fcb36ca7d4846443117b4d74a1b2d431e0a2859c0`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support,
the current OpenVEX closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

An unmatched vulnerability at any severity remains a release blocker.
