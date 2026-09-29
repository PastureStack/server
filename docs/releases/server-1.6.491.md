# Server v1.6.491

This release packages Web Console `1.6.157` on the unchanged
Server `v1.6.460` runtime base and Orchestration Engine `v0.183.326`.
The Web Console source is merged main commit
`3f2760da44d25fcc277a627e843fb0c088972ec6` from
[Web Console PR #131](https://github.com/PastureStack/web-console/pull/131).
The Web Console main CI `web-console-1.6.157.tar.gz` artifact SHA-256 is
`ba1724c8a2e3d204c6f1527c7880cd361f3e307863133a1d1ba45120fce53a3f`.
Web Console main validation run `36622118528` passed. The archive checksum
and `VERSION.txt=1.6.157` were verified before this Server source preparation.
The published Web Console release asset was read back with the same SHA-256.

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
The official [Server release assets](https://github.com/PastureStack/server/releases/tag/v1.6.491)
include `published.txt`, `image-inspect.txt`,
`candidate-smoke.txt`, the merged-rootfs `security-summary.txt`, and the image
SBOM `server.cdx.json` and OpenVEX `server.openvex.json`. `published.txt` and
`image-inspect.txt` identify the published
image as
`ghcr.io/pasturestack/server:v1.6.491@sha256:c484d298e5bde93b51b44acd476a725bbaa471959d1079d19331c01bc55f8705`.
The candidate smoke reports first-boot and restart health; the security
summary reports `SERVER_SECURITY_GATE_OK` with eight vendor-pending findings.

Post-release isolated 8080 QA identified that image and Web Console `1.6.157`.
It passed 14 scoped cases: 12 readonly Stack and Service direct-create denials
across Traditional Chinese, English, and Japanese at 1440x900 and 375x812,
and two owner checks that the create forms open at 1440x900. Two additional
fresh direct-URL checks for readonly
passed at 1440x900. The record reports zero resource writes, so the owner
checks do not establish successful creation. Packaged behavior at 280px, both
themes and directions, login/MFA notice behavior, and the broader six-role
resource matrix remain outside this QA result.

The Server OpenVEX identity and vendor-pending register advance to this
release. Retain the previously deployed immutable image digest with the same
volumes and runtime settings for isolated rollback. This release and isolated
QA do not establish deployment to the formal `stack.ascdc.tw` site.
