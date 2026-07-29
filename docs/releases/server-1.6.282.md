# PastureStack Server v1.6.282

PastureStack Server `v1.6.282` publishes the reviewed System Image Preloader
Catalog entry while retaining the runtime, Container Schedule entry, optional
network entries, and Taiwan Traditional Chinese Web Console from `v1.6.281`.

## Catalog

- Catalog Templates release: `v0.3.0-rc11`.
- Pinned Catalog commit:
  `3cfb447d7564cf9bada4bac2e15ce3dd6b221615`.
- The reviewed set contains one native project template and ten infrastructure
  templates.
- `PastureStack System Image Preloader` uses the public image
  `ghcr.io/pasturestack/system-image-preloader:v0.3.0`.
- Catalog, Compose, API, and Web Console image fields use semantic version tags
  only.

## Validation

- Runtime URL-contract, retry, and Docker cache lifecycle tests: passed.
- Catalog template rendering with default and optional privileged/private
  registry settings: passed.
- Trivy operating-system and executable results: 0 HIGH and 0 CRITICAL.
- Public GHCR visibility and anonymous manifest access: passed.
- Deployable Catalog image audit: zero blockers.
- Catalog Service validation and API integration: 4 tests passed.
- Taiwan Traditional Chinese name and description: passed.
- Test containers, caches, and temporary Catalog services: removed.

## Catalog upgrade safety

The persisted Catalog transition updates `pinned_commit` first. It leaves the
last indexed `commit` unchanged until Catalog Service has fetched, parsed, and
stored the new eleven-entry index. This prevents a stale nonempty index from
being accepted as current. Rollback bundles preserve both fields.

## Runtime inheritance

This patch image inherits the reviewed runtime, localization, licenses, SBOM,
and immutable assets from Server `v1.6.281`. It changes only the product
version and default pinned Catalog commit. The base image is referenced by the
semantic version tag `ghcr.io/pasturestack/server:v1.6.281`.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.282
```

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
