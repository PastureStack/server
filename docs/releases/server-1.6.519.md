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

The Server broker is a thin authenticated entry point. Engine owns the final
policy. Existing audit `timeScope=all`, bounded query/export behavior, database
retention, HAProxy, OIDC, security package pins and overlays are retained.

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
| Engine `v0.183.334` (`cattle.jar`) | `0cf30b0b4ffe9af1a8d1605384d457785a2d2191` | `2d96f88e6d6d72c152b84c6467f9d17b8f522ee6669fd00e1b4885bc3aac49e6` |
| Web Console `1.6.181` | `adfed6c46a0478634004d72f3748290c6f904abf` | `427424a8c2b956b415dc7daaaef8b89094130f04cd5d10f9a74a655907dc74d3` |
| Websocket Proxy `0.23.15` | `2ec921200724341af6bf1c9402aac6b10a37f19f` | `f7046347c1e8ae20b18ed068860773ff810a5180b6b9b191a8eba6fbc215670b` |
| Host API `0.38.5` | `94ae7b598c67431ceaa8ee471c0f5b83e535d25c` | `9b414d1f7e803184698c5f20bd438a75713dde7f115aac385c1f898466d2b68c` |
| Linux Node Agent `0.13.28` | `4b20764cacc9496e810fe1b6687923a4bcc901b8` | `4a9f26a0ac9d0a53a6a7b0bb1dbde72b6a642e7474a19959ad87f81e46a85396` |

Host package root: `94ae7b598c67431ceaa8ee471c0f5b83`.
Host binary SHA-256: `8a197dc440361febb750b7a181195a19b09f674d8cfd8bc69eae6b9f168616c1`.
Host `apply.sh` SHA-256: `8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f`.
Proxy binary SHA-256: `796241c34a0de6542c93d203b73bf6f6be397643c5b54ee9eae46cd23e445c67`.
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
