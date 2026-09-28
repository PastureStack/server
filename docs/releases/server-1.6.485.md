# Server v1.6.485

The Server `v1.6.485` packaging uses the released Web Console `1.6.151` on the
existing Server `v1.6.460` runtime base with Orchestration Engine
`v0.183.326`. The Web Console release tag `1.6.151` resolves to merged source
commit `dfb9b6e799e6b88ae1bf4dd94e71ccc0a8e357ce`. Its published archive
`web-console-1.6.151.tar.gz` has SHA-256
`9cee713690d0f6064bd2490e8cd0a118a7dfb5589d588d50ebb5c443a0eff2b3`;
the Server packaging gate requires `VERSION.txt=1.6.151`. GitHub main
validation run `36416310187` succeeded on that merged commit.

The Web Console source change exposes Secret Edit only when the Secret is
active, its current resource schema allows `PUT`, and it has a self link.
Secret Remove still requires its explicit action. The form payload, server
authorization, and Certificate and RegistryCredential action-link rules are
unchanged. The packaged Server image, browser/API write behavior, and full
role matrix require separate acceptance; the successful source run does not
establish those results.

Compared with Server `v1.6.484`, the source changes
the Web Console archive and Server version identity. The runtime base, other
component pins, and Engine remain unchanged. The reviewed OpenVEX and
vendor-pending finding sets are carried forward with new document identities;
this is not evidence of a new image scan. Publication still requires building
the exact source, scanning the final merged rootfs with pinned Trivy, and
matching unresolved findings against the vendor-pending tracker. New or
changed findings require review before publication.

Run `bash -n` on the changed scripts and
`bash scripts/check-server-api-explorer-patch.sh` (or the aggregate
`bash scripts/check-server-source-gates.sh`). Passing a source gate is
not proof of a `v1.6.485` image, browser acceptance, or six-role QA. Retain
the workflow and QA evidence with the release record.
