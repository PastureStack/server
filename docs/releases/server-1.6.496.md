# Server v1.6.496

Published Server artifact verified. The immutable image is
`ghcr.io/pasturestack/server:v1.6.496@sha256:6c85435b3de8771e5adff0b247274e0f1b9fe9d66c8b91e07d55a444e5589678`,
from Server source `d8e0e898b08aae45e040eb085936d11de14027fb` and successful
[publication run `36821096323`](https://github.com/PastureStack/server/actions/runs/36821096323).
Independent public Release asset and GHCR readback matched the source, component
pins, immutable digest, all 22 checksummed files plus their manifest, and the
single filesystem layer. Downloaded publication notes remain byte-for-byte
unchanged; this source document records the subsequent public readback.

Isolated QA496 deployment and two scoped desktop observations passed as recorded
below; publication checks and these observations have distinct acceptance scopes.
No company-site deployment is claimed.

This release packages the officially published Web Console `1.6.162`:

- Numeric tag and artifact source commit:
  `46501e31071b3d74595aea91908876eec32b7fd6`.
- Artifact: `web-console-1.6.162.tar.gz` (2,975,702 bytes).
- Archive SHA-256:
  `9c5b34d2cdf7ad354e1dab199795b12e5de119e47dc342547d5cdc84c7911581`.

This release consumes Orchestration Engine `v0.183.328`, from source
`ad43f4b6790c359e248710a39bca2f776d70be62` and artifact SHA-256
`184fb3d4a2b026560e1e60d7b444f693f79bff6c8220cc9354c1284012f6a683`.
Its WAR contains the published distributed-cache runtime `5.7.5` as
`WEB-INF/lib/hazelcast-5.7.5.jar`, with SHA-256
`0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715`.
The embedded Jackson core/databind metadata is `2.22.3` / `3.2.3`; numeric
Hazelcast cluster runtime remains `5.7.3`. The successful Server publication
verified these assembly inputs; that evidence does not establish native browser
or deployment acceptance.
All other platform component coordinates and runtime dependencies are unchanged.

## Narrow desktop changes

The Host **Add Container** entry follows the current project's loaded Container
schema POST capability. Missing, loading, stale or revoked project schemas do
not enable the entry. This is a client UI capability gate, not evidence of
backend POST or PUT authorization; schema GET success is not write permission.

The Secret desktop table's State, Name, Description and Created headings use
the existing generic translation keys. The existing field names, sort and
search behavior remain unchanged. This does not claim mobile acceptance or
all-language acceptance, nor does it relabel historical English screenshots as
Chinese-language evidence.

No authentication, session, OIDC, MFA, API status, database, VM or permission
policy changes are included. Existing historical
HOLD receipts remain HOLD. The broader resource/role matrix remains INCOMPLETE;
no full-site acceptance or company-site deployment is claimed.

## Published packaging evidence

The official publication run passed candidate first start and restart with
`HTTP 200` / `pong` (12 initial attempts and eight restart attempts), 34 MFA
policy/API checks, private API `no-store`, trusted TLS 1.2/1.3 reads and rejection
of an untrusted TLS certificate. These are publication checks, not QA496
deployment or packaged native-browser acceptance.

The merged-rootfs Trivy `0.74.0` scan reports 58 raw findings and 14 exact
vendor-pending package findings after VEX: eight Medium and six Low, covering
six unique CVEs, with review due 2026-10-08. Untracked, Critical/High,
fixed-available and secret findings are zero; the JSON/TSV pending set and exact
VEX finding/purl set match. The unchanged security gate passed. This is not a
zero-CVE claim.

## Isolated QA496 deployment and desktop observations

The immutable QA `8080` upgrade returned PASS: first start and restart each
reached `HTTP 200` / `pong` in 10 attempts. Runtime-contract, first-start DB and
restart DB differences were zero; the five tracked `account`, `credential`,
`setting`, `project_member` and `host` counts matched before/after. This is
count preservation, not a whole-database row comparison. Docker health is
`null`; no Docker `healthy` result is claimed. `docker-default`,
`unless-stopped`, environment overrides and the stopped `v1.6.495` rollback
container were retained. Deployment receipt `v496-deploy-20261001/result.json`
has SHA-256 `ef3e411485a7bb9b759a9a6a27f29987c3f7c5f7e95a5fddd9615f0f706ef73b`.

Two packaged desktop cases returned raw PASS at `1440 x 1000`, with zero
resource writes. Subsequent screenshot review supports only these observations:

- `host-readonly/qa496desktop1567d7bd87ea`: the readonly Host Add Container
  entry was absent and Edit unavailable. Host statistics remained connecting;
  the right-side table was not fully reviewed. Result SHA-256:
  `8283f2ec75cfc82aaf894d2fa183d9451d6746dbb93a2ca6cc3d87cfbf4159c3`.
- `secret-member/qa496desktop4a6e3b58b5d8`: the member Secret table's State,
  Name, Description and Created headings were Traditional Chinese. The body
  was deliberately masked; plaintext/body rendering was not accepted. Result
  SHA-256: `0973ef57b70acf2ca2e5f2fd3b7f51e07dd839dd03a657d199ba71a62162f736`.

The browser cases are zero-write observations, not backend-write authorization
tests, resource lifecycle or full DB-preservation tests. They do not establish
full-layout acceptance. Mobile and all-language acceptance remain pending;
the broader resource/role matrix remains INCOMPLETE. Historical HOLD receipts
remain HOLD and are not promoted; no company-site deployment is claimed.

### First publication attempt: blocked, not released

[Publication run `36812661669`](https://github.com/PastureStack/server/actions/runs/36812661669)
from source `8bbd636c6899a2d0444dbf579254c8252db6eb36` stopped at the unchanged
merged-rootfs security gate. Image push and release creation were skipped.
Its scan found four distinct HIGH Jackson findings (CVE-2026-91776 and
CVE-2026-91777 in Jackson 2.22.2 and 3.2.2), including copies embedded in the
Hazelcast runtime. Both dependency paths must consume the official fixes before
a new publication attempt; changing only the Engine's direct POM pins would
leave the embedded copies unchanged. No successful Server 496 artifact or
runtime acceptance is inferred from this failed run.

The scan also found six new LOW package findings for the three Ubuntu OpenSSL
packages at `3.5.5-1ubuntu3.6`. Ubuntu's official status on 2026-10-01 lists
[CVE-2026-42772](https://ubuntu.com/security/CVE-2026-42772) and
[CVE-2026-54873](https://ubuntu.com/security/CVE-2026-54873) as vulnerable in
26.04 without a released distribution fix. The exact packages and versions are
recorded in `server/security/vendor-pending.json`, with review due 2026-10-08;
the existing eight Medium findings remain tracked. The gate still requires
zero HIGH/Critical, zero untracked findings and no available fixes among the
pending set. No severity, scanner or gate is disabled, and no upstream patch
is cherry-picked into Ubuntu packages.

For a later isolated upgrade, preserve the current environment variables,
named volumes, restart policy, AppArmor configuration and HTTPS origin. Retain
the published `v1.6.495` image above with those same settings as the rollback
image. No stored-data migration is included.
