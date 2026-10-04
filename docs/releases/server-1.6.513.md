# Server v1.6.513

Published immutable Server artifact with Web Console `1.6.175`; its own official
runtime/security/public readback passed. Server513 is not yet deployed to QA,
which remains on 512. The full functional, permission, locale and layout matrix
remains INCOMPLETE; no native UI or VM-boot acceptance is claimed.

## Scope

Package the Web175 repair for a stale required-image message in the parent
container/VM form after image correction or locale change. The form refreshes
only the validation aggregate it still owns. Non-image model/command errors
and a later backend save error remain intact, even when texts match.
No shared NewOrEdit change, new save hook, wire-format, schema, permission
or authentication change is introduced. Four new real-component regressions
passed in the formal suite; component tests are not deployed UI acceptance.

Orchestration Engine remains official `v0.183.333`, source
`0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
`8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
Reuse the Server460 base
`ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403`,
four existing build stages and final single-runtime-layer flatten/config checks.
Other component/package pins, environment, persistent volumes, AppArmor,
OIDC/MFA and runtime policy are unchanged.
No migration or runtime patch is required.

## Actual published Web component

- Signed source: `bb905d092700c262497b88f5773e7714fc1f4be4`.
- Tested/published tree: `b2b38347e5fa24bd945706fd2aaab0136ea4ef45`.
- [Formal CI37163340764](https://github.com/PastureStack/web-console/actions/runs/37163340764):
  821/821 passed, zero failures, skips or todo; two production archives identical.
- [Signed immutable numeric tag 1.6.175](https://github.com/PastureStack/web-console/releases/tag/1.6.175):
  `web-console-1.6.175.tar.gz`, 2982158 bytes, SHA256
  `9833467b2be47d4fa01f09954fcd35beb292c59d382d5c1aecd76d17c6a387a2`.
  Anonymous archive/checksum downloads match the formal CI bytes.
- Formal receipt SHA256:
  `d128ad4b553a28556cb252debe58a0ba15657267da9b19e5221f25d8b6b4328f`.
- Publication receipt SHA256:
  `a177e4d2a20bff51b18c8f233e87672a3f343ff5a1df12edcc57771ae41ba125`.
- Web build audit remains `PASS_BUILD_VENDOR_PENDING`; it is not a zero-risk claim.

## Actual published Server and remaining acceptance boundaries

- Source: `eefc84d670188f8d81978d6ce600d1c0400fe720`.
- [Official publisher37164995463](https://github.com/PastureStack/server/actions/runs/37164995463):
  success, source-bound single final runtime layer and flatten/config checks.
- [Immutable numeric release v1.6.513](https://github.com/PastureStack/server/releases/tag/v1.6.513):
  23 assets including the checksum manifest, 22 SHA-256 entries; all local hashes
  and GitHub asset digests match. Anonymous GHCR manifest/config and SBOM identity
  match the image/source/version, linux/amd64 and digest-pinned 460 base.
- Image: `ghcr.io/pasturestack/server:v1.6.513@sha256:d6df82fe1ec29d720af47fe62ec83dcf0f96ce1b0dcfc00059363f8621dc61ab`.
- Config digest: `sha256:c219a757a09fad676f9f95c235b2b8e64551f7f011d2fae2d267752cba6bd054`.
- Isolated first start13/restart7 attempts reached HTTP200/pong; 34 MFA/API checks,
  TLS1.2/TLS1.3 HTTP200, untrusted TLS rejection and private API `no-store` passed.
  These official artifact gates are not QA deployment or native UI acceptance.
- Independent readback receipt SHA256:
  `0ddeb6b6fe1b5a846fd6e7f803da61a8caa7865496a2751fc9f33cd73bfc9e96`.
  Local release workspace evidence, not a public Release asset:
  `.release-evidence/server-v513-published-readonly/readback/server513-release-37164995463/readback-receipt.json`.

The actual Server513 merged-rootfs scan has 52 raw findings and 51 OpenVEX
statements. Raw/unresolved JSON and TSV, PURLs, VEX and vendor exact sets match;
8 Medium vendor-pending package findings / 4 CVEs remain. Untracked,
Critical/High, available-fix and secret findings are 0. Existing severity/fix
policy and the `2026-10-20` review deadline remain unchanged; do not claim zero CVEs.

Quick Start now pins the published Server513 immutable image above. QA remains
on 512; Server513 deployment/native UI evidence is pending. Do not substitute
Web publication, official runtime gates or earlier QA results for it.
Keep [Server512](server-1.6.512.md) and earlier release/QA receipts unchanged.
Historical HOLDs are not promoted; artifact publication does not complete the
native resource/role/locale/layout matrix or authorize company deployment.

## Upgrade and rollback

When deploying the published Server513 image, change only the image reference
in the existing configuration. Preserve environment overrides,
named volumes, restart policy, AppArmor and HTTPS origin. Back up persistent
data first; verify HTTP200/pong, displayed Web version and relevant native UI
after first start and a restart. Until that deployment evidence exists,
retain the current QA512 runtime and rollback reference. Never delete
persistent volumes as part of this Web-only upgrade.
