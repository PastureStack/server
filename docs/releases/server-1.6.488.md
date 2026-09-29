# Server v1.6.488

Server `v1.6.488` packages Web Console `1.6.154` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`. The Web Console
source is main commit `f381a9fb29b54c1b7c18e453c001a93ff1d6a531`.
The official `web-console-1.6.154.tar.gz` release asset has SHA-256
`c36a8e2cb06f62439359c9b05ad7eb7d76405f54de7800db4c3fea7cde77440e`.
The Server build verifies that archive and `VERSION.txt=1.6.154`. Web Console
main validation run `36598826825` passed and produced two bit-identical
release candidates; the published release tag and asset match this source
commit and digest.

When a read-only user opens a Stack or Service create route directly and the
effective schema does not allow creation, the page shows the existing growl
style with a localized permission notice before returning to Stacks. An
upgrade still checks update permission and uses a distinct update notice.
English, Traditional Chinese, and Japanese have their own messages; the
remaining locales use English fallback text. This package changes no API,
Engine, or request-payload contract.

The previous isolated `v1.6.487` six-role API matrix recorded 136 passes and
20 read-only schema N/A cases. It did not cover every same-page submission or
direct resource-ID action. This source and Web Console asset are
not proof of a `v1.6.488` image, browser acceptance, or complete six-role QA. A new image
still requires merged-rootfs security gates, first-boot/restart health, and
packaged browser checks for the permission notice and redirect.

The Server OpenVEX identity and vendor-pending register advance with this
release. Existing Ubuntu findings remain registered for exact-set image scan
and review; this patch does not claim they are fixed. Retain the previous
immutable `v1.6.487` image digest with the same volumes and runtime settings
for isolated rollback. Formal `stack.ascdc.tw` deployment is outside this
release rollout.
