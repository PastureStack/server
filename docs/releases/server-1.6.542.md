# Server v1.6.542

Server `v1.6.542` updates only the Engine component to `v0.183.352`.
This document describes the assembly and component provenance. Source changes
alone are not Server publication or deployment proof; use the official
release's `published.txt`, checksums, scan reports, SBOM and actual image digest.
It does not establish complete native-matrix acceptance.

## Project permission-check boundary

Custom API Key project-scope and ancestry checks use the same live membership
and inactive-project authority decision without populating request-local
capabilities or object-access grants. Previously, that check could add project
action metadata while filtering account responses. Normal Project resource
access retains its existing owner/set-members capabilities and grants.

This corrects an authorization-check side effect, not a demonstrated
unauthorized write. Full and legacy Keys gain no new operation, scope or
read-grant restriction. Existing expiry, revision, explicit-deny, owner,
queued-process and write-completion checks remain. No API schema or database
migration is introduced.

## Official Engine bytes

The assembly consumes the original tested bytes from the immutable
[Engine v0.183.352 release](https://github.com/PastureStack/orchestration-engine/releases/tag/v0.183.352);
Server does not rebuild the component.

| Input | Exact identity |
| --- | --- |
| Actual WAR producer | `70ba8cff544fcd5607f3054d30ac8b5cf09783d6` |
| Verified integration main | `109f2623f00ca3a3a9079414a0f0f8bd23cd1eb2` (whole tree equal) |
| Source tree | `1470942b42971f9e82853bf88ed51179faa39745` |
| Required Security CI | run `39702499820`; 3,362 tests, zero failures/errors, one skipped |
| `cattle.jar` | 87,923,198 bytes |
| JAR SHA256 | `1f17603554f1ee3fb651c6570690cb2d7b8c2fa27de17ae260d0cc68b402d826` |
| Formal anonymous-readback receipt SHA256 | `7f58365219b142306ecd423e4a40c8d455138dab98e9e347e679ec49ba98c7ed` |

Both official Engine release assets passed anonymous readback and the release
is immutable, without bypassing required checks. The actual WAR's nested
`cattle-resources-0.183.352.jar` retains the exact existing frozen v1 readonly
and restricted schema bytes; their SHA256 pins remain unchanged. These are
component evidence, not a substitute for Server final-image qualification.

## Unchanged assembly and acceptance boundaries

Web Console `1.6.192`, Host API `0.38.6`, Linux/Windows Node Agent `0.13.30`,
Windows CNI `0.2.5`, CLI `0.6.19`, LB `0.9.32`, API Explorer `1.1.19`,
Temurin `25.0.4.1+1` and every other 541 component source/archive/binary pin
are unchanged. The four nested Go payload qualifications and exact release
asset envelope remain required. Existing Compose, public-origin, three-volume,
runtime-override, LB database-override and rollback contracts are preserved.

Only current release identities in VEX and vendor tracking move to 542;
statements, package findings, policy and security thresholds are unchanged.
Final scans and SBOMs must be generated from the actual new Server image,
not copied from 541.

Custom24/OIDC, audit sink/flush and active-stream checks remain separate bounded
acceptance work. No whole-row, whole-matrix, UI or Windows-native networking
PASS is implied by this assembly. Installation examples follow the latest
documented published numeric Server tag and are updated only with publication
evidence.

Back up and preserve the database and all three persistent volumes. Retain the
previous official Server image for rollback; do not restore stale Key policies,
patch deployed binaries, weaken MFA or alter unrelated runtime settings to
apply this update.
