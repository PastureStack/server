# PastureStack Server v1.6.338

This release retains the complete `v1.6.337` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to restore directly opened host-container lists.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.337`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.338`
- Web Console: `1.6.56-pasturestack.49`
- Web Console source: `1603b04a79d3b33667fd2158eaf65ffa44c86c8c`
- Web Console artifact SHA-256:
  `41b7526481cd2b5bfd206f29ce31293993adf5467af8213a74acff7ab9e6e7ec`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30805517980`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Native host-container relationship

The host API resource provides a canonical `instances` relationship link.
Direct page entry now follows that link and passes its returned collection to
the table. This avoids relying on another route to populate the API Store and
does not infer membership through `hostId`, which is not a filterable field in
the legacy instance collection schema.

The shared late-body refresh remains in place for subsequent relationship
updates. Natural sorting, compact pagination, column selection, search, and
page-scoped statistics behavior are retained. The authoritative GitHub run
passed all 302 Chromium tests and two clean production builds produced the
same artifact.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.337`. Their hashes must remain unchanged. No database schema,
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
  `instances` relationship and retains the shared table refresh contract.
- Formal browser acceptance directly reloads the requested host URL, verifies
  rows and compact pagination, exercises search and clear-search, confirms
  statistics sockets remain connected, and rechecks Catalog code contrast.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
