# PastureStack Server v1.6.283

PastureStack Server `v1.6.283` fixes a cold-start race that could leave the
Catalog page empty after the server container restarted.

## Runtime change

- Keeps the reviewed Catalog Templates release `v0.3.0-rc11` pinned to commit
  `3cfb447d7564cf9bada4bac2e15ce3dd6b221615`.
- Starts a bounded bootstrap worker with the Catalog Service.
- Detects an empty Catalog collection and requests a refresh automatically.
- Stops retrying as soon as the collection is non-empty.
- Applies connection, request, delay, and attempt limits so a network outage
  cannot create an unbounded retry loop.

The compatibility service names and persisted control-platform settings remain
unchanged. The change only repairs initial Catalog population after a cold
start.

## Image

```text
ghcr.io/pasturestack/server:v1.6.283
```

Deployment references must use this semantic tag. Digests are retained only in
internal release evidence.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
