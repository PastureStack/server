# PastureStack Server v1.6.281

PastureStack Server `v1.6.281` publishes the reviewed Container Schedule
Catalog entry while retaining the runtime, optional VXLAN entry, and Taiwan
Traditional Chinese Web Console from `v1.6.280`.

## Catalog

- Catalog Templates release: `v0.3.0-rc10`.
- Pinned Catalog commit:
  `8e4caa289895855df9706ebf625f401da4ca2e5b`.
- The reviewed set contains one native project template and nine
  infrastructure templates.
- `PastureStack Container Schedule` uses the public image
  `ghcr.io/pasturestack/container-cron:v0.6.0`.
- Catalog, Compose, API, and Web Console image fields use semantic version tags
  only.

## Validation

- Container Cron race tests, static analysis, and Docker 29.4 start/stop
  lifecycle: passed.
- Trivy operating-system and Go-binary results: 0 HIGH and 0 CRITICAL.
- Public GHCR visibility and anonymous manifest access: passed.
- Deployable Catalog image audit: zero blockers.
- Catalog Service validation and API integration: 4 tests passed.
- Taiwan Traditional Chinese name and description: passed.
- Test containers, caches, and temporary Catalog services: removed.

## Catalog upgrade safety

The persisted Catalog transition updates `pinned_commit` first. It leaves the
last indexed `commit` unchanged until Catalog Service has fetched, parsed, and
stored the new ten-entry index. This prevents a stale nonempty index from being
accepted as current. Rollback bundles preserve both fields.

## Runtime inheritance

This patch image inherits the reviewed runtime, localization, licenses, SBOM,
and immutable assets from Server `v1.6.280`. It changes only the product
version and default pinned Catalog commit. The base image is referenced by the
semantic version tag `ghcr.io/pasturestack/server:v1.6.280`.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.281
```

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
