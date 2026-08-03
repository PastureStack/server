# PastureStack Server v1.6.335

This release retains the complete `v1.6.334` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console to restore readable Catalog documentation code blocks.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.334`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.335`
- Web Console: `1.6.56-pasturestack.46`
- Web Console source: `70fcde1ff0fe541a53eae623ed27354171c536e7`
- Web Console artifact SHA-256:
  `2c95ae6999d225b7670d90c4239d2206222b0598c26c4efcd54b4af6f247fb2c`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30798565117`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Catalog code-block contrast

CommonMark emits fenced code as a plain `pre` element containing a nested
`code.language-*` element. The previous Prism theme gave the nested code a
near-white foreground but applied its dark background only when the `pre`
itself had a `language-*` class. Catalog documentation therefore rendered
near-white text on a light-gray surface.

The shared code surface now supplies a `#272822` background and `#f8f8f2`
foreground to every `pre` element. Base code contrast is 13.94:1. Every Prism
syntax color is checked against that surface and the lowest ratio is 5.06:1,
above the WCAG AA threshold for normal text. The release gate checks all four
compiled light, light-RTL, dark, and dark-RTL theme assets and the CommonMark
and component rendering contracts. The authoritative GitHub run passed all
300 Chromium tests and produced two matching release artifacts.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.334`. Their hashes must remain unchanged. No database schema,
account, permission, authentication policy, workload, node-agent coordinate,
host registration, Docker socket, Catalog template, or persisted volume is
changed by this patch.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Two clean GitHub Actions builds produce identical normalized runtime payload
  and image configuration digests.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- Image validation proves all four compiled themes contain the reviewed code
  surface and color palette.
- Formal browser acceptance verifies both NFS documentation code blocks are
  readable without submitting the displayed workload upgrade.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
