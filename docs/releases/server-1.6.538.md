# Server v1.6.538

Officially published on 2026-10-20. Targeted QA8080 deployment acceptance passed
within the 29-check narrow scope below; this is not a claim of company-production
deployment or whole historical matrix acceptance.

## Immutable publication identity

- Signed, verified producer: `9dd8f1da85c57fc2424b9f58c278331cf679b8fc`.
- Official workflow: [39362063157](https://github.com/PastureStack/server/actions/runs/39362063157), completed successfully without bypassing required checks.
- Manifest: `sha256:10284f7c3e3a04d7212accae9bdb6daac89ea2f23bc39cd1064e937415af231e`.
- Distinct OCI config: `sha256:cd754a3eb44536004322bd28471bc094a5c13ead64b420fcde07a97d9a1912a5`.
- Artifact identity, not an installation command:
  `ghcr.io/pasturestack/server:v1.6.538@sha256:10284f7c3e3a04d7212accae9bdb6daac89ea2f23bc39cd1064e937415af231e`.
- Platform: linux/amd64; one flattened runtime layer, 540,239,336 compressed bytes.
- [Immutable release](https://github.com/PastureStack/server/releases/tag/v1.6.538): all 25 official assets passed anonymous digest and `SHA256SUMS` readback.

Documentation commits and the current release body do not replace the producer,
image or immutable assets. The attached `release-notes.md` preserves the
producer's build-time source snapshot, including its then-candidate wording;
this document records the subsequent publication and acceptance status.

## Security changes

- Web Console `1.6.191`: official Handlebars `4.7.10` and fast-uri `3.1.8`
  fixes. Producer `1452148e0ca2c0dc798dc08a653eb90196d4f88b`; archive SHA-256
  `f9b28c25ae27057ae39e55fb29400b8ac459e07632a441eea011591f305950ab`.
- API Explorer `1.1.19`: official Handlebars `4.7.10`, with actual packaged
  runtime/escaping tests. Producer `dda3fe8a806d9736de771d325e3ca98ab4067cd2`;
  archive SHA-256 `d1602ab6033512f0b86dc8ceafee2061364ce2fc5da2a9b7119f900d9e0f3c25`.
- Catalog producer `71ec6b2c27355e709f5092c954db24efa800bc41` selects
  Scheduler revision5 / `v0.8.19`; previous revisions1-4 are unchanged.
  The signed Scheduler producer is `d1720ddb65a285ed615f1461ccb44e50c2ad67a7`,
  image manifest `sha256:46dfecc72fc1fceab5c66f881f46449874b6a084a208f59c6ef1184a0d15c3f9`.
  Its official OS/toolchain security fixes retain the scheduling protocol,
  health endpoint and module boundary. Existing installations upgrade the
  Scheduler through the normal Catalog upgrade/finish-upgrade lifecycle;
  changing the Server image alone does not replace an already running service.
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

The official producer passed the actual candidate JDK identity, module, native
libnet/libnio and Java schema serialization fixture, including the twelve-role
frozen identity-security schema contract. `java-security-runtime.txt` records
Temurin `25.0.4.1+1` and the exact official archive checksum above.

The final image returned HTTP200/pong on fresh startup and restart after 11/7
polling attempts, retaining the configured public origin and private API
`no-store` contract. The existing MFA-policy API smoke passed 34 checks;
registration passed seven entry-only checks, not active-node acceptance.
These are isolated official candidate gates, not a Docker Healthcheck claim.

The fresh merged-rootfs security/SBOM gate records 73 raw findings and 29 exact
unfixed LOW/MEDIUM package occurrences across 18 CVEs after the existing VEX
policy. Review is due 2026-10-27; untracked, critical/high, fixed-available and
secret findings are all zero. The attached raw scan, effective scan, exact
vendor tracker and VEX remain separate evidence; neither tracking nor VEX
constitutes remediation, a HIGH waiver or a zero-risk claim.

### Targeted QA8080 acceptance

The QA runtime was switched to this exact published producer, manifest and config
identity. Startup and restart health passed with all three named volumes and
runtime overrides unchanged. The prior working `v1.6.537` image/container and
pre-upgrade backup were retained. VM definitions/disks were not removed or
reconfigured; company production was not modified.

Both existing QA Schedulers completed the normal Catalog revision4 to revision5
upgrade from `v0.8.18` to `v0.8.19`, with HTTP202 for both upgrade and
finish-upgrade. Existing explicit answers and effective runtime configuration
(scale, command, health, logging, network and privileged settings) were preserved.
Both Schedulers are active/healthy;
all three existing Hosts and Agents are active. New disposable workloads were
observed on their intended Hosts and became healthy; native exec returned
HTTP101 with the expected marker, and canonical own-service DNS and egress passed.

Acceptance totals 29 unique narrow checks: 25 carried PASS receipts, two API
Explorer locale cases, and two additional workload cases for the second
Scheduler. API Explorer `en-US` and `zh-TW` loaded the packaged Handlebars `4.7.10`
runtime without a compiler, visible load error or overflow. Native browser
Stack/Key-list and cookie-authenticated reads returned HTTP200; the existing
WebSocket check received 23 frames. Page errors, passive DELETE requests and
blocked writes were zero. Four 1440x1000 screenshots (Stack, Key list and the two
API Explorer locales) were reviewed with no visible errors, overflow or missing
translations.

All owned temporary Stacks, Services and Keys were removed with actual ID/UUID
readback; no VM, persistent volume, retained rollback container or existing
non-test workload was deleted. These receipts are bounded acceptance, not a
rerun of the full role matrix, thirteen locales, OIDC or Passkey suites. Unaffected
PASS receipts retain their original scope; KVM and unrelated historical pending
items remain pending. An inherited API Explorer `iv="header-body"` markup typo
is recorded for separate review only, not changed by this CVE release; the browser
oracle verified actual loaded schemas, rendered content and client error state.

## Upgrade and rollback

Installation examples use numeric `ghcr.io/pasturestack/server:v1.6.538` only,
not digest-qualified commands. Preserve the existing environment variables,
three named volumes, restart policy, AppArmor and public origin. Retain the
working `v1.6.537` image/container as code rollback; do not reset databases,
credential/revocation state, mounts or VM data. Company production is not a
deployment target for this work.
