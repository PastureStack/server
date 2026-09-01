# PastureStack Server v1.6.393

Server v1.6.393 embeds Orchestration Engine `0.183.288` and Web Console
`1.6.95`. It fixes two UI lifecycle defects without changing the established
Server v1.6.358 authenticated layout or the content of container detail tabs.

## Operator-visible result

- Container and Service three-dot menus are bound to the newest click only.
  Delayed callbacks from an older click cannot reopen an empty menu or position
  it against a stale row.
- An open action menu closes on route changes, scrolling, or viewport resizing
  instead of drifting away from its trigger.
- CPU, memory, network, and storage charts keep the same statistics stream and
  visible history while switching Ports, Commands, Volumes, Networking,
  Security, Healthcheck, Labels, and Scheduling tabs for the same container.
- The charts reconnect only when the container or statistics endpoint actually
  changes.

## Verification

- Web Console validation run `33455312520` passed `395/395` browser tests, all
  source gates, and two byte-identical production builds on Node.js `24.20.0`.
- The Web Console release is immutable and its artifact digest is bound below.
- The Server publish workflow performs source gates, an isolated start/restart
  smoke, merged-rootfs Trivy scanning, SBOM generation, image publication,
  provenance and SBOM attestations, and immutable release creation.

## Bound release inputs

- Orchestration Engine release: `v0.183.288`
- Orchestration Engine source: `a9e5d71cb5c11360018488a391c25db3f245555d`
- Orchestration Engine JAR SHA-256:
  `a68f1fea103ececd288db708f129e8cb8f47ad3b78b73102d2190d680e357247`
- Web Console release: `1.6.95`
- Web Console source: `de0b9fd4664bdce3f4a487f73f8ec51c59b10c3c`
- Web Console archive SHA-256:
  `49d04ab9ee5678a206e7f52057b22d3006bd0a0bddfc938a1a18900845c60bf8`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, Docker Engine `29.4.1` through `29.7.2` support,
the current OpenVEX closure, and the existing runtime hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

An unmatched vulnerability at any severity remains a release blocker.
