# Server v1.6.574

Published image: `ghcr.io/pasturestack/server:v1.6.574@sha256:c0c7348ad2cfa372ca8fb65cc409b6bd97dc301fa576350e03535ec40cae6651`.

Image source: `1cf5e90ff06c3e37e5babcf2ad6c5753fd55a910`; tested tree
`024e712709534a99d0b9682045ffbdf5a65fa218`.

The original official workflow passed build, security, startup/restart, image push
and OCI attestation checks, then failed at release-note rendering. Fixed official
completion [42149039216](https://github.com/PastureStack/server/actions/runs/42149039216)
published the original evidence and image without rebuilding. Independent public
readback verified the immutable Release, all 35 asset sizes/SHA256 values and both
native OCI attestations. The original failed run remains recorded in the
[publication contract](../../COMPATIBILITY.md#server-v16574-publication).

Designated deployment/restart, exact storage/cache readback and native business
acceptance on this cohort remain pending. Component tests and workflow startup
checks are not whole-workflow acceptance.

## Verified component inputs

Packages the original published Orchestration Engine v0.183.375 and Web Console
1.6.215 with Bridge 0.2.17. Compose CLI v0.14.43 and Catalog Service v0.20.17
remain unchanged from Server573.

Project metadata processing preserves fresh owner and API Key authorization
while its exact captured native update is in the updating-active transition.
A failed native update records a terminal failure; persisted field values alone
do not establish successful completion. New changes still require an active
Project, and inactive, removed and foreign targets retain their checks.

Service upgrade continuation uses the existing typed preview, human approval,
apply and operation observation flow. Native state, role and API Key scope
remain authoritative; this does not expose arbitrary HTTP or raw payloads.

Original component CI and signed release evidence are component source and
artifact qualifications. They do not establish Project, LB, Process, Catalog,
weak-model or whole frontend workflow acceptance on this Server cohort.

Existing feature opt-ins, networking and storage defaults, official APT pins,
tracking policy for 13 runtime Medium findings, severity gates and archive verification
remain unchanged. Preserve Server573 as the immediate rollback and reuse the
original mounts and operator configuration when upgrading.
