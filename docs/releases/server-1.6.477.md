# Server v1.6.477

This patch assembles Web Console `1.6.142` with the unchanged Orchestration
Engine `v0.183.326` on the preserved Server `v1.6.460` runtime base.
Receiver cloning no longer sends the source's server-issued webhook URL or lifecycle
state; a new Receiver receives its own URL from the Server. A new private
ProjectTemplate no longer inherits the catalog Default's external identity.
Direct create and environment-route denials use localized messages without
revealing whether an inaccessible environment ID exists. Container table
actions remain reachable while the data columns scroll independently in
LTR and RTL layouts, including narrow panels and desktop-to-mobile resizing.

This release changes no Engine authorization rule, API protocol, database
schema, OIDC configuration, HAProxy setting, or production deployment.
ProjectTemplate write permissions remain owner-scoped, and the prior
read-only `projectTemplate.isPublic` `/v1` schema fix remains present.

## Immutable component inputs

- Orchestration Engine `v0.183.326`, commit
  `66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, `cattle.jar` SHA-256
  `6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
- Web Console `1.6.142`, commit
  `4a056b75c41881743dbfbdc7c4bbee5cf2214123`, archive SHA-256
  `26bce780df81fb91f525f994729501394ae21672eed2be3ea5e378bf38eb41cc`.
- Webhook Automation Service remains `0.10.3`; Authentication Service remains
  `0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

Source and browser tests, deterministic double-build, isolated Server
boot/restart, merged-rootfs security inventory, SBOM identity, and published
image digest readback are release gates. They do not replace the six-role,
per-resource-ID, same-page write-flow, and locale/layout acceptance on the
separate `8080` QA installation. Untested matrix entries remain untested.

## Upgrade and rollback

Upgrade by changing only the Server image reference to the immutable numeric
tag `ghcr.io/pasturestack/server:v1.6.477` and its verified digest. Preserve
Compose environment variables, named volumes, restart policy, AppArmor,
HTTPS origin, OIDC, performance settings, and firewall backend.
Rollback selects the preserved `v1.6.476` image with the same configuration and
volumes. Neither tag is overwritten; `stack.ascdc.tw` is outside this QA
deployment.
