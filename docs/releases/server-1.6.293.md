# PastureStack Server v1.6.293

PastureStack Server `v1.6.293` completes the reviewed platform Catalog
experience and makes the Web Console update durable across container restarts.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.7`, built from commit
  `bce877cc526774dbbd11c4856aac43275868ed10`.
- Pins Catalog Templates release `v0.3.0-rc21` at commit
  `30caa02cfef52e26dc65cfceba5c36b3150283f2`.
- Publishes all 22 platform-maintained infrastructure templates and the
  project template while excluding third-party templates.
- Embeds the index cache correction from Orchestration Engine commit
  `e9fe2a2c1d328f547a4d5bb34f370515e5e5e572`.
- Prevents a directly opened or refreshed Web Console route from reusing an
  obsolete HTML entry point after an upgrade.
- Increases Catalog card layout space so Taiwan Traditional Chinese
  descriptions remain readable without clipping.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Validation covers the Orchestration Engine cache tests, all 198 Web Console
browser tests, Catalog template and image-coordinate gates, the production
Server image, direct-route browser loading, all Catalog card images, layout
clipping, and scheduled Catalog refreshes.

## Image

```text
ghcr.io/pasturestack/server:v1.6.293
```

## Rollback

Stop the `v1.6.293` container and restore the exact stopped `v1.6.292`
container with the same server data volume. The `v1.6.292` image and stopped
container are retained until live acceptance is complete.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
