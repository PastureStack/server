# Server v1.6.497

Published Server `v1.6.497` is the immutable image
`ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d`,
from source `80d97523052aa86ec761ade8ec487c382a8d5e1d`.
[Official publication run `36836319609`](https://github.com/PastureStack/server/actions/runs/36836319609)
and independent public assets/GHCR readback passed. QA `8080` now runs the
immutable `v1.6.497` / Web Console `1.6.164` deployment; first start/restart passed.
Packaged native Receiver browser acceptance remains pending. Publication does
not promote historical HOLD receipts. Preserve the nearest `v1.6.496` QA rollback
with its original named volumes/settings; the `v1.6.495` image and backups remain
retained.

## Official Web Console input

This release pins the officially published Web Console `1.6.164`:

- Numeric release/tag: `1.6.164`.
- Validated artifact source: `c3c0779d930d4d0367ec0517166ca21f6b3dc6d4`.
- Signed tag object: `eddb24c5561e0ad46519aa3e3e2704e932fc8e72`.
- [Official validation run `36831735186`](https://github.com/PastureStack/web-console/actions/runs/36831735186):
  763 actual case results; this is component validation, not Server QA.
- Archive: `web-console-1.6.164.tar.gz` (2,976,044 bytes).
- Archive SHA-256:
  `734898ac6ed2fe8774e5bb947988da9720a3a65aa0bb7ec09a89420adc0acc20`.
- Portable SHA-256 file SHA-256:
  `4b7c0d38fd529a7dc9ca36457a40b5afe8216ca595393e291a031b44ec73801e`.

The existing archive is consumed by exact hash; the Server build does not rebuild
Web Console. Web Console `1.6.163` fixes are included: relative dates recompute
when the selected locale changes without mutating the global Moment locale,
and seven recognized state display labels use existing translations while
unknown/overridden display labels remain unchanged.

Web Console `1.6.164` reuses the actual visible labels for required/numeric
Receiver driver fields. Receiver Name uses `generic.name`; the scale-service
target uses `newReceiver.service.label`. Service-upgrade size/interval use
`formUpgrade.size` / `formUpgrade.interval`. Model-specific labels retain
precedence, unknown fields retain the fallback, and scale-service/scale-host
retain their existing min/max validation condition with translated feedback.
No translation keys, validation conditions, schema, API authorization, driver
actions, clone behavior or resource-request contracts change.

## Preserved assembly and security boundaries

Orchestration Engine remains `v0.183.328`, source
`ad43f4b6790c359e248710a39bca2f776d70be62`, with WAR SHA-256
`184fb3d4a2b026560e1e60d7b444f693f79bff6c8220cc9354c1284012f6a683`.
The WAR's `WEB-INF/lib/hazelcast-5.7.5.jar` retains SHA-256
`0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715`.
Jackson core/databind metadata remains `2.22.3` / `3.2.3`; numeric Hazelcast
cluster runtime remains `5.7.3`. The runtime base stays
`ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403`.

Other platform pins, runtime packages, Compose, AppArmor, nftables, database,
authentication, OIDC and MFA contracts are unchanged. Only the VEX/tracker
release identity changes to `v1.6.497`; all 51 VEX statements and the exact
vendor-pending set of eight Medium plus six Low package findings are retained,
including their original vendor status and review dates. The actual merged-rootfs
Trivy `0.74.0` scan reports 58 raw findings and 14 exact vendor-pending package
findings after VEX (six unique CVEs), reviewed through `2026-10-08`. Raw and
unresolved JSON/TSV sets, VEX finding/PURL suppression and the tracker exact-set
were independently matched. Critical/High, untracked, fixed-available and secret
findings are zero; this is not a zero-CVE result.

## Official publication evidence and remaining acceptance

- All 56 source/pin gates and the single exact-source image build passed.
- The 26-layer build was flattened to one `linux/amd64` layer with identical
  runtime configuration; public tag/immutable manifest bytes, config hash and
  version/revision/base labels matched.
- Isolated first start and restart returned `HTTP 200` / `pong` (13 and eight
  attempts); all 34 MFA policy/API checks passed on the disposable database.
- TLS 1.2/1.3 returned HTTP 200 and an untrusted certificate was rejected.
  Before/after restart public-origin and private-API `no-store` contracts passed.
- All 22 checksummed assets plus `SHA256SUMS` matched their local SHA-256/size and
  published GitHub asset digests. Manifest SHA-256 is
  `1c0110de4bc4e513a78fb6e825b6d8b4da1e34dd851947bc93079d29fa990793`.
- CycloneDX SBOM container digest, version, source revision and root dependency
  identity matched the published image. Both provenance and SBOM attestation
  workflow steps succeeded. The 14-pending security boundary above is unchanged.
- Existing QA `8080` first start/restart returned `HTTP 200` / `pong` (10 and nine
  attempts), with zero runtime-contract and tracked five-table DB-count
  differences at both checkpoints. The `account`, `credential`, `setting`,
  `project_member` and `host` counts were preserved; this is count preservation,
  not a whole-database row comparison. The three original named data volumes,
  environment overrides, AppArmor and restart policy were preserved. Docker
  health is `null`, and no Docker `healthy` result is claimed. The nearest
  immutable `v1.6.496` rollback is retained. The `v1.6.495` image and backups
  remain retained; its obsolete stopped container was removed without deleting
  data volumes.

The immutable Release assets, including their publication-time notes, remain
byte-for-byte unchanged; this source document records the subsequent successful
publication/readback. Component validation and publisher smoke are not packaged
native-browser evidence. QA startup/restart is not backend-write authorization
or lifecycle acceptance. Packaged native Receiver browser acceptance remains
pending; mobile, all-language/full-layout and the broader resource/role matrix
remain INCOMPLETE. No company-site deployment or full-site PASS is claimed.
