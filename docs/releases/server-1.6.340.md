# PastureStack Server v1.6.340

This release retains the complete `v1.6.339` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to synchronize host-container rows into the rendered page.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.339`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.340`
- Web Console: `1.6.56-pasturestack.51`
- Web Console source: `fe7f366d9d976404a0bfb6b2763999cd99e9efa0`
- Web Console artifact SHA-256:
  `3676d870f2326f47897f97da9a9fc16173d2edf3daccf0ed62754cac8e590f7a`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30814351879`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Rendered-page synchronization

The host route continues to follow the API resource's canonical `instances`
relationship. Authenticated acceptance of the preceding release proved that
the route, relationship, filtered collection, and statistics sockets were
healthy. The rendered page remained empty because the legacy pagination proxy
relied on a string binding that no longer propagated the filtered collection
under the modern Ember runtime.

The shared sortable table now explicitly synchronizes filtered content, page
number, and page size into the pagination proxy. Late-populated, replaced, and
initial relationship collections all reach the rendered page. Search, clear
search, page changes, page-size changes, natural sorting, column selection,
and live statistics remain synchronized.

The authoritative Web Console run passed all 305 Chromium tests, including
rendered-page, page-number, and page-size regression cases, and two clean
production builds produced the same artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.339`. Their hashes must remain unchanged. No database schema,
account, permission, authentication policy, workload, node-agent coordinate,
host registration, Docker socket, Catalog template, or persisted volume is
changed by this patch. The four reviewed theme assets and their WCAG AA Catalog
code-block contrast contract are retained.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Two clean GitHub Actions builds produce identical normalized runtime payload
  and image configuration digests.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- Image validation proves the compiled table explicitly synchronizes filtered
  content, page number, and page size into the rendered-page proxy.
- Formal browser acceptance directly reloads a host URL, verifies visible row
  elements and pagination, searches for an existing row, clears the search,
  and confirms statistics sockets remain connected. API or filtered counts
  alone are not sufficient.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
