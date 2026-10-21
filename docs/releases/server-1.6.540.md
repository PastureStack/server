# PastureStack Server v1.6.540

This document describes the Server `v1.6.540` assembly. Source changes alone are
not publication proof. Before installing, verify the official release assets,
producer and immutable registry digest; do not use a guessed tag or treat prior
Server evidence as 540 results. Follow the current published installation
instructions in the [README](../../README.md#quick-start).

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

Web Console `1.6.192`, Linux Node Agent `v0.13.29`, API Explorer `1.1.19` and the
patched Temurin `25.0.4.1+1` are retained. There is no schema/data migration, new
required volume or firewall-backend switch.

## Go helper security input

The digest-pinned official Go helper advances to 1.27.3, including the
crypto/x509 security update. The Server-built console broker is compiled with
that exact toolchain and its binary build information and runtime marker are
checked. Its go.mod minimum remains unchanged.

Other Go executables are retained as their exact published component artifacts,
including their Go 1.27.2 producer metadata and hashes. Updating the helper does
not rebuild or remediate those binaries. Their existing vulnerability checks
remain required; this change adds no VEX exception or release-threshold change.
Server 539 publication evidence is historical and is not rewritten as a 540
build, scan or runtime result.

## Evidence boundaries

The official release workflow must pass source, packaging, startup/restart,
runtime-security and artifact checks before publication. Its immutable release
assets identify the exact producer, component hashes, SBOM, vulnerability review
and image digest. Targeted QA runtime results are separate from build checks;
source tests or one successful request are not a whole permission-matrix PASS.

The LB's two-instance causal reload test observed controller-owned zero,
temporary initial zero after reload, recovery to formal weights `1`/`7`, and
HTTP 200 through both routes. A no-reload condition, every manual-control branch
and the broader state-transition matrix are not implied by that result. The
observation did not prove the target Docker restart epoch and is not a complete
native acceptance PASS.

Unchanged acceptance evidence is carried forward without rerunning unrelated
cases. KVM remains deferred. Officially unfixed LOW/MEDIUM findings are tracked
under the existing policy; untracked, fixed-available, CRITICAL/HIGH and secret
findings still block release. VEX and tracking records are not vulnerability
fixes or a zero-risk claim.

## Upgrade and rollback

Only after the official Server `v1.6.540` release and image are published and
read back, use its numeric tag with the existing Compose configuration. Follow
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
