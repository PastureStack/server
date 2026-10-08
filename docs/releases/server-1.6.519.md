# Server v1.6.519

Status: unpublished candidate. No registry digest or new artifact-scan result
is claimed by this source document.

## Scope

Restricted and expiring API Keys use the same Engine authorization boundary
as full keys, intersected with the owner's live role and environment access.
Operation decisions and actual request/process outcomes are durably audited
without credential secrets or request payloads. Key-scoped audit queries
recheck the viewer's current authorization before filtering and pagination.
Delegated terminal/log access rechecks current authorization; terminal outcomes
are accepted only from the authenticated host's agent, with durable deduplication.
An API Key stream cannot start against a backend without the verified audit
capability. That blocked handshake is recorded as `FAILED`, phase `handshake`,
HTTP `503`; it is not an executor completion. Cookie-based access is unchanged.
A signed ticket used for a different stream route is rejected and durably
recorded as `DENY`/`FAILED`, phase `handshake`, HTTP `403`. An unavailable durable
receipt stops the stream with `503`; it does not start an executor.

The Server broker is a thin authenticated entry point. Engine owns the final
policy. Existing audit `timeScope=all`, bounded query/export behavior, database
retention, HAProxy, OIDC, and security overlays are retained. The govc bundle
updates only its x/text dependency to `0.41.0` for
[GO-2026-6629](https://pkg.go.dev/vuln/GO-2026-6629); its upstream Go source and
Go `1.27.0` toolchain remain unchanged.

Linux Node Agent `0.13.28` supervises the installed Host API `0.38.5` binary
instead of the old embedded backend. Host and Node producer archives are
installed through the existing authenticated config-item SHA-256 verification
path. A missing or incorrect Host version does not fall back to the old backend.
The existing full bootstrap image `v1.2.31` remains pinned; this does not claim
that existing hosts have been upgraded merely because Server contains the new
archives. Windows retains its separate `0.13.27` package and unsupported
delegation boundary.

## Exact component inputs

| Component | Clean source commit | Archive SHA-256 |
| --- | --- | --- |
| Engine `v0.183.334` (`cattle.jar`) | `863aed1f35e7a85d3686d5829d54dfe5c2c2f084` | `60b7ca446421f366882136a2bb276e508aa400d2961854b77d9a4574ee4dabfc` |
| Web Console `1.6.181` | `cf3d8b654e5ad8cd003ae10e62c57a3c14d79f95` | `6bc983093b3af4905d31e9a55be2cc73dfe5da915aba3e4d33f0f2df8251a6cf` |
| Websocket Proxy `0.23.15` | `97ad2a48658841709924efc21af93b82c825c800` | `3e9dabbfd466ccaa4427ed9cf02b2fb3793436f4d27a120dd7e2d73d9ba56bfc` |
| Host API `0.38.5` | `94ae7b598c67431ceaa8ee471c0f5b83e535d25c` | `9b414d1f7e803184698c5f20bd438a75713dde7f115aac385c1f898466d2b68c` |
| Linux Node Agent `0.13.28` | `4b20764cacc9496e810fe1b6687923a4bcc901b8` | `4a9f26a0ac9d0a53a6a7b0bb1dbde72b6a642e7474a19959ad87f81e46a85396` |
| vSphere CLI Bundle `0.55.3` | `5b1f9c91cdf2b5217b8d5019bbfb18bbc3e3294e` | `94553db031d141bf115594effae7ef0c28214e091d018db684467ee56f0c5120` |

Web Console's official archive is packed from the listed clean source,
including its test-fixture correction. All 123 packaged files, including
88 assets, are byte-identical to the previously tested production bundle;
this is a provenance-only repack, not a new runtime build.

Host package root: `94ae7b598c67431ceaa8ee471c0f5b83`.
Host binary SHA-256: `8a197dc440361febb750b7a181195a19b09f674d8cfd8bc69eae6b9f168616c1`.
Host `apply.sh` SHA-256: `8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f`.
Proxy binary SHA-256: `686fa62702315348e8698fa11e9647b423ab5c4331ff8236260726ef1c275b16`.
govc binary SHA-256: `0994912900534ddb60e0b70a1853046f0c7ab1aa374d241f12b2a397d1de84ae`.
Node package root: `4b20764cacc9496e810fe1b6687923a4`.
Node binary SHA-256: `a20b69fc484416e92f4102d2a18f77cc1650ed7d7c6fbbd9c371f5383e2596aa`.
Node `apply.sh` SHA-256: `dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9`.

The new Host producer package is verified and installed byte-for-byte;
the compatibility repair path is limited to the historical `0.38.4` package.
Candidate local inputs and later HTTPS release assets use the same five
archive checksums and formal Dockerfile. Missing identities, extra input files,
symlinks and checksum failures stop the build.

## Verification boundary

### Rollback safety

Direct image-only downgrade to Server `1.6.518` or another policy-unaware Engine
is unsupported. Such versions can interpret custom, closed or expired API Keys
as full access. Recover to a compatible version, or disable the external API
while revoking affected Keys and preserving revocation tombstones. Restoring a
database must not resurrect credentials revoked, narrowed or expired since the
backup. See the [API Key rollback safety guide](../upgrades/api-key-policy-rollback.md)
for the required recovery boundary.

### Artifact evidence

Source/recipe tests, exact producer package checks and Engine component tests
are distinct from the assembled Server image's startup, restart, feature/API
matrix and merged-runtime vulnerability scan. Publication requires those
artifact-specific checks; a source commit or inherited VEX statement is not
evidence that the new assembled image passed them.

The existing VEX assessments, vendor-pending findings and review deadlines
are retained without relaxing the release policy or claiming a new scan.
The published installation target remains `v1.6.518` until the candidate is
verified and separately published.
