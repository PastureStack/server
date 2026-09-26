# Server v1.6.470

This patch assembles Web Console `1.6.133` with the unchanged
Orchestration Engine `v0.183.322` on the preserved digest-pinned `v1.6.460`
runtime base.
Host creation and cloning now use the active project's effective host POST
schema. A direct Add Host URL without create permission shows a 403 before
registration data loads. Responses from an earlier project selection cannot
restore stale create controls. Project details wait for the selected project
before reading its network and policy. Host access errors are localized in all
13 console locales and fit narrow and right-to-left layouts.

No backend API, authentication policy, database schema, HAProxy, or production
deployment changes are included.

## Verification boundary

Web Console's 563 browser tests and production build passed locally. Release
acceptance also requires the pinned asset checksum, Server source gates, an
immutable image build and security scan, QA 8080 startup/restart, and scoped
host-permission checks before publication. The permission matrix records tested
paths and gaps; it does not establish every API endpoint's authorization.
Production `stack.ascdc.tw` is not changed by this source patch.

## Upgrade and rollback

After publication, update only the Server image reference from `v1.6.469`.
Preserve existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.469` image with the same
configuration and volumes.
