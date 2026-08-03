# PastureStack Server v1.6.341

This release retains the complete `v1.6.340` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to stabilize host storage pagination and selected-volume removal.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.340`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.341`
- Web Console: `1.6.56-pasturestack.52`
- Web Console source: `37f6a581aa1318dd575a179677b4b439af6e0b2d`
- Web Console artifact SHA-256:
  `77fa9f75e3803bb82906fa4f327e383ada244bb7aa9feed22e494967b843355b`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30818724024`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Storage pagination

The shared sortable-table component now treats its invocation `perPage` value
as caller-owned input. It synchronizes that input into a separate writable
effective page size and never writes a user selection back through a read-only
computed property. The `All` choice persists the semantic value `0` while the
pagination proxy receives a bounded internal value that renders all currently
filtered rows. Valid positive page sizes supplied by callers remain supported,
even when they are not options in the interactive selector.

## Selected-volume removal

The confirmation workflow reports each successful API removal to the host
storage controller immediately. The controller removes that exact resource
from the route model and selected-items collection, then increments an explicit
table revision. Visible rows, the selected count, filter results, and paging
therefore update after each success without requiring a browser reload. A final
completion callback remains idempotent and safely reconciles partial failures.

The authoritative Web Console run passed all 307 Chromium tests, including
caller-owned page-size, semantic `All`, and per-success removal regressions.
Two clean production builds produced the same reviewed artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.340`. Their hashes must remain unchanged. No database schema,
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
- Image validation proves the compiled table has a separate effective page
  size and rejects caller-owned page-size mutation.
- Image validation proves the compiled removal workflow reports every success
  and explicitly revises the visible storage collection.
- Formal browser acceptance changes among `10`, `25`, `50`, and `All` without
  an application error or stale row count.
- Formal removal acceptance uses only a deliberately created disposable volume
  and verifies that its row and selection count update without a reload.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
