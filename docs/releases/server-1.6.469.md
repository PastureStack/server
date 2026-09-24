# Server v1.6.469

This patch assembles Web Console `1.6.132` with Orchestration Engine `v0.183.322`
on the preserved digest-pinned `v1.6.460` runtime base.
The environment editor previously read the selected project's network
without `X-Api-Project-Id`. The API correctly returned no unscoped network,
while policy-manager and save requests already used the project context.
The read now uses the same project ID in both its filter and header. No API
authorization, authentication policy, database schema, HAProxy, or production
deployment changes are included.

## Verification boundary

The Web Console unit and browser tests, immutable image build and scan,
QA 8080 startup/restart, and the scoped permission matrix for network APIs
and browser editing
must pass before accepting this patch. The matrix records tested paths and
gaps, not blanket authorization assurance for every API endpoint.
Production `stack.ascdc.tw` is not changed by this release.

## Upgrade and rollback

After publication, update only the Server image reference from `v1.6.468`.
Preserve existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.468` image with the same
configuration and volumes.
