# Server v1.6.470

This patch assembles Web Console `1.6.135` and Orchestration Engine `v0.183.323`
on the preserved digest-pinned `v1.6.460` runtime base.
Host creation and cloning now use the active project's effective host POST
schema. A direct Add Host URL without create permission shows a 403 before
registration data loads. Responses from an earlier project selection cannot
restore stale create controls. Project details wait for the selected project
before reading its network and policy. Host access errors are localized in all
13 console locales and fit narrow and right-to-left layouts.

Site administrators can switch to every active environment, even without a
direct project membership. Other users continue to request only the
environments authorized for their account; the Server remains the enforcement
point for `all=true` and direct project IDs. The affected switcher labels
also have corrected French and Russian translations. The Engine packages FreeMarker
`2.3.35` exactly once, and the Server refreshes Ubuntu 26.04 curl packages to
the signed `8.18.0-1ubuntu2.7` security revision from
[USN-8820-1](https://ubuntu.com/security/notices/USN-8820-1). Unfixed Medium findings are
tracked by exact package and CVE in `server/security/vendor-pending.json`;
they are not relabeled as fixed.

No backend API, authentication policy, database schema, HAProxy, or production
deployment change is included.

## Verification boundary

Component tests and pinned artifact checks are required before assembly.
Release acceptance also requires the Server source gates, immutable image
build and merged-rootfs security scan, QA 8080 startup/restart, role-based
v1/v2 permission checks, and browser tests of the affected UI across locales
and narrow/right-to-left layouts. The permission matrix records tested paths
and gaps; it does not establish every API endpoint's authorization. Production
`stack.ascdc.tw` is not changed by this release.

## Upgrade and rollback

After publication, update only the Server image reference from `v1.6.469`.
Preserve existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.469` image with the same
configuration and volumes.
