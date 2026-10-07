# Server v1.6.518

Status: officially published; immutable artifact and scoped isolated-QA
deployment/read-only checks verified.

Immutable image:
`ghcr.io/pasturestack/server:v1.6.518@sha256:4040180d74574b1e72710decb09874d29a32e45808658156753700b548c8647e`.
Signed Server source: `7607f4d4cd64b3c99b8ed9faa809109ad49cf893`.
Image config digest: `sha256:2fb8eb0bce97f1351ffd513a826da1dcb3c0434e9ffeda1e04d424029d7b4564`
(not the registry manifest digest).

## Scope

Pins published Catalog `v0.3.13` source commit
`b6b658888fce50d3ec217eb4eba0f26ab0113baf`, with Network Services revision `10` / template
`v0.3.8` referencing Network Plugin Manager `v0.8.22`. The manager reconciles
the CNI configuration supplied by Metadata during a managed infrastructure
upgrade. A historical `10-rancher.conf` can otherwise remain active after
Metadata switches to `10-pasturestack.conf`, causing both configurations to
be executed.

The manager validates and serializes all desired configurations
before changing active files. It installs each desired file atomically, then
retires the unrequested historical file only when its network name, bridge
type and IPAM type exactly match the known legacy triplet:
`rancher-cni-network`, `rancher-bridge`, `rancher-cni-ipam`. The requested native
counterpart must match `pasturestack-cni-network`, `pasture-bridge`,
`metadata-cni-ipam`.

The retired file retains its original contents as
`10-rancher.conf.pasturestack-retired`, outside the active `.conf` / `.json`
set. The reverse transition to the exact legacy Metadata contract retires
the known native counterpart as `10-pasturestack.conf.pasturestack-retired`.
Legacy Metadata remains supported. Unrelated administrator configurations
are preserved; malformed or ambiguous old configurations, non-regular files
and conflicting backup contents fail reconciliation explicitly.

Atomicity applies to each file replacement, not to the complete configuration
bundle. Desired files are installed sequentially, and retirement follows
successful desired-file writes. A failure during a multi-file update can
leave earlier replacements in place for the next reconciliation attempt.
The recoverable retired copy does not make the whole update transactional.

The audit broker accepts explicit `timeScope=all` to query all retained audit
log time without the implicit 24-hour lower bound. Requests without that
marker or explicit dates retain the default 24-hour window. Explicit dates
remain authoritative even with `timeScope=all`: both boundaries are required,
the interval remains `[from,to)`, and the maximum explicit range is 366 days.
Unknown time scopes return HTTP 400 with `invalid_time_scope`.

Query and export use the same token-owner authorization, environment and
record filters. The 20,000-row scan cap and 10,000-row export cap remain in
place; database retention is unchanged. JSON and XLSX exports describe the
all-retained scope without inventing date boundaries. Web Console `1.6.180`
forwards the all-time marker through both the audit query and export routes;
explicit date filters remain intact.

Server assembly packages the reviewed Catalog source pin and release
identity. Orchestration Engine `v0.183.333`, Catalog Service `0.20.12`,
Authentication Service `0.4.42`, HAProxy and OIDC contracts remain unchanged.
The Web Console pin is `1.6.180`, source
`637604b38401b19d2c9ef73d5729d356bb80c8e6`, with archive
`web-console-1.6.180.tar.gz` SHA-256
`a367bd6907281298a8e2bf0f3ad0444083db06062f3a1521db573cc5606d274e`.
Four build stages and the existing single final runtime layer publication flow
are retained.

## Verification

[Official publication run 37566647090](https://github.com/PastureStack/server/actions/runs/37566647090)
completed successfully at the signed Server source above. It passed source
gates, exact component verification, artifact scan/SBOM, disposable startup
and restart (11/7 bounded probes), and public release readback. Independent
readback verified the public asset SHA-256 checksums, SBOM OCI identity,
single runtime layer and official fixed FreeType package.

The final scan has 53 raw findings, 51 retained VEX statements, and nine
vendor-pending Medium package findings covering five CVEs. Untracked,
Critical/High, available-fix and secret findings are zero. Existing
vendor-pending findings and review deadlines are not reset; this is not a
zero-CVE claim.

Catalog PR #17 was normally merged, and
[Catalog CI 37564407383](https://github.com/PastureStack/catalog-templates/actions/runs/37564407383)
passed at the pinned source. The fixed Web source passed
[Validate 37564108185](https://github.com/PastureStack/web-console/actions/runs/37564108185);
the official numeric [Web Console 1.6.180 release](https://github.com/PastureStack/web-console/releases/tag/1.6.180)
contains the pinned archive.

## Publication blocker repaired

The first official publication attempt,
[run 37565304067](https://github.com/PastureStack/server/actions/runs/37565304067),
stopped before publishing any Server `v1.6.518` tag or image. Its artifact gate
found `CVE-2026-95512` in inherited `libfreetype6` `2.14.2+dfsg-1ubuntu0.1`, with
an official available fix. [Ubuntu USN-8881-1](https://ubuntu.com/security/notices/USN-8881-1)
identifies `2.14.2+dfsg-1ubuntu0.2` as the fixed Ubuntu 26.04 package.

The release adds only that official amd64 deb, SHA-256
`6d7d532b7d0c57639deb3b228f1f0d786cf5305d613ef7df9ba76c776a0f8373`,
to the existing security-package builder. The archive identity, installed dpkg
version and actual shared-library bytes/linkage are checked. The existing
`20261002T000000Z` snapshot, curl/OpenSSL/DBI pins, VEX/pending policy and review
deadlines remain unchanged. The subsequent successful official build and
artifact scan verified this repair without a security-gate exception.

## Acceptance and upgrade boundaries

Separate isolated-QA deployment and read-only checks verified the exact
published image, first startup and one restart with HTTP 200/pong. Runtime
configuration, mounts, environment overrides and database counts were
preserved, with the previous image and backup retained for rollback. Host
receipts remain local; internal endpoints and QA details are not published.

Publication and these scoped checks do not establish complete infrastructure,
resource/role/hardware or functional-matrix acceptance. Existing historical
HOLDs and incomplete coverage remain unchanged.

Operator Catalog overrides and deployed
infrastructure stacks are not automatically upgraded by changing the image
defaults. VEX and vendor-pending metadata change only their Server release
identity; vulnerability decisions and existing review deadlines are retained.

README and Compose install examples use the actually published numeric tag
`v1.6.518`, without a digest or descriptive suffix. Immutable identities remain
in release/compatibility records. Existing volumes, environment overrides and
prior rollback evidence must be preserved; see [the upgrade guide](../upgrades/README.md).
