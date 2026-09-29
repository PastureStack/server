# Server v1.6.492

This release packages Web Console `1.6.158` on the unchanged
Server `v1.6.460` runtime base and Orchestration Engine `v0.183.326`.
The Web Console source is merged main commit
`4c99e4803d594a6bc7c340aefc686d34e4ea0f87` from
[Web Console PR #133](https://github.com/PastureStack/web-console/pull/133).
Web Console main validation run `36634695941` passed. The official
`web-console-1.6.158.tar.gz` archive SHA-256 is
`286833d3313c5bc04469a8fafd41bab7de1c4b60527f91aae9eef8a4016b17f6`. The published release asset and its
checksum sidecar were read back with that same SHA-256.
The downloaded archive checksum and `VERSION.txt=1.6.158` were verified.

The prior `v1.6.491` image packages Web Console `1.6.157`. API acceptance
observed inaccessible Secret IDs returning HTTP 403, readonly Secret PUT and
DELETE without schema methods returning HTTP 405, and scoped Service direct-ID
denials. Web Console `1.6.158` maps Service direct-ID and Secrets collection
load failures through the existing resource-safe error handling: HTTP 403 and
404 share an unavailable message, and HTTP 5xx receives a server-failure
message. HTTP 405 save and action failures use existing localized unavailable
messages. New load copy is supplied in English, Traditional Chinese, and
Japanese, with English fallback for other locales. Authorization and request
payload contracts are unchanged.

Focused Web Console source tests passed 7/7 Chrome QUnit cases for the route
failures, HTTP 405 responses, and three-language copy. The
[Server release](https://github.com/PastureStack/server/releases/tag/v1.6.492)
points to source commit `946584c41db72bcc247617af83c878210933610f`.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.492@sha256:a50d7859aebb7d08b62a237e42e1323b3da3b9cef51ab8028d4c730d2dd87a03`.
Official workflow `36637509103` verified the Web archive checksum and
compiled UI, merged-rootfs security gate, candidate first boot/restart and
private API cache policy. Its candidate smoke returned HTTP 200 `pong` after
both starts. Isolated 8080 deployment then reported `QA_DEPLOY_OK` for that
exact digest, source revision, Web Console version and single-layer image;
it retained v1.6.491 as the rollback container. Packaged browser and broader
role/resource acceptance are separate and must not be inferred from these
image and deployment gates.

The Server OpenVEX identity and vendor-pending register advance to this
release. The merged-rootfs scan reported zero untracked findings, zero
Critical/High findings and zero fixed-available findings; eight exact-set
vendor-pending findings remain, rather than being suppressed as fixed. Retain
the previously deployed immutable image digest with the same volumes and
runtime settings for isolated rollback. Formal `stack.ascdc.tw` deployment
was not performed.
