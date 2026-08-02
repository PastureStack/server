# PastureStack Server v1.6.331

This release retains the complete `v1.6.325` database, authentication,
authorization, orchestration, host-agent, API Explorer, and workload behavior.
It replaces only the embedded Web Console and the reproducibly rebuilt console
broker while retaining the pinned first-party Catalog snapshot and all
persisted workload definitions.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.325`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.331`
- Web Console: `1.6.56-pasturestack.42`
- Web Console source: `25f9e4af353ec11cb452b67d9b30c00dee5e2b14`
- Web Console artifact SHA-256:
  `cb8359166822e77247f06fe103691c6f7297042c2da79269af54086a78913584`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Catalog upgrade version selection

The installed Catalog revision remains the immutable identity. The Catalog API
resolves that revision to its display version and supplies exact compatible
targets through `upgradeVersionLinks`. The stack-list update badge and upgrade
form now consume the same map. The upgrade form displays the installed version
as the current option and every valid API link as a selectable target.

The browser does not infer an upgrade from an image tag, Catalog default
version, or a rewritten external identifier. The shared native select exposes
its grouped and ungrouped content as class-level reactive properties supported
by the Ember 6 runtime. Image assembly verifies the corresponding markers in
the compiled JavaScript, not only in source files.

The exact Web Console source passed its full Chrome suite, 13 production
locales, privacy and license gates, and two byte-identical production builds.
Its archive contains no pseudo-locale and no source maps. The public release
asset also downloads anonymously with the pinned SHA-256 value.

## Preserved components

The API Explorer remains `1.1.15`, the Orchestration Engine remains
`0.183.273`, the Authentication Service remains `0.2.5`, and the vSphere CLI
bundle remains `0.55.1-pasturestack.1`. Image assembly compares their critical
executables and the API Explorer tree with `v1.6.325`.

No database schema, account, permission, authentication policy, workload,
node-agent coordinate, host registration, Docker socket, or persisted volume is
changed by this patch.

## Release acceptance requirements

- All Server source gates and console-broker package tests pass.
- Two clean image builds produce the same image identifier.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- An isolated candidate preserves API object counts and returns the expected
  Catalog revision-to-version and upgrade-link maps.
- Formal browser acceptance confirms selectable versions for an installed old
  Metadata Healthcheck revision and NFS Storage revision without executing an
  upgrade.
- Formal `8080` cutover preserves the previous image, container configuration,
  persistent volumes, and workload container identities as the rollback target.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
