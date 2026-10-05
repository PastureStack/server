# Server v1.6.515

Status: published immutable Server image and Web component, with independent
public readback. Separate isolated QA 515 / Web 177 deployment/readback passed;
native lifecycle acceptance remains pending. The complete functional matrix
remains INCOMPLETE, and historical HOLD results are unchanged. No production
deployment is authorized by these checks.

## Repair

Web Console `1.6.177` prevents ended log and terminal workspace entries from
opening another connection. Late ticket/broker responses, socket callbacks and
timers retain their original entry identity and cannot update a replacement.
Ended terminal input is disabled. Explicitly opening a new entry and reconnecting
a live session remain supported.

API contracts, role permissions, workspace persistence, generation/mutex and MFA
are unchanged. This packages the normal Web release; it is not a runtime patch.

## Published Web component

- Numeric lightweight tag `1.6.177` binds the signed source commit below; this is
  not a signed tag:
  `b9b841e65afe1d89a5b03ac767e9168bccd3c3ea`.
- Reviewed tree: `109a60fc005d9dc18e38864089dd0055980485c3`.
  Normal PR #175 squash merge `5d150806be20226657e5caa8a0150d068006c772`
  has the same tree and a verified signature.
- [Formal CI 37255121243](https://github.com/PastureStack/web-console/actions/runs/37255121243):
  841 tests passed, zero failures/todo, including 17 new lifecycle regressions;
  both CodeQL checks passed. Two CI archives were byte-identical.
- `web-console-1.6.177.tar.gz`: `2982494` bytes, SHA256
  `4e34eb2b3165f078134cddcf1721239b3da7baf11dd683991b2d6aa5bae944e0`.
  Anonymous HTTP 200 download matched those immutable archive bytes.

These observations establish the published Web component, not live UI acceptance.

## Published Server artifact

- Source: `f0267ff3a347ea526088db1749b1d3c8dfd9bd37`.
- Reviewed and normally merged tree: `4bdb4a10132f467bc163f9afa9b55c2518a4e514`.
- [Official publisher 37256753740](https://github.com/PastureStack/server/actions/runs/37256753740)
  succeeded; the independent public reader verified 23 assets and 22 checksums,
  immutable release/source, component provenance, registry/config and SBOM identity.
- Immutable image:
  `ghcr.io/pasturestack/server:v1.6.515@sha256:fcc79f616927040ef2b3a5c58662fa948823220dbc57ffe275dee2ad88764d47`.
- Official readback receipt SHA256:
  `6e0e3ef7bd3ca9741d8e8ef84c16c46a6bf3e9033e72383cdcf960435a5608ed`.
- Isolated artifact polling reached HTTP 200/pong after 11 initial-start and 7
  restart attempts; 34 MFA/API checks, TLS 1.2/1.3, untrusted-certificate rejection
  and private `no-store` passed.
  These publisher checks are separate from deployed QA or native UI acceptance.
- Merged-rootfs scan retains 52 raw findings, 51 VEX statements and 8 Medium
  vendor-pending package findings across 4 CVEs; untracked, Critical/High,
  available-fix and secret counts are 0. Review deadline remains 2026-10-20; no zero-CVE claim.

## Isolated deployment and readback

The exact published Server 515 / Web 177 image was deployed on the isolated QA site
and independently read back. Initial-start and restart polling reached HTTP 200/pong
after 10 and 11 attempts, respectively.
Runtime-contract difference and both five-table count differences were 0;
environment overrides, three named persistent volumes and the Docker socket bind
were preserved. `docker-default`, bridge networking and `unless-stopped` remain
unchanged; the 514 rollback image/container and database backup are retained.

The container is running but has no Docker Healthcheck (`health` is null), so this
is not a Docker healthy claim. Earlier incomplete attempts remain unchanged.
This deployment scope does not establish native logs/terminal/container lifecycle,
all roles/locales/resources or production acceptance. Those native checks remain pending.

A separate fresh Project v2 native run remains HOLD. Native creation returned
HTTP 201; edit cancellation issued no additional resource write. Save PUT and
set-members POST returned HTTP 200, with the saved description preserved after
reload and save ownership released. Deactivate, the fourth resource write,
returned HTTP 200, but the following UI wait timed out. Five guard captures were
retained. Native removal and database cleanup were not completed; these partial
observations do not establish complete Project lifecycle or full-matrix PASS.

## Unchanged assembly and rollback

Engine `v0.183.333`, source `0d94f7d879d314235e582a7f4062914a27b82709`,
WAR SHA256 `8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`
and Catalog Service `0.20.12` remain pinned. All other component/plugin pins,
the Server460 immutable base, four build stages and final one-runtime-layer
publication/config-comparison flow are unchanged.

VEX and vendor-pending declarations change only their Server release identity;
the reviewed CVE statements and exact vendor-pending set are unchanged.
The published artifact passed its own source, image, runtime and security gates;
none of these gates substitute for isolated deployed native acceptance.

Quick Start now pins the published immutable 515 reference. Preserve 514, existing
configuration, named volumes and backups for rollback. Catalog database IDs,
including API template IDs, may remap within an existing refresh transaction;
this repair does not change that 514 contract.
