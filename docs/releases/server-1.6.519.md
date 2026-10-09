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
uses x/text `0.41.0` for
[GO-2026-6629](https://pkg.go.dev/vuln/GO-2026-6629); its upstream Go source and
Go producer toolchain is now pinned to `1.27.2`, as are the other active Go
component producers. Historical base-image provenance is not rewritten.

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
| Engine `v0.183.334` (`cattle.jar`) | `91f44685953f7cc72344a21cb47ca235c0bce53f` | `b0e3608b21ce405cdaf2f74699442b9420844384055f85acf88cfeb638600490` |
| Web Console `1.6.181` | `9f2869e08161db6550892039aea4ccf2c8a8016b` | `db50f1f4f413ccbc6d9b2c3337e1979fb5ed4688f86978b885a48f30af342ad1` |
| Catalog Service `0.20.13` | `4c39c73a8131ba06e9ff0aaec3b95cc27e049324` | `29626181cb8489b016e5975ffaddc00b2a32d290b1c0066e833d27fa7a5edf83` |
| Authentication Service `0.4.43` | `cae736f377019bd9743648a8e9aa469a0e21b5e0` | `e9218771af8dd68323c8c6fdab149c40a3ad02da9ff23f8aad6f0b2977740273` |
| Compose Executor `0.14.37` | `88e991e823f06d2334c07d5370595aae3c48ee99` | `5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81` |
| Host Provisioner `0.39.8` | `385e5b536c108f17fdfcdec84c01750a5be5ab1c` | `d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c` |
| Secret Delivery API `0.3.2` | `53060369b29946b1f1b62e5fabbcfc8778c55bb6` | `8a5e6da29db8f7b55ab3291b0270e843a5c15e67154fa075575d8b84f4bc0ae9` |
| Usage Telemetry Agent `0.4.2` | `40f9af7ca932fedacdb87e30b4ef1c60a4a7444e` | `5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8` |
| Webhook Automation Service `0.10.4` | `400118b893843d2a7d7c65cc70c3449d76c4a8d8` | `49c4579829a04e758045fae02a5a9fca12bb0ba3af0d5e979cf9eb97f23a88a9` |
| Websocket Proxy `0.23.15` | `1928f602b66443cdab40c8cdb450c811548d2749` | `4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a` |
| Host API `0.38.5` | `84754fe8bc79027d0c72f492923c47861aa74b99` | `ba111038695aa03a82c51d60944bbbdbbec30bb269051ba29fa21d46ada17179` |
| Linux Node Agent `0.13.28` | `bb4e057c089e5384bc9836b42db206326c690387` | `a16ae6be5fb72fa2ba38bd1076fd3b9e0536c48e70995ffa49d17b8063e2f8d0` |
| vSphere CLI Bundle `0.55.3` | `f48ab9fd9990132c85845fc162186a04f1e0418d` | `31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4` |

Web Console is built and officially packed from the listed source. Its custom
scope editor uses stable rule identity and defers capability publication until
after rendering. Source/render regression tests are distinct from the required
native browser acceptance of this new production bundle. Blacklist/whitelist
defaults support direct exception editing; draft and reviewed changes include
the same named resource-by-operation policy matrix. Unknown or contradictory
ancestry is not guessed as permission. The preview does not grant owner access.
All 123 official package files match the production build byte-for-byte.

Host package root: `84754fe8bc79027d0c72f492923c4786`.
Host binary SHA-256: `fda5080d6cfec0a4c1e9daf15b43cea2dce7ffb116c8292ff0f3547c8fb371f7`.
Host `apply.sh` SHA-256: `8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f`.
Proxy binary SHA-256: `9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa`.
govc binary SHA-256: `d3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990`.
Node package root: `bb4e057c089e5384bc9836b42db20632`.
Node binary SHA-256: `ce8342e10da07c50cc414b471cadc67db4dd390e6e2dcb632b30c542f658b021`.
Node `apply.sh` SHA-256: `dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9`.

The new Host producer package is verified and installed byte-for-byte;
the compatibility repair path is limited to the historical `0.38.4` package.
Candidate local inputs and later HTTPS release assets use the same thirteen
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
