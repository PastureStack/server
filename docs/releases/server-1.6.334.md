# PastureStack Server v1.6.334

This release retains the complete `v1.6.333` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console with the reviewed immutable-revision localization and latest-request
Catalog upgrade repair.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.333`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.334`
- Web Console: `1.6.56-pasturestack.45`
- Web Console source: `7a388418b10168cab56853d4be553f65f1f2c48e`
- Web Console artifact SHA-256:
  `44d825c31749490dad5e7262d9e1d4bec1ffbaa94fab3d8e44bb8493ec920b6e`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30778555612`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Catalog revision alignment

Published numeric Catalog revisions remain immutable. When an installed older
revision predates localized question metadata, the upgrade form retains labels
learned from another revision of the same template and uses them only as a
fallback for matching variables. Metadata supplied by the selected revision
always takes precedence, and changing templates clears the cache. The revision
payload and prospective upgrade external identifier are not rewritten.

Version-resource requests are latest-response-only. A delayed request cannot
replace the selected version's questions, localized labels, Compose preview,
or loading state after an operator changes the selector again.

The preceding exact `upgradeVersionLinks`, native enum, and value-aware
required-answer repairs remain enforced. The Web Console release gate compiles
all 332 Handlebars templates, scans all 663 JavaScript modules, verifies all 12
supported schema input components, runs the complete browser suite, and builds
two matching release candidates.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.333`. Their hashes must remain unchanged. No database schema,
account, permission, authentication policy, workload, node-agent coordinate,
host registration, Docker socket, or persisted volume is changed by this
patch.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Two clean GitHub Actions builds produce identical normalized runtime payload
  and image configuration digests.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- Image validation proves the localization merge and request serial markers are
  present in the embedded compiled JavaScript.
- Formal browser acceptance verifies all 22 Catalog forms and 171 questions,
  both installed Healthcheck and NFS update targets, and both NFS revisions in
  Traditional Chinese without executing a workload upgrade.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
