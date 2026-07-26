# PastureStack Server v1.6.306

This release integrates the reviewed PastureStack Web Console container-table
and terminal-workspace refinements without changing the Server API, persisted
data model, Catalog coordinates, or Docker host support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.305`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.306`
- Web Console: `1.6.56-pasturestack.17`
- Web Console source:
  `d0daefe82fd659acb6551c5ea0788b0b84d98244`
- Reviewed Web Console artifact SHA-256:
  `dcc33cb8f2c2417330f78dd0f26b65c0a884545f03e58289807db7023a2b65d5`
- Newest supported Docker Engine remains `29.6.2`.

Runtime and documentation coordinates use semantic version tags. The artifact
hash above is release-verification evidence and is not used as a container image
coordinate in the Catalog, API, or Web Console.

## Container table behavior

- Host and service container views use natural sorting and pagination.
- The default page size is 10 rows, with 10, 25, and 50 row choices.
- CPU, memory, network, and storage activity appear in four separate columns.
- Each value is a root mean square over the same 60-sample window shown by its
  chart.
- Live metric sorting is sampled every 10 seconds and applies 5 percent
  hysteresis, preventing continuously moving rows while retaining useful
  effective-load ordering.
- Genuine row changes use a bounded transition, and charts are created only for
  the visible page.
- The statistics socket is suspended while the browser tab is hidden.

## Terminal workspace behavior

- An active session uses a neutral background and its status indicator.
- Blue background, lift, scale, and shadow appear only while the pointer is
  actually over the control.
- Keyboard focus remains visible through a dedicated focus outline.

## Validation

- The complete 224-test Web Console Chromium suite passes.
- Two Web Console production builds are byte-identical.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- All 46 Server source gates pass.
- The focused Server image preserves the Docker `29.6.2` host policy, reviewed
  Catalog commit, external data volumes, and semantic runtime coordinates.
- Fresh isolated startup, existing-data cutover, Catalog preservation, system
  workload state, and rollback behavior pass.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
