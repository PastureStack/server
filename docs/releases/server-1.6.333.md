# PastureStack Server v1.6.333

This release retains the complete `v1.6.332` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console with the reviewed Catalog required-answer validation repair.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.332`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.333`
- Web Console: `1.6.56-pasturestack.44`
- Web Console source: `32901abe204df613aff1cffde95d4ec0116b6eff`
- Web Console artifact SHA-256:
  `334ee4e93c2a96213b693839a60e8e8bd8bc3706b84bfb59d2e9ae7c824a5dd1`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30776255840`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Catalog form validation

Required Catalog questions now treat boolean `false` and numeric `0` as valid
answers. Only `null`, `undefined`, blank strings, and empty arrays are treated
as missing. This prevents a valid default such as Kubernetes
`FAIL_ON_SWAP=false` from blocking a launch while preserving required-field
validation for genuinely empty answers.

The Web Console release gate compiles all 332 Handlebars templates, scans all
663 JavaScript modules, verifies all 12 supported schema input components, and
tests the required-answer boundary. Formal acceptance covers all 22 current
Catalog launch forms and all 171 questions without launching or upgrading a
workload.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.332`. Their hashes must remain unchanged. No database schema,
account, permission, authentication policy, workload, node-agent coordinate,
host registration, Docker socket, or persisted volume is changed by this
patch.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Two clean GitHub Actions builds produce identical normalized runtime payload
  and image configuration digests.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- Image validation proves the exact required-answer helper is present in the
  embedded compiled JavaScript.
- Formal browser acceptance verifies all 22 Catalog forms, the installed
  Metadata Healthcheck and NFS Storage upgrade-version selectors, complete
  enum fields, and every following question without executing an upgrade.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, host and agent health, and nonvolatile workload
  identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
