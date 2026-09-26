# Server v1.6.471

This patch packages Web Console `1.6.136` on the preserved Server `v1.6.470`
assembly and digest-pinned `v1.6.460` runtime base. The environment switcher
menu opens toward available viewport space in left-to-right and right-to-left
views. Its width is bounded on narrow screens, and long entries wrap. Other
dropdowns keep their existing placement. The Persian `/fail` page also uses
the intended right-to-left direction in compiled stylesheets.

Environment authorization remains Server-enforced. On authenticated console
load, the console revalidates a stored environment selection with a fresh
direct GET. A 403 or 404 falls back to an available environment; 401 and 5xx
errors are surfaced. Environment management uses the current fresh collection
so stale cached records cannot keep a revoked environment visible. The refresh
preserves the active environment and loaded schema on return navigation. A
permitted direct URL still works when its environment is absent from the
collection. Site administrators continue to see every active environment;
other users receive only their authorized collection.
An already open view can retain its former selection until reinitialization
or an explicit switch; the Server checks project membership on each request.

Orchestration Engine `v0.183.323` remains, with FreeMarker `2.3.35` packaged
exactly once. Authentication Service remains `v0.4.42`. The signed Ubuntu
26.04 curl packages remain at `8.18.0-1ubuntu2.7`. The reviewed OpenVEX
statements and vendor-pending findings retain their exact package and CVE
sets. No backend API, authentication policy, database schema, HAProxy, or
production deployment change is included.

## Verification boundary

The Web Console release asset must match its published commit and SHA-256.
Server source gates, the immutable image build, merged-rootfs security scan,
and isolated startup/restart smoke must pass before publication. QA 8080
browser checks of the environment switcher in left-to-right and right-to-left
layouts, the Persian `/fail` page, and the affected account roles remain a
separate deployment gate. Production `stack.ascdc.tw` is not changed by
publishing this release.

## Upgrade and rollback

After publication, update only the Server image reference from `v1.6.470`.
Preserve existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.470` image with the same
configuration and volumes.
