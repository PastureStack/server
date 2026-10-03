# Server v1.6.511

Candidate packaging contract only. No Server511 image, publication, runtime
or native browser acceptance is claimed by source alignment or offline tests.

## Scope

This candidate packages Web Console `1.6.173` for native Project Template
card names. Template choices read the existing model `name`; the previous
`localizedName` property is not implemented on ProjectTemplate. This changes
the native display source, not template payloads, role authorization or schema.

Orchestration Engine stays official `v0.183.333`, source
`0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
`8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
Reuse the digest-pinned Server460 base and existing single-runtime-layer
flattening/config comparison gates. Other component/package pins, security
policy, OIDC/MFA, production environment and persistent volumes are unchanged.
No migration or runtime patch is required.

## Pending exact release coordinates

- Web173 published source: `c8b8bb2659fdad3539cf6a72866c94a77ec516b6`.
- Web173 published tree: `f590310e157edea79de81fcf333e8b39dbc5677e`.
- [Official Web CI37115288389](https://github.com/PastureStack/web-console/actions/runs/37115288389):
  812/812 tests passed; failures, skips and todo are zero. Two production
  archive builds are byte-identical.
- [Published Web Console](https://github.com/PastureStack/web-console/releases/tag/1.6.173):
  `web-console-1.6.173.tar.gz` under signed numeric tag `1.6.173`.
  CI archive SHA256: `a566684e6e0831630a15cb7212989c0e9fe707ed07965156c2b664b9cdb5ba27`.
  Immutable publication, SSH tag signature and anonymous public byte readback
  were verified; public archive bytes match this CI SHA256.
- Archive SHA256 and source guards remain fail-closed. Source-contract tests
  are not Server build PASS and do not replace formal public artifact readback.
- Server511 final source/tree, official publisher run, immutable image/config/
  layer digests, asset checksums, attestations, SBOM and merged-rootfs scan
  remain pending. Start/restart and TLS/private-cache gates need this version's
  actual evidence, not copied Server510 numbers.

The existing security exact-set is retained without widened severity, available-
fix or untracked-finding exceptions. A new final merged-rootfs scan must agree
with those gates. No Server511 scan count or zero-CVE assertion is claimed.

## Remaining native acceptance and historical evidence

QA deployment and exact native Project, Host and fresh API Key lifecycle
outcomes remain independently pending; a template or fixture is not Host PASS.
The full permission/resource/locale/layout matrix remains INCOMPLETE.
Historical scoped results and HOLD receipts remain version-bound and immutable;
a later component fix does not promote or replay them.

The verified public Server510 image remains the installation guide and nearest
release rollback reference until Server511's own immutable publication is read
back. Preserve the same Compose environment, volumes and runtime policy.
Publication does not deploy or modify the company site or existing environments.
