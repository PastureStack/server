# PastureStack Server v1.6.277

PastureStack Server `v1.6.277` repairs Catalog recovery when a stored repository commit is current but its local template index is empty.

## Catalog recovery

- Catalog Service `v0.20.7` checks whether the matching catalog and environment actually contain indexed templates before skipping a refresh.
- An empty index is rebuilt from the reviewed, commit-pinned GitHub Catalog.
- A populated index at the same commit keeps the established fast path.
- The Catalog Service release passed its full test suite and two byte-identical builds.
- Fresh Server startup and restart validation require all six reviewed Catalog templates to remain available.

All inherited runtime history, licenses, authorship, and compatibility identifiers remain preserved. The updated deterministic Runtime license bundle records the exact Catalog Service source commit and distributed archive.

## Included runtime

- Orchestration Engine `v0.183.269`
- Web Console compatibility artifact `1.6.56`
- API Explorer `1.1.14`
- Catalog Service `v0.20.7`
- Node Agent `v1.2.31`
- Load Balancer Service `v0.9.25`
- Catalog commit `91f5910a44cb181051be2adc4c14f0e6ec7842ef`

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.277
```

Keep the operational image reference in semantic version-tag form. The matching GitHub Release retains the resolved digest as verification evidence.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.
