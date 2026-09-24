# Server v1.6.468

This patch assembles Web Console `1.6.131` with Orchestration Engine `v0.183.322`
on the preserved digest-pinned `v1.6.460` runtime base.
The administrative account collection includes project accounts, such as
the shared Default project. The account page only displays user/admin
accounts, but Web Console 1.6.130 requested user-only identity links for
every account in the collection. A project account's expected 404 blocked
the whole page. The route and controller now share the displayed-kind
predicate; authorization and backend errors for visible accounts remain
visible rather than being discarded.

No API authorization, authentication policy, database schema, HAProxy, or
production deployment changes are included.

## Verification boundary

Source and browser-unit gates, the immutable image build and scan, QA 8080
startup/restart, the real account-page browser check, and the scoped
v1/v2-beta permission matrix must pass before claiming this patch is
accepted. The matrix lists its tested paths and gaps; it is not proof of
every API endpoint. Production `stack.ascdc.tw` is not changed here.

## Upgrade and rollback

After publishing the immutable image digest, update only the Server image
reference from `v1.6.467`. Preserve existing Compose environment variables,
named volumes, restart policy, AppArmor, HTTPS origin, OIDC, performance
settings, and firewall backend. Rollback selects the preserved
`v1.6.467` image with the same configuration and volumes.
