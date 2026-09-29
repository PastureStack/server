# Server v1.6.489

Server `v1.6.489` packages Web Console `1.6.155` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`. The Web Console
source is main/tag commit `20ed369c6f9600fc063b6ff8f3587de70ae838ff`.
The official `web-console-1.6.155.tar.gz` release asset has SHA-256
`fb4591618bfd782dc05932b401296c40d91785a2c7eb20218d29086850500d8f`.
The Server build verifies that archive and `VERSION.txt=1.6.155`, then checks
all four theme CSS assets after extraction and in the assembled image. Web
Console main validation run `36605681674` passed 713 Chrome tests and produced
two byte-identical release candidates; the published tag and archive match
this source commit and digest.

The Web Console notification is offset below the 45px navbar, and its close
control is bounded to `calc(100vw - 20px)` so it stays usable on narrow
viewports. The preceding Stack and Service route permission notices from
`v1.6.488` remain in place. This package changes no API, Engine, or request
payload contract.

Web Console PR #128 CI passed. That source and asset evidence is not proof of
a `v1.6.489` image, packaged browser acceptance, or complete six-role QA.
The image acceptance criteria are merged-rootfs security gates,
first-boot/restart health, and packaged browser checks for notification
placement and narrow viewport behavior. The previous isolated role matrix
need not be rerun for this CSS change unless those checks reveal a permission
regression. The Server release record carries the resulting image identity
and acceptance evidence.

Post-release isolated QA 8080 checked the packaged `v1.6.489` image. The
notice cleared the navbar and the direct-create permission cases passed, but
screenshots showed it still covered the 375px page title and the 1440px sort
controls. Therefore the notification layout was not accepted; Web Console
`1.6.156` and Server `v1.6.490` address this shared placement defect.

The Server OpenVEX identity and vendor-pending register advance with this
release. Existing Ubuntu findings remain registered for exact-set image scan
and review; this patch does not claim they are fixed. Retain the previous
immutable `v1.6.488` image digest with the same volumes and runtime settings
for isolated rollback. Formal `stack.ascdc.tw` deployment is outside this
release rollout.
