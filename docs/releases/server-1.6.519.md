# Server v1.6.519

Status: unpublished candidate. No registry digest or new artifact-scan result
is claimed by this source document.

## Scope

Restricted and expiring API Keys use the same Engine authorization boundary
as full keys, intersected with the owner's live role and environment access.
Operation decisions and actual request/process outcomes are durably audited
without credential secrets or request payloads. Key-scoped audit queries
recheck the viewer's current authorization before filtering and pagination.
Transparent resource-manager filters preserve guarded collection SQL scope
before pagination; unknown or replaced query paths remain denied. During a
service upgrade, persisted live `upgrade=true, managed=false` relationships
retain their same-account ancestry while old instances are replaced. Ordinary
unmanaged, removed or contradictory relationships do not grant that ancestry.
The Key query uses the viewer's personal context and Engine-proven live project
contexts, then deduplicates and scopes events within a shared scan bound.
An incomplete live project-authority page is rejected without partial results.
Delegated terminal/log access rechecks current authorization; terminal outcomes
are accepted only from the authenticated host's agent, with durable deduplication.
An API Key stream cannot start against a backend without the verified audit
capability. That blocked handshake is recorded as `FAILED`, phase `handshake`,
HTTP `503`; it is not an executor completion. Cookie-based access is unchanged.
A signed ticket used for a different stream route is rejected and durably
recorded as `DENY`/`FAILED`, phase `handshake`, HTTP `403`. An unavailable durable
receipt stops the stream with `503`; it does not start an executor.

An expired, signed Key-traced ticket is rejected before backend or persistent
session creation. Its verified trace and authenticated host proof are audit-only:
durable acceptance records `DENY`/`FAILED`, phase `handshake`, and returns
`ApiKeyExpired` (`401`). Signature-only parsing never restores authorization.
Missing proof or durable acceptance returns `AuditUnavailable` (`503`), without
execution or a claim that the denial was durably recorded. The
[API Key guide](../api-keys.md) describes raw policy-input validation, sensitive
export classification and persisted container audit identity.

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

The Linux Host completion spool validates each directory descriptor before
creating descendants. Unsafe aliases, writable or foreign-owned parents fail
without creating directories through them. Search-only trusted ancestors and
owner-only permission repair remain supported without changing parent modes.

## Exact component inputs

| Component | Clean source commit | Archive SHA-256 |
| --- | --- | --- |
| Engine `v0.183.334` (`cattle.jar`) | `c709e19933beb47ae7b530b07aaa1046a8a22564` | `aec22db40e2a7e4a4b16003c5a931ed16a285170c15ad5db3d7a37181146f333` |
| Web Console `1.6.181` | `c3536a0560cdc1b286b275c39fb1cd04a14ed9b0` | `6b22e2291b0d4c1d19061e65eb84a84d5f8ae2c22b1eb5b6b1d24b1f3a46d08b` |
| Websocket Proxy `0.23.15` | `a968ae2887a9b6f190c0552e11c9bb54da72a76b` | `159f6bbaf84c230b99c97d59f171e12444ff203dd183a338e0b7d491711a88d4` |
| Host API `0.38.5` | `ea295d1ffe4064bd3ac4afd8ea0f751d27aa4285` | `718e952852b4bc0342e62481ae60673a6b8e76f72b48e741a63a3145724bf1ce` |
| Linux Node Agent `0.13.28` | `4b20764cacc9496e810fe1b6687923a4bcc901b8` | `4a9f26a0ac9d0a53a6a7b0bb1dbde72b6a642e7474a19959ad87f81e46a85396` |
| vSphere CLI Bundle `0.55.3` | `5b1f9c91cdf2b5217b8d5019bbfb18bbc3e3294e` | `94553db031d141bf115594effae7ef0c28214e091d018db684467ee56f0c5120` |

Web Console is built and officially packed from the listed source. Its custom
scope editor uses stable rule identity and defers capability publication until
after rendering. Source/render regression tests are distinct from the required
native browser acceptance of this new production bundle.
The final package changes only the two generated range-limit translations
relative to the rendered build; business JavaScript bytes are unchanged.

Host package root: `ea295d1ffe4064bd3ac4afd8ea0f751d`.
Host binary SHA-256: `30ab71f83213858e6cc727a8b6be22ac9d390c97fdc7a5f0ed96818a8715565f`.
Host `apply.sh` SHA-256: `8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f`.
Proxy binary SHA-256: `5ade6d24ff05abd7fdd29b5c4260a699d2bf1ccde17cfc9ebbcedb1c0ee36d6a`.
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
