# PastureStack Server v1.6.307

This release integrates the reviewed PastureStack Web Console table-layout and
localization refinements without changing the Server API, persisted data model,
Catalog coordinates, or Docker host support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.306`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.307`
- Web Console: `1.6.56-pasturestack.18`
- Web Console source:
  `dd71bdba68df574507982e7cf411ae782296657a`
- Reviewed Web Console artifact SHA-256:
  `41be21341b23ccde05e9b40008d897528b1fedd5ba28692c7ff530668e70abbb`
- Newest supported Docker Engine remains `29.6.2`.

Runtime and documentation coordinates use semantic version tags. The artifact
hash above is release-verification evidence and is not used as a container image
coordinate in the Catalog, API, or Web Console.

## Container table behavior

- Host and service container views use natural sorting and pagination.
- The default page size is 10 rows, with 10, 25, and 50 row choices.
- The primary columns are State, Name, CPU, RAM, Network, Storage, Container
  Image, IP Address, optional Host, Command, and Actions.
- Container Image and Command are independent columns. Command is hidden by
  default and remains available through the column selector.
- The column selector appears immediately before search and persists each
  view's choices in the browser.
- Content-aware widths keep compact values narrow, preserve useful image space,
  and avoid wrapping until the viewport requires it.
- The body and sticky header remain horizontally synchronized.
- CPU, RAM, network, and storage sparklines render on the first visible frame.
- Each sortable metric remains a root mean square over the same 60-sample
  window shown by its chart. The concise column labels do not expose that
  implementation detail.
- Live metric sorting remains sampled with hysteresis so rows do not constantly
  jump while values fluctuate.

## Localization

- All 13 shipped locale files contain the complete 2,387-message English
  baseline.
- Validation reports zero missing keys, orphan keys, or invalid ICU messages.
- Traditional Chinese uses `CPU`, `RAM`, `網路`, `儲存`, `容器映像`,
  `IP 位址`, and `命令`.
- Image and command are never presented as a combined label.

## Validation

- GitHub Actions run `30244624396` passes.
- The complete 228-test Web Console Chromium suite passes.
- Two Web Console production builds are byte-identical.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- The focused Server image preserves the Docker `29.6.2` host policy, reviewed
  Catalog commit, external data volumes, and semantic runtime coordinates.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
