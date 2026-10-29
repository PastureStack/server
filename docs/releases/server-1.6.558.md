# Server v1.6.558

Published image: `ghcr.io/pasturestack/server:v1.6.558@sha256:c49c4bb1f7bcee2ae0299f196a8332657967fa2ed4e3a3496854f5bca89ec42b`.

Source commit: `33f6056476ee29eb18aa9185e59b4cb3e86c5960`.

The original publisher passed source, security, protocol and startup/restart gates.
Deployment-specific findings below are separate; publication is not full acceptance.

## Verified component inputs

- Engine `v0.183.358`, original CI producer `1da1f4c37fe43b8c387045c263d286f7db01c574`,
  merged/tag source `50569f39f241216d38661f49828dec0d925bb605`, JAR SHA256 `46ad548c6e284a7758eb7f65c85fb5878e2ebdc861ef5c396a00a6510709b733`.
  Required CodeQL and [Security run 40939424603](https://github.com/PastureStack/orchestration-engine/actions/runs/40939424603) passed.
  374 suites, 3631 tests,
  0 failures and 0 errors;
  conditional skips: 1.
- Web Console `1.6.199`, producer `80a47df65f6406087b80aa81cfa99fe1f438ecff`,
  archive SHA256 `ab60d4baa10685021b74db09b805dee1f866e9bd0fbccea4d54610df907c7570`.
- Optional bridge `0.2.1`, ZIP SHA256
  `f1477b74da0caefd7fcef77609b55b7d172683bda4afe3ffb884dfdf5a63dfae`.
  Other component pins are unchanged. Catalog launch and Archive work are not included.

## Corrected behavior

Service reconciliation may retire a managed service/instance mapping before an
asynchronous stop/remove checks its scoped Key. Preserve only the exact
engine-captured scheduling ancestry, while rechecking current owner, role, Key,
expiry, policy revision and explicit child DENY. Named/file volume deactivation
keeps its existing safe path; only the exact private instance OS volume can
inherit destructive cleanup. No historical row or caller body grants authority.
Previously cancelled jobs are not automatically replayed or retrospectively authorized.

Typed name search now filters through the normal authorized native owner before
pagination. In-memory owners filter their authorized projections before taking
a page. Late-row resources and literal wildcard characters no longer cause
repeated empty pages. Ordinary Full/legacy API contracts remain unchanged.

## Acceptance and rollback boundary

The original 557 full workflow failed during scale-down after six verified
operations and seven normal human approvals. Its raw failure and exact fixture
ledger remain recorded. The real weak-model search failure is also retained;
the model did not invent a successful result. Fourteen focused lifecycle and
three actual H2/native-query regression cases passed for this patch.

The designated 8080 installation must complete a fresh full affected lifecycle
journey and the five real weak-model cases. The six original weak fixtures may
be reused only by their exact UUID/name/project/readback ledger; no duplicate
test data or replay of an uncertain apply is needed. Unaffected role/read and
Web199 layout evidence carries forward with its original scope, not as a new
whole-matrix PASS. Other frontend workflows, advanced forms and KVM HOLD remain
separately tracked. No production origin, firewall or authentication policy changes.

Back up the database, preserve all named volumes and genuine operator overrides,
and retain the previous image. Keep existing AI opt-in properties, HTTPS origin,
security and performance settings. No database migration is added. Before rollback,
stop new clients, settle accepted work, cancel unused plans and revoke temporary
Keys. Preserve durable receipts and never replay uncertain operations. See the
[Key-policy rollback guide](../upgrades/api-key-policy-rollback.md).
Officially unfixed Medium findings retain exact package tracking; applicable
fixed, High/Critical, secret or untracked findings still block publication.
Browser SBOM coverage remains explicitly incomplete.

## Designated deployment findings

The existing QA deployment passed normal upgrade and one actual restart with
operator overrides, mounts, AppArmor, data and three active Hosts/Agents retained.
All 35 public assets and native OCI provenance/SBOM attestations were verified.

The complete affected flow remains FAILED. Ten operations completed through
normal review and eleven approvals were made; individual Service stop then left
its container stopping with an authorization-denied completion, although the
Service itself became inactive. Its Key was revoked and removed after the
failure. Downscale, Service restart and Stack stop/start passed. The exact owned
Core fixture ledger is retained for source repair; no production site was touched.

Five actual weak-model MCP cases passed: late-row Volume search, exact literal
command/entry-point arrays, missing-image clarification, same-name disambiguation,
and stale-reference recovery through the named Stack/Service hierarchy. The fifth
case originally failed an overly narrow test oracle; its original trace and native
plan readback prove an equivalent published tool sequence. A separate correction
retains the original FAILED report and four original PASS records; no model replay
or approval/apply was performed. Test Keys and six owned weak fixtures were removed
normally. Their three private OS-volume retirements were proved separately while
all 479 other recorded Volume identities/states and existing Core fixtures stayed
unchanged. Original cleanup HOLD evidence is retained with that bounded correction.

Unchanged layout and role evidence is carried forward without rerunning it.
Catalog launch, Archive/restore, advanced forms, other workflows and KVM HOLD
are not promoted to accepted coverage by this release.
