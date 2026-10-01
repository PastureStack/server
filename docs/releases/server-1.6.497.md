# Server v1.6.497

SOURCE-ONLY ASSEMBLY CANDIDATE — Server publication pending. No Server497 build,
image digest, Release assets, runtime start/restart, deployment or packaged
native-browser acceptance is claimed. The published immutable `v1.6.496` image
remains the installation and rollback reference; its historical evidence is
unchanged. This candidate does not promote historical HOLD receipts.

## Official Web Console input

This candidate pins the officially published Web Console `1.6.164`:

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
including their original vendor status and review dates. No new scan result,
raw finding count or zero-CVE result is inferred. The gate still requires zero
Critical/High, untracked, fixed-available and secret findings.

## Required gates before publication or deployment

Server source/pin gates, the actual image build, flattened one-layer identity,
34 MFA policy/API checks, isolated first start/restart `HTTP 200` / `pong`,
TLS/private-API contracts, actual merged-rootfs SBOM/security exact-set checks
and independent public asset/GHCR readback remain pending for Server497.
Component validation is not packaged native-browser evidence. Mobile,
all-language/full-layout and the broader resource/role matrix remain INCOMPLETE;
no company-site deployment or full-site PASS is claimed.
