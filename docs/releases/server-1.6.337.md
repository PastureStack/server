# PastureStack Server v1.6.337

This release retains the complete `v1.6.336` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to complete direct host-container route loading.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.336`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.337`
- Web Console: `1.6.56-pasturestack.48`
- Web Console source: `2334be807ac06edbee790a72f1f9e5ffdddfd8e4`
- Web Console artifact SHA-256:
  `156b46116aa7fa88c33393483afbc1bd120ab96bc8e042b3ec9f67e54faa99ea`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30803251668`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Filtered host-container preload

The host resource contains container IDs, while its denormalized `instances`
relationship resolves only records already present in the API Store. Entering
the host-container URL directly or reloading it bypassed the project host-list
route that previously populated those records. The backend containers and
statistics endpoints remained healthy, but the table received an empty array.

The host-container route now requests only instances matching the selected
`hostId` before it returns the existing host model. It does not fetch unrelated
project containers and does not start statistics streams for rows outside the
current page. The shared late-body refresh from `v1.6.336` remains in place for
subsequent relationship updates. The authoritative GitHub run passed all 302
Chromium tests and two clean production builds produced the same artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.336`. Their hashes must remain unchanged. No database schema,
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
- Image validation proves the compiled host-container route contains the
  filtered `hostId` instance preload and the shared table refresh contract.
- Formal browser acceptance directly reloads the requested host URL, verifies
  its rows and compact pagination, exercises search and clear-search, confirms
  statistics sockets remain connected, and rechecks Catalog code contrast.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
