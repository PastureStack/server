# PastureStack Server v1.6.308

This release integrates the reviewed PastureStack Web Console container-table
controls without changing the Server API, persisted data model, Catalog
coordinates, or Docker host support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.307`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.308`
- Web Console: `1.6.56-pasturestack.19`
- Web Console source:
  `e27d5b8106d822ad21478fd7b6223c7aefb10a31`
- Reviewed Web Console artifact SHA-256:
  `7e64360378e2ba14568c5452ad24703481d38b74e0b9085dba369ba044b0a165`
- Newest supported Docker Engine remains `29.6.2`.

Runtime and documentation coordinates use semantic version tags. The artifact
hash above is release-verification evidence and is not used as a container image
coordinate in the Catalog, API, or Web Console.

## Container table behavior

- Container Image and Command are independent columns and are both hidden by
  default.
- Host and service container views use new scoped column-preference keys so the
  reviewed defaults apply once. Later operator choices continue to persist in
  the browser.
- The toolbar order is Columns, Rows per page, and Search.
- The Rows per page control keeps its own width and cannot be squeezed out by
  search or pagination.
- Pagination displays a compact, single-line
  `current page / total pages` summary.
- Natural sorting, content-aware widths, synchronized sticky headers, metric
  sparklines, sampled RMS sorting, and live-sort hysteresis remain unchanged.

## Localization

- All 13 shipped locale files contain the complete 2,387-message English
  baseline.
- Validation reports zero missing keys, orphan keys, or invalid ICU messages.
- Traditional Chinese uses `CPU`, `RAM`, `網路`, `儲存`, `容器映像`,
  `IP 位址`, `命令`, and `每頁顯示`.
- The numeric page summary is language-neutral and does not wrap.

## Release gates

- GitHub Actions run `30247491429` passes all 228 Web Console Chromium tests.
- Two Web Console production builds are byte-identical.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- Server assembly must verify the hidden-column defaults, toolbar order,
  compact page summary, all 13 locales, Docker `29.6.2` host policy, reviewed
  Catalog commit, external data volumes, and tag-only runtime coordinates.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
