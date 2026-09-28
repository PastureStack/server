# Server v1.6.486

Server `v1.6.486` packages released Web Console `1.6.152` on the unchanged
Server `v1.6.460` runtime base and Orchestration Engine `v0.183.326`. The
Web Console tag resolves to merged commit
`dae731085d00f209ad4ee9419acd21d0b6d64f2a`; release asset
`web-console-1.6.152.tar.gz` has SHA-256
`56c147e392d40395690e925e0d8590e44de90bd7d6aaa3e6076ca75f30341486`.
The Server build verifies that asset and `VERSION.txt=1.6.152`. Web Console
main validation run `36446151881` passed its complete source gates and two
production builds on that commit.

The only product behavior change is the required-name error in Stack,
Service, and Container forms: it now uses the same visible translated label
as the input. Isolated Server `v1.6.485` browser QA found four Chinese/Japanese
Stack mismatches. Earlier Service/Container browser cases exercised shared
memory errors but did not submit blank names; those cells remain untested.
There is no API, authorization, request-payload, or runtime component change.

Source and Web Console artifact checks are
not proof of a `v1.6.486` image, browser acceptance, or six-role QA.
Publication requires an immutable Server
build with final merged-rootfs vulnerability/SBOM checks and first-boot/restart
health. Isolated `8080` browser QA must then verify zh-TW, en-US, and ja-JP
Stack/Service/Container blank-name errors at desktop and narrow widths, with
zero writes on invalid submission. Do not infer a complete all-resource ID
write-permission matrix from that localized check.

The reviewed OpenVEX and vendor-pending finding sets are carried forward
with new document identities; this is not a new vulnerability assessment.
Rollback uses the previous immutable Server `v1.6.485` digest with the same
volumes, origin, restart policy, and AppArmor configuration. Production
`stack.ascdc.tw` is outside this isolated QA rollout.
