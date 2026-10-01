# Server v1.6.496

Candidate packaging only. No Server `v1.6.496` image, digest or deployment is
claimed. Packaged desktop acceptance and isolated runtime acceptance remain
pending. The currently published Server remains
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`;
public quick-start and compatibility instructions still use that release.

This candidate packages the officially published Web Console `1.6.162`:

- Numeric tag and artifact source commit:
  `46501e31071b3d74595aea91908876eec32b7fd6`.
- Artifact: `web-console-1.6.162.tar.gz` (2,975,702 bytes).
- Archive SHA-256:
  `9c5b34d2cdf7ad354e1dab199795b12e5de119e47dc342547d5cdc84c7911581`.

This candidate consumes Orchestration Engine `v0.183.328`, from source
`ad43f4b6790c359e248710a39bca2f776d70be62` and artifact SHA-256
`184fb3d4a2b026560e1e60d7b444f693f79bff6c8220cc9354c1284012f6a683`.
Its WAR contains the published distributed-cache runtime `5.7.5` as
`WEB-INF/lib/hazelcast-5.7.5.jar`, with SHA-256
`0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715`.
The embedded Jackson core/databind metadata is `2.22.3` / `3.2.3`; numeric
Hazelcast cluster runtime remains `5.7.3`. These pinned assembly inputs do not
replace the required new Server artifact scan or runtime acceptance.
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

## Required packaging evidence

The local source gate is not an artifact scan, image build, first start,
restart or native packaged-browser acceptance. A new immutable Server artifact,
its official digest/readback, merged-rootfs security gate and isolated runtime
checks are still required before publication or deployment claims. The VEX and
vendor-pending release identities are advanced for this candidate. This is not
a zero-CVE claim.

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
