# Server v1.6.492 candidate

This candidate prepares to package Web Console `1.6.158` on the unchanged
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
failures, HTTP 405 responses, and three-language copy. These tests and this
Server source preparation do not establish a `v1.6.492` image or packaged
browser acceptance. After the official archive is published and pinned, the
Server release gate must verify its checksum and compiled UI, merged-rootfs
security scan, and first-boot/restart health. Packaged browser QA must verify
the Service direct-ID and Secrets load messages, HTTP 405 action feedback,
and the prior role and locale boundaries.

The Server OpenVEX identity and vendor-pending register advance to this
candidate. Existing Ubuntu findings remain subject to the exact-set image
scan and review. Retain the previously deployed immutable image digest with
the same volumes and runtime settings for isolated rollback. Formal
`stack.ascdc.tw` deployment is outside this candidate preparation.
