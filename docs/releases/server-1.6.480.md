# Server v1.6.480 source candidate

This patch assembles Web Console `1.6.145` with the unchanged
Orchestration Engine `v0.183.326` on the preserved Server `v1.6.460` runtime base. All other
component coordinates remain those of Server `v1.6.479`.

Post-release isolated QA of `v1.6.479` found a Registry Add false denial for
superadministrator, owner, member, and restricted roles even though both
`registry` and `registryCredential` scoped schemas offered POST. The schema
cache used a lower-case ID while the create-capability lookup queried a
camel-case ID. Web Console `1.6.145` resolves that mixed-case lookup. The
readonly and no-access denial behavior, Secret and Certificate Add controls,
localized direct-route feedback, and Secret Edit action-link behavior remain
within the existing browser contract. Server authorization, authentication,
API schema, database, and existing resources are unchanged.

The unchanged Orchestration Engine input is commit
`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, with `cattle.jar` SHA-256
`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
The Web Console `1.6.145` merge commit is
`c130a081257b14d1a547ca13c3a16aa0d802d435`. Its independently rebuilt
release archive SHA-256 is
`fa040adff35162fec11e6400180a913af9847db1798c6ead6111f539a4436e39`.

Server publication requires source and final-image gates. Separate isolated
`8080` QA must recheck the six-role Registry Add visibility and direct-route
denial, confirm the two scoped POST capabilities, and verify
zero unintended writes. Prior `v1.6.479` QA remains a failed historical result
for Registry Add, not acceptance evidence for this release. The `v1.6.480`
browser and write matrix has not yet been accepted on `8080`.

## Upgrade and rollback

After release verification, select the immutable numeric tag
`ghcr.io/pasturestack/server:v1.6.480` and its verified digest. Preserve the
existing QA container's environment overrides, named volumes, runtime
contract, and `v1.6.479` rollback container. Do not deploy this release to
`stack.ascdc.tw` as part of the isolated QA upgrade.
