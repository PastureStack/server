# PastureStack Server v1.6.336

This release retains the complete `v1.6.335` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to restore asynchronously populated rows in shared sortable tables.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.335`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.336`
- Web Console: `1.6.56-pasturestack.47`
- Web Console source: `d22b1e3c50c7b0dceeb38d429cac67442c932c2a`
- Web Console artifact SHA-256:
  `8303af1fd61cfb6b48c79de8eaf68541539c6277386305149247f5eaad2b9277`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30801530024`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Late-bound sortable-table refresh

Host container relationships are initially empty and are populated after the
host route renders. The shared sortable table previously calculated its
filtered result during initialization, then used legacy string-form run-loop
callbacks that no longer invoked the refresh on Ember 6. The API resources and
statistics sockets remained healthy, but the table incorrectly displayed its
no-match state.

The shared table now observes its body directly and schedules content and
search updates with function references. Natural sorting, pagination, column
selection, search, and live-stat sorting continue to operate on the refreshed
rows. The authoritative GitHub run passed all 301 Chromium tests, including
empty initialization, late relationship population, natural ordering, search,
and clearing search. Two clean production builds produced the same artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.335`. Their hashes must remain unchanged. No database schema,
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
- Image validation proves the compiled vendor bundle observes late body
  changes and uses function-reference throttle and debounce callbacks.
- Formal browser acceptance verifies the requested host shows its containers,
  search and clear-search update rows, statistics sockets remain connected,
  and the NFS Catalog documentation retains readable code blocks.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
