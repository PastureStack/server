# Server v1.6.526

This immutable published release packages Engine `v0.183.344` and unchanged
Web Console `1.6.183`. Installation examples use the published numeric
`ghcr.io/pasturestack/server:v1.6.526` tag.

The published producer is `dd95830037925ad00ecb98021aa8c8f2de8feb04`.
The linux/amd64 image has one runtime layer. Its actual registry manifest is
`ghcr.io/pasturestack/server:v1.6.526@sha256:2c724739d37d4bef2c5f1013f334f3109ef8279dcbe390ff0ed68e4e2ff18379`;
the distinct OCI configuration digest is
`sha256:e92382b15773dcb4335ef01c5bb9634d4716ee8eeefcc99c267f4f0875ca2944`.
Original publication workflow `38335880534` completed successfully; immutable
release and registry readback were verified. Canonical publication receipt
SHA-256: `a89a4816138e5692b1a0dc138ddfb372330e1fca5ab5358eb3ab5458d657a72d`.

## Operation-specific linked operand lookup

Engine344 addresses the generic operand pre-read that prevented an export-only
Key from invoking an otherwise authorized named compose link or registered
export action. The operand lookup remains bound to the actual operation and live
owner authority; it does not grant ordinary GET/list, broaden scope or weaken
deny precedence or expiry.
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

The Engine's 28 focused source tests and Server's 33 packaging cases passed.
The normal signed merge/required CodeQL and original publication gates passed:
full source checks, build/flatten/config comparison, startup/restart/MFA, seven
entry-only registration checks, merged-rootfs security, unchanged VEX/vendor
policy, SBOM, provenance and immutable numeric publication/readback.

Twenty-two targeted native cases passed across v1 and v2-beta in an isolated
owned fixture, using one owner account, two Stacks and twenty single-use Basic
Keys. Normal and export-only compose ZIP reads succeeded; registered
POST exportconfig returned compose JSON and recorded the export operation.
Ordinary GET with an export-only Key and decorated PUT/DELETE without mutation
grants were denied. Update-only mutation and full/legacy GET/PUT controls passed.
Audit pairs, unchanged protected resources and exact fixture cleanup were
verified. This is scoped operation evidence, not complete role/action/resource
coverage or a whole-matrix result.
Native acceptance receipt SHA-256:
`bf6633a94b7a302fd2ce765978a6363fb646b4f970c51a448ae3770ed1df5ec3`.

The isolated QA upgrade from published Server524 to this exact Server526 image
and one restart passed health checks. Resource counts, runtime overrides,
AppArmor and all three named volumes were preserved; the SQL backup and
Server524 rollback were retained. Deployment receipt SHA-256:
`3a1436516d40623844ddb10c34e46c647c43ed3dd7d79064b12deec85a39fb6c`.
Entry checks do not establish an active node. Preserve all three named volumes,
backups and runtime/security settings.
Rollback to published Server525 restores the known export-only compose operand
pre-read limitation. Follow the API Key rollback guide; do not add a read grant
or weaken Key restrictions merely to make the operation succeed.
