# Server v1.6.473

This patch assembles Web Console `1.6.138` and Webhook Automation Service
`0.10.2` on the preserved Server `v1.6.460` runtime base and unchanged
Orchestration Engine `v0.183.323`. No database migration, OIDC configuration,
HAProxy change, or production deployment is included.

Web Console delete confirmation now waits for each resource request, prevents
duplicate submits, and keeps failed items available for a bounded retry. The
authenticated route waits for language initialization so denied and missing
resource pages display a translated message in the active locale, including
after a language change. Webhook receiver management requires the trusted
project header to match the requested project, and all receiver operations
exclude unrelated generic-object kinds. Its existing `/v1-webhooks` endpoint,
driver identifiers, and internal `/usr/bin/webhook-service` compatibility
symlink remain intact.

## Immutable component inputs

- Web Console `1.6.138`, commit
  `538795125b0c1815c5e662449146ca670529e2fc`, archive SHA-256
  `e5b2ffb3831fca2562ba3d545e0ff2690cf7b156b70b18c05cf73b10ec6cfa27`.
- Webhook Automation Service `0.10.2`, commit
  `7e8bdcd4b6b9456116a4b2e2c9c40e501b456366`, archive SHA-256
  `fb2e4185b783ca58c171abef84fd5fa3e1451696c526ce25b7330445adcdcce7`,
  executable SHA-256
  `9f0a5f633b7c96e48d5b6a47b7e0bd2520df0731cb906c8e1f0a6308b52ba4ba`.
- Orchestration Engine remains `v0.183.323`; Authentication Service remains
  `v0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

The Server build checks the public release archives, exact contents, hashes,
Web Console version/translations, executable version and source record, and
the webhook compatibility symlink. Its release workflow must additionally
pass isolated boot/restart, merged-rootfs security inventory, source/SBOM
identity, SBOM identity, and image digest readback before publication.

## QA and security boundary

Prior QA on `v1.6.472` proved controlled certificate and registry/credential
resource-ID matrices with cleanup; those results do not establish that all
create, upgrade, edit, delete, same-page buttons, or host-backed paths pass on
this version. Re-run the affected translated denial page and webhook project/
kind authorization against the immutable `v1.6.473` image at QA port 8080.
Keep the evidence matrix explicit about untested rows. This release does not
deploy `stack.ascdc.tw` or alter its HAProxy.

## Upgrade and rollback

After publication, replace only the Server image reference with
`ghcr.io/pasturestack/server:v1.6.473`. Keep the existing Compose environment
variables, named volumes, restart policy, AppArmor, HTTPS origin, OIDC,
performance settings, and firewall backend. Rollback selects the preserved
`v1.6.472` image and the same configuration and volumes; do not overwrite its
tag or digest.
