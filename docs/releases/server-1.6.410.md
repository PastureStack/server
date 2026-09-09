# PastureStack Server v1.6.410

This release removes branded version qualifiers from the active Server
dependency chain while preserving the reviewed v1.6.409 application and Web
Console behavior.

## Operator-visible result

- The documented and published Server coordinate is the pure numeric semantic
  version `ghcr.io/pasturestack/server:v1.6.410`.
- Existing Web Console `1.6.102` HTML, CSS, layout, translations, action menus,
  charts, audit filters, log and shell sessions, ports, volumes, and container
  runtime settings are unchanged.
- Catalog Templates advance to the validated pure numeric `v0.3.1` source at
  commit `02df5f7df9eebe640590d93b1506543d2367e355`.

## Reviewed runtime replacements

- Orchestration Engine `v0.183.294` from source commit
  `b59ddee9d79dcffa8b95a00dd9182fe5304b619b`; release JAR SHA-256
  `1e49dac19043cb1579a0449f0d8874ebe5d1777c1231bff61dca793f58fe0b73`.
- Distributed cache runtime `5.7.4`; embedded JAR SHA-256
  `6b768e6cff9e5281e77ad14e609b69bac6856ecd4469af827f566be95553644c`.
- vSphere CLI Bundle `v0.55.2` from source commit
  `c4b27e87aa0dacce432a2c6108ee0752319e6d5b`; archive SHA-256
  `bebcc1c0275072ac40b5bc9b80f914c40a7f0431fffebc2c06fe34a34c33a57c`
  and installed `govc` SHA-256
  `f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31`.

The build rejects non-numeric Orchestration Engine, API Explorer, and vSphere
CLI release versions. It verifies archive paths, duplicate members, links,
artifact hashes, exact executable version output, source records, and legal
files before the resulting image can be published.

Publication requires all Server source gates, clean-source image assembly,
initial and restart `pong` checks, Catalog bootstrap, merged-rootfs Trivy
vulnerability and secret scans, CycloneDX SBOM generation, provenance and SBOM
attestations, and a release bound to the exact source commit. Any unmatched vulnerability at any severity remains a release blocker.

The runtime security layer advances to the signed Ubuntu snapshot from
2026-09-09 and installs the official glibc `2.43-2ubuntu2.4` and Perl
`5.40.1-7ubuntu0.2` packages. The build verifies every downloaded package name,
version and architecture and rejects any Server runtime entrypoint that invokes
Perl, references the four reviewed Perl-only vulnerable paths, or contains the
empty `,ccs=` mode required by `CVE-2026-18374`. Ubuntu still marks that glibc
issue as needing evaluation for Resolute; therefore the OpenVEX statement is an
explicit runtime-path determination, not a false claim that package revision
`2.43-2ubuntu2.4` fixes it. Perl remains present for operating-system package and
MariaDB administration compatibility, but is not in the running Server, API,
WebSocket, database or service-launch execution path. GNU coreutils `uniq`
retains fix `d64e35a8a4c0e4608321433e0d84d917e4e36371`; the OpenSSL closure for
`CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910` are unchanged.
