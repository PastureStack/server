# Server v1.6.574

## Candidate boundary

This source candidate is not a published Server image or deployment result.
The normal Server workflow must build, scan and qualify the image before use.

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
