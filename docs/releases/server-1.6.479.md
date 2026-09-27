# Server v1.6.479

This patch assembles Web Console `1.6.144` with the unchanged Orchestration Engine `v0.183.326`
on the preserved Server `v1.6.460` runtime base. All other
component coordinates remain those of Server `v1.6.478`.

The unchanged Orchestration Engine input is commit
`66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, with `cattle.jar` SHA-256
`6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.

Secret, Certificate, and Registry Add controls now follow the current
environment's create capability. Direct Add routes reject unauthorized entry
with localized, human-readable 403 feedback before creating form records;
Registry creation requires both registry and registryCredential POST.
Secret Edit now follows its update action link instead of appearing
unconditionally.
Existing Secret Remove and Certificate/Registry Edit/Remove action-link checks
are unchanged.

These are browser controls and route feedback. This release does not change
Server authorization, authentication, API schema, database, or existing
resources. The Web Console `1.6.144` source is
`e76706a13e24ebe6581719e8c5407f7a7b998bdc`; its independently rebuilt,
immutable release archive is SHA-256
`906876dbac44d8644bd0481dc3d0eab19dd4098d930b20919bcd52b0bb607d91`.

Server publication requires the source and final-image gates. Separate
isolated `8080` QA must verify the affected six-role Secret, Certificate,
and Registry Add visibility and direct-route denial, Secret Edit action
visibility, English/Traditional Chinese feedback, and zero unintended writes.
The prior `v1.6.478` API direct-ID matrix remains historical evidence; it is
not a substitute for `v1.6.479` browser acceptance.

## Post-release isolated QA finding

Registry Add failed its UI check for the superadministrator, owner, member, and
restricted roles even though the scoped `registry` and `registryCredential`
schemas both offered POST. Readonly and no-access denial checks passed, as did
the Secret and Certificate checks in English and Traditional Chinese. The
schema cache used a lower-case ID; capability lookup returned false for the
camel-case form and true for the lower-case form. This was not a loading race,
and the failed Registry flow caused no resource writes. Web Console `1.6.145`
addresses this false denial; `v1.6.479` must not be marked as passing the full
Registry Add browser matrix.

## Upgrade and rollback

After release verification, select the immutable numeric tag
`ghcr.io/pasturestack/server:v1.6.479` and its verified digest. Preserve the
existing QA container's environment overrides, named volumes, runtime
contract, and `v1.6.478` rollback container. Do not deploy this release to
`stack.ascdc.tw` as part of the isolated QA upgrade.
