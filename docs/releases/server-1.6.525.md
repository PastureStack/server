# Server v1.6.525 - API Key actual dispatch binding

This source release packages officially published Engine `v0.183.343` and
unchanged Web Console `1.6.183`. Server525 image publication, deployment and
final-image native acceptance are pending at source preparation. Current
installation examples and the documentation index remain on published Server524.

## Method dispatch and old queued metadata

Engine343 binds authorization to the HTTP operation actually dispatched.
PUT/DELETE and POST-create cannot borrow export/exec/logs grants from ignored
selectors. GET links and registered POST actions retain their actual precedence.
Custom-Key queued work captured by an older server recomputes its stored
method/selectors and rejects a contradictory operation before process execution.
Full/legacy work retains the original live-owner, expiry, revocation and lifecycle
checks. This change adds no external GET/list grant, role or replay feature.

## Immutable released component inputs

Engine source `5aa9d8978c75a7fe63330453c399a92716d88568`, tree `3aad75897d2ec50796a067a71a58ec1a48f729fd`.
The actual released `cattle.jar` is 87871526 bytes, SHA-256
`b29c0057f96dbae38bfe2c663c63bbe4c8b5c755b3090f39414aa51f9813025f`. Local WAR/checksum bytes match the immutable official
assets read anonymously. Canonical Engine publication receipt SHA-256:
`0696bc024a6fc437b594dbbb5f5ff1ce33e53e7d949b65345450171adb77aa24`.

Web183 source `e056a0111d20816742eff17a65dfabb5d003dae2`, archive SHA-256
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.
Other component pins, role/schema hashes, Ubuntu inputs, authentication, broker,
registration, HA and runtime configuration are unchanged by this Server scope.
VEX decisions and vendor-pending exact-set/deadline remain unchanged; only their
numeric release identities advance. Historical mutation controls are retained,
with a new real previous342 package-rejection control.

## Evidence, original publication gates and rollback

The Engine component records 21 focused source tests (12 ingress/lookup and
9 queued cases). They are separate from the new 16 final-image native cases;
those Server525 native cases remain pending until their own receipts establish
outcomes. Prior Server524's 96 native cases apply only to that historical image.
C03 typed all-actions remains HOLD in every row. Neither component publication
nor a source test closes C03, complete role/resource lifecycles or the matrix.

Normal signed source merge and required CodeQL checks, original full source
and packaging gates, build/flatten/config comparison, startup/restart/MFA,
seven entry-only registration checks, merged-rootfs security scans, unchanged
VEX/vendor policy, SBOM, provenance and immutable numeric publication/readback
remain mandatory. Entry-only checks do not establish an active node.
Server525 deployment and native acceptance must be recorded separately.
Preserve all three named volumes, backups, environment and security settings.
Rollback to published Server524 restores its known method/selector and old-queue
classification defect. Follow the API Key rollback guide; do not weaken Key
restrictions or expiry to make a request succeed.
