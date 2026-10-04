# Server v1.6.513

Source candidate only. Web Console `1.6.175` is a published immutable component;
Server513 has not yet been built, published or deployed. The full functional,
permission, locale and layout matrix remains INCOMPLETE.

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

## Pending Server and acceptance boundaries

Server513 source, publisher run, image/config digest, public assets,
merged-rootfs scan, isolated start/restart and deployed UI evidence are PENDING.
Do not substitute Web publication, Server512 artifact checks, or earlier QA
results for this version's acceptance. No Server513 image digest is asserted.

The existing 51 OpenVEX statements and vendor-pending exact-set/severity/fix
policy retain the `2026-10-20` review deadline. Updating their release identity
does not establish a new artifact scan. Server512's historical raw52/VEX51,
8 Medium package findings / 4 vendor-pending CVEs are not Server513 scan results.
The actual Server513 scan remains required; do not claim zero CVEs.

Quick Start keeps the published Server512 immutable image
`ghcr.io/pasturestack/server:v1.6.512@sha256:805078de83c0320c751dff90304bd841b8e64bec720079198258d22fa41d0145`.
Keep [Server512](server-1.6.512.md) and earlier release/QA receipts unchanged.
Historical HOLDs are not promoted; component publication does not complete the
native resource/role/locale/layout matrix or authorize company deployment.

## Upgrade and rollback

After Server513's own publication/readback gates pass, change only the image
reference in the existing configuration. Preserve environment overrides,
named volumes, restart policy, AppArmor and HTTPS origin. Back up persistent
data first; verify HTTP200/pong, displayed Web version and relevant native UI
after first start and a restart. Until that evidence exists, retain Server512
as the current published Quick Start and rollback reference. Never delete
persistent volumes as part of this Web-only upgrade.
