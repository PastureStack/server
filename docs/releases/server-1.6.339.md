# PastureStack Server v1.6.339

This release retains the complete `v1.6.338` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to finish restoring directly opened host-container lists.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.338`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.339`
- Web Console: `1.6.56-pasturestack.50`
- Web Console source: `9c0735900e7443d8d1e0de45299c056983fe744d`
- Web Console artifact SHA-256:
  `5839e3b86e5c4d356b187196c90b1e1b52da1d633f61a6fef65c487ee69ea03c`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30812723185`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Host-container table initialization

The host route continues to follow the API resource's canonical `instances`
relationship. Authenticated production acceptance of the preceding release
proved that the relationship and live statistics sockets were healthy, the
search field was empty, and the arranged collection contained rows. The table
still rendered its no-match state because its filtered collection retained the
empty placeholder calculated during component initialization.

The shared sortable table now observes both the relationship collection's
contents and replacement of the collection reference itself. It also computes
filtered rows when invocation attributes are first received. This preserves
the native API relationship while making the initial rows visible immediately.
Natural sorting, compact pagination, column selection, search, and live
statistics remain synchronized.

The authoritative Web Console run passed all 304 Chromium tests, explicit
late-population and collection-replacement regression gates, and two clean
production builds that produced the same artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.338`. Their hashes must remain unchanged. No database schema,
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
- Image validation proves the compiled host-container route follows the native
  `instances` relationship and that the compiled table handles collection
  population, collection replacement, and initial invocation attributes.
- Formal browser acceptance directly reloads a host URL, verifies visible rows
  and compact pagination, exercises search and clear-search, and confirms the
  statistics sockets remain connected. API counts alone are not sufficient.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
