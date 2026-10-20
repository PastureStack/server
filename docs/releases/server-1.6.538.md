# Server v1.6.538 candidate

Prepared source only; no Server image or release has been published.

## Security changes

- Web Console `1.6.191`: official Handlebars `4.7.10` and fast-uri `3.1.8`
  fixes. Producer `1452148e0ca2c0dc798dc08a653eb90196d4f88b`; archive SHA-256
  `f9b28c25ae27057ae39e55fb29400b8ac459e07632a441eea011591f305950ab`.
- API Explorer `1.1.19`: official Handlebars `4.7.10`, with actual packaged
  runtime/escaping tests. Producer `dda3fe8a806d9736de771d325e3ca98ab4067cd2`;
  archive SHA-256 `d1602ab6033512f0b86dc8ceafee2061364ce2fc5da2a9b7119f900d9e0f3c25`.
- Replace the actual inherited JDK `25.0.3`, not only the separate from-scratch
  Dockerfile, with official Temurin `25.0.4.1+1`. The complete archive is verified
  against SHA-256 `dbb698396d478e7fa2b1e50f4103324b2a99b90569ee27c33f2261f9215cf41e`.
  The update retains Java25 LTS, required module opens, GC/performance controls,
  CA bundle and JDK tools. See the [Adoptium security release](https://adoptium.net/en-GB/news/2026/09/eclipse-temurin-8u504-110321-170201-210121-25041-26021-available)
  and [Oracle advisory](https://linux.oracle.com/errata/ELSA-2026-55798.html)
  for CVE-2026-60589, CVE-2026-61308, CVE-2026-70906 and CVE-2026-70907.
- Refresh the official vulnerability database and re-evaluate the complete
  released Server and CLI SBOMs, rather than checking only previous CVE IDs.
  This found seven additional Ubuntu CVEs: two in dash and five in GnuTLS.
  Canonical currently provides no Ubuntu26.04 fix; retain all 18 unresolved
  Server CVEs / 29 package occurrences for review on 2026-10-27. This is tracking,
  not remediation. Existing exact VEX statements are unchanged.

The Server SBOM does not by itself prove the safety of minified JavaScript or
every JDK security patch; official upstream advisories, actual build inputs and
runtime identity are checked separately. Unpatched Web build-only braces HIGH
findings remain explicitly visible under an exact, expiring review, not a
blanket runtime exception. Newly discovered findings and available official
fixes remain fail-closed under the existing release policy.

## Scope and acceptance

Engine `v0.183.350`, OIDC/MFA/session, API authorization, archive behavior and
firewall architecture are unchanged. Source-only LZ4/RabbitMQ dependency fixes
in distributed-cache-runtime do not require a new core JAR or Engine release:
the published core artifact does not contain either dependency.

Required evidence before calling this release complete: signed/protected PRs,
exact official component assets, actual candidate Java identity and schema
serialization fixture, startup/restart with existing auth/registration smoke,
fresh merged-rootfs SBOM/security scan, immutable registry/release readback,
then QA8080 upgrade preserving configuration and volumes. Run only affected
UI/API/JDK and scheduler lifecycle checks; retain unaffected PASS receipts and
leave KVM and unrelated historical pending items pending. Final identities and
results will be added after publication and QA readback.

## Upgrade and rollback

Installation examples use numeric `ghcr.io/pasturestack/server:v1.6.538` only,
not digest-qualified commands. Preserve the existing environment variables,
three named volumes, restart policy, AppArmor and public origin. Retain the
working `v1.6.537` image/container as code rollback; do not reset databases,
credential/revocation state, mounts or VM data. Company production is not a
deployment target for this work.
