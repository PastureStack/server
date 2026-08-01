# PastureStack Server v1.6.327

This release retains the complete `v1.6.325` database, authentication,
authorization, orchestration, host-agent, API Explorer, and workload behavior.
It replaces the embedded Web Console and advances the pinned first-party
Catalog snapshot without changing persisted workload definitions.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.325`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.327`
- Web Console: `1.6.56-pasturestack.38`
- Web Console source: `21e53a5427a1099af026e72fdee8675d8ed5e55f`
- Web Console artifact SHA-256:
  `572d33673d939240077876a12cc546ab74c2f3525dd86f860ebe1d45344e0438`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Web runtime fixes

The Ember `6.12` compatibility boundary now covers the remaining classic
template behaviors used by the production application: action dispatch,
contextual partial replacements, legacy input and textarea helpers, pod-style
component templates, and query-parameter normalization. The bridge uses public
runtime APIs wherever available and confines the one required private target
fallback to an isolated compatibility shim.

Project-subscription reconnects retain one socket owner. A disconnect callback
may replace the active socket without leaving a competing reconnect timer, and
a delayed close event from an older socket cannot clear a newer connection.
Interactive terminal sessions remain intentionally single-use: an expired
session identifier is not reconnected and a new terminal creates a new
authenticated session.

The exact source passed all 291 Chrome tests. Two clean production builds were
byte-identical. The packaged archive contains 13 production locale files, no
pseudo-locale, no source maps, and the verified upstream license and provenance
files required by the Server image assembly gate.

## Catalog compatibility

The pinned Catalog snapshot retains both current and still-referenced versions
of Network Diagnostics, Network Policy Manager, and Secret Volume Driver.
Existing stacks whose external identifiers end in version `1` therefore keep a
valid detail route while new deployments continue to use version `2`. Catalog
image coordinates remain semantic tags and the deployment audit verifies their
immutable registry digests separately.

## Preserved components

The API Explorer remains `1.1.15`, the Orchestration Engine remains
`0.183.273`, the Authentication Service remains `0.2.5`, and the vSphere CLI
bundle remains `0.55.1-pasturestack.1`. Image assembly compares their critical
executables and the API Explorer tree with `v1.6.325`.

No database schema, account, permission, authentication policy, workload,
node-agent coordinate, host registration, Docker socket, or persisted volume is
changed by this patch.

## Release acceptance requirements

- All Server source gates and the Web Console runtime patch gate pass.
- Two clean image builds produce the same image identifier.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- An isolated candidate preserves the expected API object counts and exposes
  every retained Catalog version route.
- Browser acceptance covers login failure handling, Traditional Chinese,
  Catalog, API Explorer, a forced project-subscription reconnect, and a newly
  created terminal WebSocket session.
- Formal `8080` cutover keeps the proven `v1.6.325` container stopped as an
  exact rollback target until post-deployment acceptance completes.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
