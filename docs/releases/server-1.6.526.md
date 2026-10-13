# Server v1.6.526

This source release packages officially published Engine `v0.183.344` and
unchanged Web Console `1.6.183`. Server526 image publication, deployment and
native qualification remain pending at source preparation. Installation examples
must continue to identify an actually published image until official readback.

## Operation-specific linked operand lookup

Engine344 addresses the generic operand pre-read that prevented an export-only
Key from invoking an otherwise authorized GET compose operation. The operand
lookup remains bound to the actual operation and live owner authority; it does
not grant external ordinary GET/list, broaden Key scope or weaken deny/expiry.
Engine343's HTTP dispatch binding and old queued metadata checks are retained.
Full/legacy, owner, revocation and lifecycle boundaries remain authoritative.

## Immutable component inputs

Engine source `72c42e6f2000301fe03ffd2442fb9ee89aee120c`, tree `9d61004949e7e6befc0a8c046dcc199258e6e887`.
Actual released `cattle.jar`: 87873505 bytes, SHA-256
`ffafa4700156b74ec11bcae1b830738e49943f1a3b8b0565895ed6d7726eebf1`. Local WAR/checksum bytes match the immutable official
assets read anonymously. Engine build receipt SHA-256:
`cb414ba0290627f3a216cfd81d437eb069c3e058a9859e704268042b17975665`; immutable release receipt SHA-256:
`4947a2a01255627067e5ce158e7474f5a8345482563dc140fed283e31e26898b`.
Web183 source `e056a0111d20816742eff17a65dfabb5d003dae2`, archive SHA-256
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.
All other component pins, role/schema hashes, Ubuntu inputs, authentication,
broker, registration, HA and runtime configuration remain unchanged.
VEX/vendor decisions, exact-set and deadlines are unchanged apart from numeric
release identity. Historical mutation controls remain, with previous343 rejection.

## Qualification and rollback

Component source tests, official WAR publication, Server source/packaging gates,
final-image native acceptance and deployment have separate evidence boundaries.
No new native PASS, complete role/action/resource coverage or target image digest
is inferred from this source preparation or prior-version evidence.
Original signed normal merge/required CodeQL, full source/packaging gates,
build/flatten/config comparison, startup/restart/MFA, seven entry-only
registration checks, merged-rootfs security, unchanged VEX/vendor policy, SBOM,
provenance and immutable numeric publication/readback remain mandatory.
Entry checks do not establish an active node; unresolved action coverage remains
pending. Preserve all three named volumes, backups and runtime/security settings.
Rollback to published Server525 restores the known export-only compose operand
pre-read limitation. Follow the API Key rollback guide; do not add a read grant
or weaken Key restrictions merely to make the operation succeed.
