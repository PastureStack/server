# Server v1.6.540

Published Server `v1.6.540` is the immutable image
`ghcr.io/pasturestack/server:v1.6.540@sha256:b6b3909578f4e05a3cdccb1c24640ee3fbc6f8919d0b06a787ee1d3830d7e1c2`,
from source `cb78888bd156f9aca3b0c31b2b2076319bc116cf` and successful
[publication run `39683753151`](https://github.com/PastureStack/server/actions/runs/39683753151).
All 26 official assets were anonymously read back with exact sizes and SHA256.
The linux/amd64 image has one runtime layer, 516,223,196 compressed bytes.
OCI config `sha256:2a2377f42dfa0dccf2940528d484cbe333c9e7e817a6902ba968bf3021c6a14e`
is not the registry manifest digest. Use the published numeric tag in the
[README installation commands](../../README.md#quick-start), not a guessed
future version or a digest pasted into the command.

The release gate recorded 73 raw findings and 29 exact vendor-pending package
occurrences across 18 CVEs, with zero untracked, CRITICAL/HIGH, fixed-available
or secret findings in its recorded scan scope. Tracking is not remediation or a
zero-CVE claim. The owned QA125 deployment then passed startup/restart health
while preserving all three volumes, runtime overrides and the two LB DB settings.
This is targeted acceptance, not full native-matrix or Windows networking PASS.
Publication receipt SHA256 is
`061ea5608abda9561f740b0577ad5731885d4803a5c428469d6d7d9309efb80c`;
the separate targeted-switch receipt is
`1ae315d416a2554456b29c27971b29ee476a4ebb59345ffd027ad167d3b0e5ad`.

The current assembly consumes the immutable, anonymously read-back official
Engine `v0.183.351` release (two assets). Its actual WAR producer is
`1befd83278618f9a5b7cdaf96522004dd89918ba`; JAR SHA256 is
`efd0e826364c551f782b281f081d53cadb48faa7d5c37c2f101e6f9c7d7f9ea6`.
The signed main merge `fdc5ae7862f3c44b156955aab9cf016365d5d67d` has the
same whole source tree `8f4ae4ae332014b67e8dae5dde197cc865bf53b6` as that producer;
it is the tag target, not the WAR producer identity. The Engine publication
receipt SHA256 is `9b9afea66ce949f6f4ef7080c44f5faf0f6fb41fedfbca867694b23747dc23f4`.

## API Key write completion and audit storage

Engine `v0.183.351` rechecks the current credential inside the existing write
transaction before a synchronous mutation completes. A Key revoked, narrowed or
expired while waiting for a database lock cannot complete using its earlier
admission snapshot. The denial rolls the mutation back and records its actual
completion outcome. Full and legacy Keys retain their existing capabilities;
the Key owner's current permissions remain the upper bound.

Ordinary audit request/response data is copied and recursively sanitized. The
custom jOOQ listener records operation type, counts and duration rather than SQL,
bind values, records or exception messages. This protects new records; it does
not remove secrets from historical logs or recognize a secret deliberately put
in an unrelated resource name or description.

The administrator's `-Dpasturestack.audit.outbox.dir` remains supported, including
relative/absolute paths and intentional configured symlinks. The default stays
in `/var/lib/cattle/data/api-key-audit-outbox`, inside the existing data volume.
Linux verifies the canonical destination and opened directory handle, service
ownership, private write permissions and bounded direct-child I/O. Existing
event names and first-terminal replay remain compatible. No CodeQL query,
threshold or required check is weakened. See the Engine's
[audit storage requirements](https://github.com/PastureStack/orchestration-engine/blob/v0.183.351/docs/api-key-policy.md#audit-storage)
before upgrading an unsafe custom spool.

## Load balancer lifecycle

The packaged default and HA Compose templates select official Load Balancer
`v0.9.32`. Its controller retains evidence of its own temporary drain across
stopping metadata and HAProxy reload, then restores the applicable configured
weight after the target is ready. It does not restore every zero to one.

An existing database setting, environment override or deployed LB is not silently
upgraded. Keep custom images and explicit weights. Upgrade an existing LB through
its normal service upgrade/review/finish or rollback flow. A runtime-socket-only
override is not a persisted port-rule setting; use the normal configuration when
an intentional zero must survive a reload.

Web Console `1.6.192`, API Explorer `1.1.19` and the patched Temurin
`25.0.4.1+1` are retained. There is no schema/data migration, new required
volume or firewall-backend switch.

## Go runtime security update

The digest-pinned official Go helper advances to 1.27.3, including the
crypto/x509 security update. The Server-built console broker is compiled with
that exact toolchain and its binary build information and runtime marker are
checked. Its go.mod minimum remains unchanged.

The ten other runtime executables are replaced by exact official component
artifacts compiled with Go 1.27.3: Authentication Service 0.4.44, Catalog Service
0.20.14 (both binaries), WebSocket Proxy 0.23.16, Compose CLI 0.14.38,
Host Provisioner 0.39.9, Secret Delivery API 0.3.3, Usage Telemetry Agent 0.4.3,
Webhook Automation Service 0.10.5 and vSphere CLI Bundle 0.55.4. Their actual
artifact producers may differ from signed squash-merge or later documentation
commits; the recipe pins the actual producer and both archive/binary hashes.
Legal attribution, compatibility aliases and component ownership are preserved.

Delivered Host API `0.38.6`, Node Agent `0.13.30` (Linux and Windows) and
CLI `0.6.19` also use the fixed toolchain. Node Agent retains exact Host API
version matching, now paired to `0.38.6`; no fallback or authentication bypass
is introduced. The Windows ZIP retains its own existing package layout and
has no Linux package ID. Cross-build qualification is not Windows native QA.

The final-image gate verifies the exact active Host/Node archives and their
inner executable and installer hashes, inspects Go producer metadata, and
scans all three inner executables for vulnerabilities and secrets. Their raw
scan and CycloneDX inventory are retained in `server-nested-payloads.json`
alongside the unchanged rootfs scan; compressed content is not assumed covered
by an outer filesystem scan. Superseded versioned Host/Node bundles are removed
only while constructing the new image, after active download references are
updated. Active aliases and unrelated packages are preserved; no live VM,
container, volume or rollback image is removed.

The first Server540 publication attempt correctly blocked retained Go 1.27.2
binaries for fixed-available `CVE-2026-111943`; that failed attempt created no
release tag or image. Updating only the helper was insufficient. The component
releases and final-image gate remain required; there is no Go VEX exception or
release-threshold change. Server539 and failed-attempt evidence remain historical,
not rewritten as a successful new 540 build, scan or runtime result.

## Evidence boundaries

The official release workflow passed source, packaging, startup/restart,
runtime-security and artifact checks before publication. Its immutable release
assets identify the exact producer, component hashes, SBOM, vulnerability review
and image digest. Targeted QA runtime results are separate from build checks;
source tests or one successful request are not a whole permission-matrix PASS.

Separate QA on the published LB `v0.9.32` proved a new target Docker restart
epoch, controller-owned drain zero and recovery through both LB instances for
default weight `1` and custom weight `7` in separate runs. Both preserved a
persisted zero and an independent weight `1`, with successful HTTP traffic after
recovery. Both LB PIDs reloaded; the no-reload precondition was not reached.
The earlier default-weight verifier failures remain historical, not product
failures or passing evidence. Every manual-control branch and the broader
lifecycle matrix remain separate. None of these observations is a Server540
deployment result or a whole-matrix PASS.

Unchanged acceptance evidence is carried forward without rerunning unrelated
cases. KVM remains deferred. Officially unfixed LOW/MEDIUM findings are tracked
under the existing policy; untracked, fixed-available, CRITICAL/HIGH and secret
findings still block release. VEX and tracking records are not vulnerability
fixes or a zero-risk claim.

## Upgrade and rollback

The official Server `v1.6.540` release and image have been published and
read back; use its numeric tag with the existing Compose configuration. Follow
the [current published instructions](../../README.md#quick-start).
Preserve all three named volumes, restart
policy, AppArmor, public HTTPS origin, OIDC/MFA settings, performance parameters
and the host's existing firewall backend. Do not replace the company reverse
proxy or patch running binaries to apply this release.

Before upgrade, back up the database and data volumes, including a custom audit
spool, and retain `v1.6.539` as the previous Server image. Ensure the configured
spool belongs to the Engine service account and has no untrusted writers; the
upgrade does not chmod existing administrator directories. Roll back code using
the retained image and the same volumes, not by resetting database, credentials
or API Key policy records. Preserve an existing LB's own rollback image and
operator settings separately.
