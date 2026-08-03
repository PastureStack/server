# PastureStack Server v1.6.332

This release retains the complete `v1.6.331` database, authentication,
authorization, orchestration, host-agent, API Explorer, terminal broker,
Catalog snapshot, and workload behavior. It replaces only the embedded Web
Console with the fully reviewed Catalog upgrade-form repair.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.331`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.332`
- Web Console: `1.6.56-pasturestack.43`
- Web Console source: `7f71f4d93578178b3acc847d8151f57e2a0e9e92`
- Web Console artifact SHA-256:
  `843e7d308253382b7890f38de1d1cea3f8ce3e2954b368e237c77b0c46e2f82b`
- Web Console validation run:
  `https://github.com/PastureStack/web-console/actions/runs/30772901928`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Catalog upgrade form

The stack-list update badge and the upgrade form consume the same exact
`upgradeVersionLinks` map. The installed Catalog revision is displayed as the
current version and every non-empty API link is a selectable target. The
browser does not infer an upgrade from an image tag, a Catalog default version,
or a rewritten external identifier.

Full NFS acceptance also found a separate Ember 6 template-compiler collision:
an `option` block parameter shadowed the native `<option>` element. Primitive
values such as `nfsvers=4` were therefore treated as dynamic component
definitions, producing `Invalid value used as weak map key`, an empty enum,
and no later questions. The block parameter is now unambiguous. A compiler gate
rejects dynamic-component bytecode at this boundary.

Formal acceptance verifies both NFS protocol versions, both data-removal
policies, and the following debug setting. It does not submit a workload
upgrade because this release changes the form, not the user's running NFS
service.

## Preserved components

Image assembly compares the Server Engine, Authentication Service, Catalog
Service, API Explorer, vSphere CLI bundle, WebSocket proxy, and terminal broker
against `v1.6.331`. Their hashes must remain unchanged. No database schema,
account, permission, authentication policy, workload, node-agent coordinate,
host registration, Docker socket, or persisted volume is changed by this
patch.

## Release acceptance requirements

- All Server source gates pass from the immutable Server commit.
- Two clean, isolated GitHub Actions image builds produce identical RootFS
  layer lists and runtime configuration. OCI image IDs may differ when build
  history timestamps differ and are therefore recorded, not misreported as
  byte-identical payload evidence.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- Image validation proves the exact version-link and native-enum markers are in
  the embedded compiled JavaScript.
- Formal browser acceptance verifies Metadata Healthcheck and NFS Storage
  current and target versions, complete NFS enum questions, and every following
  field without executing an upgrade.
- Formal `8080` cutover preserves the previous container configuration,
  persistent volumes, and nonvolatile workload identities as rollback evidence.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
