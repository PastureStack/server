# Server v1.6.509

Published immutable release; isolated QA deployment and two existing-key scoped
closures are verified. Fresh-key first delivery remains HOLD and fresh Host
lifecycle remains pending. Server source: `261bb23c980f5f896375923233e36f6554b99751`.
Image: `ghcr.io/pasturestack/server:v1.6.509@sha256:d934c9d7bc7387626fedca5d403210fac70b7b4e35e334dcdb439f79f555ab87`.
Official publisher: [37105881483](https://github.com/PastureStack/server/actions/runs/37105881483).

## Scope

This patch packages Orchestration Engine `v0.183.333`. A shared response wrapper
previously treated every POST as creation. Consequently a POST lifecycle action
could expose a create-only field again. Creation is now classified by the actual
request dispatcher: POST with no action. All three wrapper construction paths
use that same predicate; method-only legacy constructors fail closed.

The first API Key create response still delivers the generated material. Later
GET, PUT, DELETE and POST action responses redact only fields already marked
create-only by their authoritative schema. No ordinary readable field is
redacted merely because its name contains "secret". Frozen v1 schemas remain
byte-for-byte unchanged. A non-null later secretValue was observed; this does
not establish plaintext disclosure, since the stored credential is a verifier.

Web Console remains `1.6.171`. Role authorization, databases, authentication,
OIDC/TOTP/Passkey, node agents, Catalog, firewall backends and deployment settings
are unchanged. No migration or runtime patch is required.

## Verification status

- Local targeted Engine tests: 19 passed, including 14 new regression cases.
- Fresh independent production-path review: no concrete bypass or regression.
- Engine security CI `37104364692` and CodeQL `37104364689`: passed at exact
  source `0d94f7d879d314235e582a7f4062914a27b82709`; 273 suites / 1,164 tests,
  zero errors, failures or skips; all 62 required named cases verified.
- Engine `v0.183.333`: signed immutable tag, six CI-derived assets, portable
  SHA256 and three anonymous content readbacks passed. WAR SHA256:
  `8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
  Exact WAR isolated JDK25/H2 startup exited 0 without platform data or network.
  Four existing CodeQL Medium findings remain; this is not a zero-risk claim.
- Local Server current-packaging contract: 11 tests passed.
- Server source/build/start/restart/image security/publication and independent
  public readback: passed for the exact source and image above. All 23 assets /
  22 SHA-256 checks, public tag/digest/config, single runtime layer, 34 MFA/API
  checks, TLS HTTP200 and untrusted-certificate rejection were verified.
- Security: raw52 findings, 51 VEX statements, and the existing exact-set of
  8 Medium package findings / 4 vendor-pending CVEs remain; zero Critical/High
  is not a zero-CVE claim. No security threshold or exception was widened.
- QA 8080 upgrade and read-only deployment verification: passed; first start
  after 13 retries and restart after 9 retries both returned HTTP200 pong.
  Environment overrides, runtime contract and five database table counts
  remained identical. Server508 rollback container and database backup remain.
- Owner2513 existing Account6974 scoped closure: PASS, with new native PUT200,
  deactivate POST202 and DELETE200 only; 3 writes / 9 full16-and14API guards,
  cleanup=true. The old508 POST201 create and original HOLD remain immutable.
- Existing Project6977 scoped removal: PASS, with only 1 new DELETE200 /
  4 guards and cleanup=true. The old508 POST201 / PUT200 / deactivate202
  responses are not counted as 4 new509 writes or promoted to whole-case PASS.
- Fresh Project key: HOLD. The second run created 1c6982 with only POST201;
  3 full16/14 guards and the create Store barrier passed, but the Web171 native
  first-delivery modal timed out. No issued Basic reads, edit, deactivate,
  delete or cleanup completed. The active resource is retained with no
  automatic retry or cleanup. The first zero-resource-write HOLD is retained.
- Fresh isolated Host register / healthy / deactivate / remove: pending.
  The first empty-template producer run recorded HOLD with empty writes and
  guards. Guest readiness, a template or Project fixture is not Host PASS.
- Full permission, individual-resource-ID, locale and layout matrix: incomplete.

Web172 first-delivery correction is pending packaging and native acceptance;
it is not part of the immutable Server509/Web171 image or an established fix.

Historical HOLD and PASS evidence is immutable and is not promoted to this
release. Server508 scoped results remain version-bound. Official artifact
acceptance does not establish Docker healthy, company deployment, or a complete
role matrix.

The checksum-covered `release-notes.md` asset retains its original candidate
wording as a pre-publication record; it and the other immutable assets are not
rewritten. The public GitHub Release body is reconciled separately with actual
readback, deployment and native acceptance results.

## Upgrade and rollback

Use only the exact verified immutable image above. Change only the image
reference in the existing Compose file; retain environment variables, named
volumes, restart policy, AppArmor, HTTPS origin, OIDC and performance settings.
Keep the existing Server508 image and recovery backup for rollback. QA509
upgrade/readback is verified; this work does not deploy or modify the production
site.
