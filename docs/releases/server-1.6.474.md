# Server v1.6.474

This patch assembles Web Console `1.6.139` and Webhook Automation Service
`0.10.3` on the preserved Server `v1.6.460` runtime base and unchanged
Orchestration Engine `v0.183.323`. It includes no database migration, OIDC
configuration change, HAProxy change, or production deployment.

Web Console uses the authenticated project's API capabilities for Container,
project API-key, and Receiver Hook write controls. Direct Container and Receiver
Hook routes reject unavailable writes with localized messages. Account-key
creation remains available when the account API permits it. The Container edit
modal waits for primary, port, and link saves; a failed port or link update
restores the original local field, leaves the modal open, and does not repeat a
successful peer update on retry. The separate API writes are not a transaction.

Webhook Automation Service returns role-specific Receiver write methods from
both `/v1-webhooks/schemas` and `/v1-webhooks/schemas/receiver`. Those schema
responses are private and non-cacheable. Receiver data, credentials, routes,
project isolation, and the internal `/usr/bin/webhook-service` compatibility
symlink remain unchanged.

## Immutable component inputs

- Web Console `1.6.139`, commit
  `7683aa5095b5b6608dafea1b1f49f8d35dec20dc`, archive SHA-256
  `18d21b29e7da7695cda6c4bd4091d0afc1aea960f568b0043f0c5d6403873634`.
- Webhook Automation Service `0.10.3`, commit
  `fbcc0ca07e42e9b21bda18031d0848192ec2f9a1`, archive SHA-256
  `6babbc18cee9a192009cfadcd143e6b9a5f2b550c4dc419781f3e3657caa022a`,
  executable SHA-256
  `9094f3b2527762a3e683b02d93aa00e52618e902cd409e72e34553d98d98a609`.
- Orchestration Engine remains `v0.183.323`; Authentication Service remains
  `v0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

The build verifies release archive hashes and contents, component versions,
source records, and the webhook compatibility symlink. Publication also
requires the isolated boot/restart gate, merged-rootfs security inventory,
source and SBOM identity checks, and image digest readback. The image pipeline
does not establish role-by-role behavior on the existing QA service.

## QA and deployment boundary

Run the affected Container, project API-key, Receiver Hook, and Container edit
write-flow matrix against the immutable `v1.6.474` image in isolated QA. Check
owner/member write access and restricted/read-only denial, localized direct
route errors, Receiver schema cache boundaries, and partial edit retries. Keep
untested rows explicit. This release does not deploy `stack.ascdc.tw` or alter
its HAProxy.

## Upgrade and rollback

After publication, replace only the Server image reference with
`ghcr.io/pasturestack/server:v1.6.474`. Keep the existing Compose environment
variables, named volumes, restart policy, AppArmor, HTTPS origin, OIDC,
performance settings, and firewall backend. Rollback selects the preserved
`v1.6.473` image with the same configuration and volumes; do not overwrite its
tag or digest.
