# Server v1.6.583

## Published release

[Server v1.6.583](https://github.com/PastureStack/server/releases/tag/v1.6.583)
is published from the original image below. Final normal read-only verification
completed at `2026-11-07T16:02:22.760926+00:00` with status
`PASS_PUBLISHED_READY_FOR_8080` / `PASS_NORMAL_READ_ONLY_COMPOSITE`.
The same image passed isolated deployment, restart and smoke verification.
Remaining business/native acceptance is pending; complete frontend coverage
remains in progress across 243 groups.

| Component | Published version |
|---|---|
| Engine | `v0.183.385` |
| Web Console / optional Bridge | `1.6.225` / `0.2.27` |
| Catalog / Compose Executor | `0.20.17` / `0.14.43` |

## Changes and boundaries

Ordinary Stacks support reviewed Group changes, including exact case, whitespace,
commas, empty string and null, combined with name/description. System, Catalog
and externally managed Stacks remain outside this typed subset. Current native
role, project/Stack UUID, Key scope/revision and configuration CAS are still
required; only a person can approve execution.

Builtin-local unallocated Volume creation now recognizes native inactive
completion. A logical record does not establish physical Host allocation,
mounting or retained-data safety. Two fresh logical-record create/readback/cleanup cases passed native acceptance;
physical storage and mounted data remain outside that scope.

Tool descriptions now put the required preview envelope and opaque source/target
references first, explain full link replacement and explicit clearing, and retain
normal human confirmation. Safe native validation field names are preserved
without values or raw error details. An unavailable reference prompts a fresh
find/read with the same Key and environment, without distinguishing absence from
lack of access or expanding authority. Tools, privileges and default-off flags
are unchanged. Service configuration, bounded logs and other previously scoped
workflows retain their existing limits and original PASS/FAIL evidence.

## Exact artifact and component evidence

Original image:
`ghcr.io/pasturestack/server:v1.6.583@sha256:e22ecd94bbc83c2d34f49aa7dde231301f42a26de9a89c929e8a11d886b6c78c`.
Original build source `6e6befedc7cd97dc3685ef7f6010b1fa2506bd77`, tested tree
`aa6227d081ad14c6237e6af062357ce1c22d034b`.

Engine producer `1bd87ed39b0ccae7852c7407003692f35ecf83da`, tree
`e2e475d69ef7a681992475b2f064717a43bee119`; cattle.jar SHA-256
`b75146e629fa7991bf32087088f81629e59a7fa69f6d9e2f742aebca7d696762`.
Its original CI recorded 473 suites / 4,229 tests, zero failures/errors, one
inherited skip, 415 required methods and 72 packaged roots.
Web producer `01e55cfc800b5bd728821df7193e2b6fe4286cd9`, tree
`3a9172750200a1d84441f25946d78cbad18e4613`; archive SHA-256
`1e7ebdd819f7a36524e3345b9e1b06f8c5805fd313ede8586b72d099f543bb96`.
Its original CI recorded 1,142 browser tests and 290 focused identities; the
matching Bridge passed its actual SDK handshake. Component CI, compiled C03/role
closure, release crypto and anonymous bytes are separate from Server native PASS.

## Publication recovery record

Original publisher [42381092651](https://github.com/PastureStack/server/actions/runs/42381092651)
passed source/build/flatten/security/startup/restart and semantic image publication,
then failed creating the provenance transparency-log entry with HTTP500. The
original run and earlier failed recovery attempts remain failed.

Recovery [42388223188](https://github.com/PastureStack/server/actions/runs/42388223188),
source `b9fcd2bd840fb7425c575d487ca43c296d492fd3`, appended the signed custom
same-artifact statement and original CycloneDX SBOM to the same digest, verified
both native OCI proofs, and created immutable Release `437671242`. Its immediate
`gh release verify` returned nonzero; that workflow/job remains failed. Subsequent
normal read-only verification passed all publication postconditions: original and
recovery source/run identities, exact prepared 35 assets and original source tag,
36 native release-crypto subjects, 35 anonymous-byte readbacks, both OCI signatures,
transparency witnesses and full predicates, plus the normal component/security gates.
No image rebuild, semantic repush, new scanner execution or immutable asset rewrite
was used for this completion.

The custom predicate type is
`https://github.com/PastureStack/server#recovery-v1`. Its certificate identifies the
actual recovery signer/run; the original builder record is reconstructed from the
original official evidence and is not an original signed SLSA statement.
`originalNativeSlsaAvailable=false`: no original standard SLSA or SLSA-level PASS
is claimed. See the [fixed recovery protocol](../operations/server583-publication-recovery.md#recovery-v1).
This repository note records the final readback; immutable release assets retain
their original bytes.

## Isolated deployment and restart readback

The normal capture, pull, dry-run, cutover, restart and smoke stages all passed
at `2026-11-07T16:31:38.290451+00:00`, using the exact published digest and original
build source recorded above. New Server container:
`f210c36d85949bc5689b696d048d597524c598dd9427168cea68c4f688db048f`.
Its start timestamp changed across the controlled restart, HTTP ping returned
`pong`, and three Hosts / three Agents were active. No Docker HEALTHCHECK is
defined; these are HTTP/native readiness observations, not a Docker healthy claim.

All four mounts and nineteen named volumes, `unless-stopped`, AppArmor
`docker-default`, operator origin/performance settings and four existing feature
opt-ins were preserved. Qualified Server582 rollback was retained. Official APT
runtime readback matched nineteen ELF files and the recorded package pair.
Post-restart readback verified the existing volume-free BusyBox `1.37.0` cache on
all three qualified daemons, with zero new image pulls. The separate deployment
and all-host cache receipts passed; the production site was not changed.

These observations establish the isolated cutover/restart/smoke scope only.
Two fresh logical-Volume cases passed native creation, cancellation, current-role /
Key limits and normal cleanup. They establish unallocated records, not physical
storage or mounted-data acceptance. Existing scoped Service results are carried.

A subsequent API-Key-backed typed Load Balancer scale case failed with
`ResourceChangeAuthorizationDenied`: the native `service.update` process ended
`CANCELED` / `AUTHORIZATION_DENIED` before execution. The desired scale had already
been persisted by native PUT. Do not infer zero effects or retry that plan; the
worker incorrectly applies metadata-only attestation to scale, and a permanent
source fix is being qualified. Bounded Container log reads also retain a failed
native output-contract assertion pending diagnosis. The original failures remain
failed even after their owned fixtures and Keys are normally cleaned up.

Other business/native workflows, real weak-model cases and whole-frontend
acceptance remain pending or incomplete; historical FAIL/HOLD results are not
promoted. The acceptance workbook distinguishes these scopes from deployment.

## Security and operator acceptance

The recorded merged-rootfs/active-payload/browser-runtime security gate has zero
effective Critical/High or available-fix findings, not zero vulnerabilities.
Thirteen Medium package occurrences across nine CVEs without an available official
fix remain tracked, with review after `2026-11-12`. Raw scans, package-scoped VEX,
vendor-pending evidence and incomplete browser scan coverage are retained.

Publication, cached-image preparation and isolated deployment do not establish
complete business/native acceptance. Stack Group, remaining storage and Service/Registry,
Container logs, role/Key/audit/UI and real weak-model cases retain their designated
native gates. Historical FAIL/HOLD evidence and unaffected scoped PASS are preserved;
this release is not all 243 frontend groups accepted. KVM and human-only workflows
remain outside these optional tool subsets.

Preserve operator mounts, all named volumes, restart policy, AppArmor, firewall,
origin/performance settings and the four independent default-off feature flags.
Retain qualified Server582 and its complete image/config/database rollback set,
with the existing qualified581 rollback. No new data migration or live bundle swap
is introduced. See [upgrade/rollback](../upgrades/README.md) and
[performance settings](../performance/README.md).
