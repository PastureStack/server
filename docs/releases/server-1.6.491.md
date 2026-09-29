# Server v1.6.491

This candidate prepares to package Web Console `1.6.157` on the unchanged
Server `v1.6.460` runtime base and Orchestration Engine `v0.183.326`.
The Web Console source is merged main commit
`3f2760da44d25fcc277a627e843fb0c088972ec6` from
[Web Console PR #131](https://github.com/PastureStack/web-console/pull/131).
The Web Console main CI `web-console-1.6.157.tar.gz` artifact SHA-256 is
`ba1724c8a2e3d204c6f1527c7880cd361f3e307863133a1d1ba45120fce53a3f`.
Web Console main validation run `36622118528` passed. The archive checksum
and `VERSION.txt=1.6.157` were verified before this Server source preparation.
The published Web Console release asset must match this checksum before the
Server image build.

The prior `v1.6.490` image packages Web Console `1.6.156`. In isolated 8080
browser QA, a readonly user's fresh direct visit to `/apps/stacks/add` showed
the permission denial but left the notice fixed under `BODY`, overlapping
right-side header actions at 1440px. An in-app route transition moved the
notice into the page flow. Web Console `1.6.157` renders a `growl-mount`
component in the authenticated template and moves the existing jGrowl
container when the component enters the DOM. On teardown it returns the
container to `BODY` only while the component owns it. Login and MFA notices
therefore retain their existing body host. Permission checks, API
authorization, notice copy, and request payloads are unchanged.

The Web Console focused source tests passed 7/7 Chrome QUnit cases for notice
placement, component insertion and teardown, delete notices, and layout.
Those source tests and this Server source preparation do not establish a
`v1.6.491` image or packaged browser acceptance. The Server release gate must
verify the official archive, its compiled UI, the merged-rootfs security
scan, and first-boot/restart health. Fresh direct-URL browser QA on the
packaged image must confirm that the readonly denial clears the header
actions at 1440px and remains in flow at 375px and 280px in both themes and
directions; login and MFA notices must remain visible. The broader six-role
permission matrix remains a separate acceptance check.

The Server OpenVEX identity and vendor-pending register advance to this
release. Existing Ubuntu findings remain subject to the exact-set image scan
and review. Retain the previously deployed immutable image digest with the
same volumes and runtime settings for isolated rollback. Formal
`stack.ascdc.tw` deployment is outside this release preparation.
