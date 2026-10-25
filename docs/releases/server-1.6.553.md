# Server v1.6.553 candidate

Prepared source only; no Server image or release has been published.
Deployment acceptance is not claimed until the normal protected release workflow
and the affected runtime checks complete.

## Scope

CVE-2026-111497 affects the Brotli decoder. The accepted Google fix is applied
to the pinned Ubuntu source without replacing Ubuntu packaging or adding
packages to the runtime. The qualified shared bundle binds the official patch,
native owning tests, ordinary compression/streaming tests, three-library ABI,
package bytes, consumer installation receipts and exact-package OpenVEX.

Web Console `1.6.195`, Engine `v0.183.354`, Host API `0.38.8`, Temurin
`25.0.5+8` and their application behavior are retained. Node Agent `v1.2.34`
uses published compatibility base `v0.3.8`. Catalog `v0.3.18`, source
`00eec89e5fdeb9728c1c41babccad8b7dfc8b297`, references the separately published
qualified component images. Node.js
build SDK checks are separate from the static web runtime artifacts.

## Upgrade and rollback

Back up the database and all three named volumes. Preserve the existing Compose
environment, HTTPS origin, ports, AppArmor, mounts and restart policy. After
publication use the numeric `ghcr.io/pasturestack/server:v1.6.553` tag, then
upgrade existing infrastructure Stacks and Host Agents normally. A new Server
default does not override an explicit database setting.

Keep the preceding immutable images and matching data checkpoint. Do not run
`docker compose down -v` or retain an old runtime web-bundle override. A rollback
may require restoring the matching database and volumes; never restore over
the only copy of current data.

## Acceptance boundary

Only affected package installation, linkage, startup/restart and system-service
functions require new evidence. Unchanged UI, language, RBAC and session tests
retain their earlier results. Runtime adoption must identify the actual
container digest on each eligible Host; registry publication alone is not
deployment acceptance. Production, HAProxy and host firewall configuration are
outside this QA deployment.
