# Server v1.6.490

Server `v1.6.490` packages Web Console `1.6.156` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`. The Web Console
source is main commit `29cda4fd9239e159ff46769cf7db4318c6406d0f`
from [Web Console PR #129](https://github.com/PastureStack/web-console/pull/129).
The official `web-console-1.6.156.tar.gz` release asset's
SHA-256 is `8ddb875fe374c8893bbdde4ee595d3cc9502e24dc30832b866404c12fc2cacd2`.
Web Console main validation run `36614540232` passed. The numeric release tag,
archive identity, and `VERSION.txt=1.6.156` were verified before this Server
image build.

The prior `v1.6.489` isolated browser run found that a fixed permission notice
still covered a page title at 375px and right-side sort controls at 1440px.
Web Console `1.6.156` moves the existing jGrowl container into an in-flow
mount between the navigation and `<main>` on authenticated pages. It returns
the same container to the body when leaving that route, preserving login and
MFA notices. The package and image checks require the `growl-mount` browser
asset marker and static-position CSS in all four theme assets. This is a
layout change; API, Engine, authorization, and request payload contracts are
unchanged.

Web Console source tests and local compiled-CSS checks do not establish a
`v1.6.490` image or packaged browser acceptance. The image requires the
merged-rootfs security gates and first-boot/restart health checks. Packaged
browser checks must verify that permission notices clear the navbar, page
title, and header actions at 280px, 375px, and 1440px in both theme and text
directions, and that login/MFA notices remain visible. The prior six-role
matrix remains separate and must not be claimed complete from these layout
checks.

The Server OpenVEX identity and vendor-pending register advance with this
release. Existing Ubuntu findings remain subject to exact-set image scan and
review; this patch does not claim they are fixed. Retain the previously
deployed immutable image digest with the same volumes and runtime settings
for isolated rollback. Formal `stack.ascdc.tw` deployment is outside this
release rollout.
