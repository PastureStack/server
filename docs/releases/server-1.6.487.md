# Server v1.6.487

Server `v1.6.487` packages Web Console `1.6.153` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`. The Web
Console source is the signed main commit
`2c1ac7b112cd82d4335d320880822b2a4a9b1ae8`. Its immutable
`web-console-1.6.153.tar.gz` SHA-256 is pinned in the Server build; the build
verifies `21a4a3ddfe7e79cb3b7189d8ce8854271470a50193d6ab30a2124dd17f72c910`
and `VERSION.txt=1.6.153`. Web Console main validation run `36532426851`
passed all 712 tests and produced two identical release candidates. CodeQL
run `36532407773` passed on the same signed main commit.

This patch tightens Stack, Service, Container, Catalog, and adjacent UI write
controls against the currently selected project, effective API schema, and
resource action link. Queued project upgrades, delayed Service scale writes,
and Catalog save navigation remain bound to their originating project. A
denied or missing resource has localized, non-identifying feedback. Registry
edit recovery and Japanese wording were checked in their forms. Container and
Host charts stop loading when a stats link is absent; authorization and
not-found responses are not retried, while transient failures may retry with
a fresh socket. The Engine, API permission rules, stored payloads, and other
runtime components are unchanged.

The isolated Server `v1.6.486` QA established six-role read-only page
discovery, selected cross-project ID denials, and bounded real Stack/Service/
Container writes and cancel/save/remove flows. It did not establish every
same-page submission or every direct resource-ID operation. A new Server
image must still pass first-boot/restart health, merged-rootfs security gates,
and packaged browser checks. Source checks and the Web Console asset are
not proof of a `v1.6.487` image, browser acceptance, or six-role QA.

The Server OpenVEX identity and vendor-pending register advance with this
release. Ubuntu findings without an upstream fix remain registered for review
and subject to the exact-set image scan; this patch does not claim they are
fixed. Use the previous immutable `v1.6.486` digest as the isolated 8080
rollback image with the same named volumes and runtime settings. The formal
`stack.ascdc.tw` deployment is outside this release rollout.
