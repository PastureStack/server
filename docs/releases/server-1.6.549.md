# Server v1.6.549

Published from producer `ed3f334f2c371a3038ca5fe3e63c6581c8c1aabf` using the
image and evidence produced by
[run 40096562378](https://github.com/PastureStack/server/actions/runs/40096562378).
All 34 immutable release assets passed anonymous SHA-256 readback. Image
provenance and SBOM attestations were independently verified against the exact
source, workflow and image identity.

Published image identity:
`ghcr.io/pasturestack/server:v1.6.549@sha256:dae1c8e490e012a030855d73d7af0bfcd85f4c9d9bf94148664d492c35e5684c`.
The distinct OCI config is
`sha256:ba535844f1b3e37ad3be74c7037ef7be90cd186f7058dad9a421de4d95f09a24`.
The linux/amd64 image has one runtime layer. Installation examples use only
the numeric `ghcr.io/pasturestack/server:v1.6.549` tag.

## Attachment recovery

The original workflow conclusion remains `failure`. Its source, build,
rootfs-equivalence, security, startup/restart, image push and two attestation
steps passed; the final release upload failed with HTTP 400 `Bad Content-Length`
when sending the valid zero-byte browser findings TSV.

The preserved official CI artifact and its checksums were verified before
completing the release. Its empty TSV was losslessly encoded as deterministic
gzip, the checksum manifest was regenerated for that transport filename, and
`publication-recovery.json` was included as the 34th public asset. The
[recovery receipt](https://github.com/PastureStack/server/releases/download/v1.6.549/publication-recovery.json)
records the original job, artifact hash, successful steps, exact image digest
and byte-identical decompression. The image was not rebuilt, its tag was not
overwritten, and no security gate was bypassed. The permanent upload fix is
[PR353](https://github.com/PastureStack/server/pull/353).

## Verified component inputs

- Web Console `1.6.195` is consumed as an exact static archive and a separate
  `web-console-1.6.195-runtime.cdx.json` release asset. The build verifies both
  checksums and binds the SBOM to the archive name, archive SHA-256, source
  commit, version and package-lock SHA-256.
  Producer `f905bc12daae18d98a6ac65942625562fff2a424` passed
  [run 40086505425](https://github.com/PastureStack/web-console/actions/runs/40086505425).
  Archive SHA-256: `26cbe1f3c057722c6682c43316021687508b7d9dd58c28c32713512d75238bb3`.
  Runtime SBOM SHA-256: `ca31669f58aa342cd346e1d33ec7061d65f9b84d6a3afcbd132e09361425a88a`.
  Lock SHA-256: `ae862be4519751895f74e552f036906d64be8371fdbbc6379c16e52518f9ee22`.
  The formal 216-component runtime SBOM passed the Server consumer's archive,
  source, version, lock and phase identity checks with `coverage=incomplete` retained.
- Orchestration Engine `v0.183.354` retains source
  `dc5a8d7bc44131f609f72a6504483b692d47ce16` and JAR SHA-256
  `f4889bfb8759a7664f07524bb129d0cda19f35604a06c877b6ca7033246df6fa`.
- Catalog `v0.3.16` retains source `070e08d8f85ffc2779a0f97eb4e356c857812d34`,
  Network Plugin Manager `v0.8.25` and Metadata Service `v0.10.6`.
  The other Server v1.6.548 runtime component coordinates are unchanged.

## Browser SBOM delivery

The original browser runtime SBOM is stored at
`/usr/share/licenses/pasturestack/web-console/runtime.cdx.json`. The publisher
read that same file from the actual image rootfs, verified its pinned
identity, and retained `web-console-runtime.cdx.json`, its SHA-256 sidecar and
`web-console-sbom-identity.txt` as separate Server release assets.
No normalization or merge into the OS SBOM changes the producer's bytes.

The publisher performs independent component vulnerability lookup on this runtime
SBOM using the same pinned Trivy image and freshly downloaded vulnerability DB.
Raw and effective reports retain identical bytes because no browser exception or
OS VEX is applied. Browser findings retain a distinct target in the existing
exact-set release gate: HIGH/CRITICAL, available fixes and every unregistered
finding block publication. The existing Ubuntu no-fix ledger is not expanded.
The raw/effective scan reports, coverage report and browser findings table are
included in the release checksum manifest.

The published scan recognized all 87 npm PURLs and reported zero browser
findings. Six source snapshots remain unsupported by ecosystem lookup:
Bootstrap 3 presentation compatibility, Bootswatch Cosmo, PastureStack icons,
Lato webfonts, the frozen noVNC bundle and jQuery.PositionCalculator. Their
references and source hashes remain itemized in the published
[coverage report](https://github.com/PastureStack/server/releases/download/v1.6.549/web-console-runtime-scan-coverage.json).
Raw and effective report SHA-256 are both
`8f35d4bd158998acc75d48ebb9c4c32e6fcc3b9e657b590ff177931022767b76`.
The scan used Trivy `0.74.0`; its DB was fresh at scan time with SHA-256
`9f227eaae45c4fa4d8b3e4baea563e4aca69de04c7fef933e469cfb66b8ccfa0`.
The published findings report is `web-console-runtime-vulnerabilities.tsv.gz`;
decompression yields the original zero-row TSV.

The coverage report binds recognized npm PURLs to scanner package inventory,
records the scanner and exact DB identity, and lists unsupported snapshots with
their names, versions, references and provenance hashes. Missing npm lookup
coverage blocks publication. An unsupported snapshot does not receive a
not-affected/VEX disposition and a zero scanner result does not establish zero
risk or complete browser coverage.

The runtime inventory preserves `coverage=incomplete`, including its documented
opaque vendor, sentinel and Sass tracing limitations. Build dependencies,
package-lock-only entries and host SDK inventories are not promoted into the
browser runtime inventory. The source-to-artifact evidence and disclosed
unknowns determine scope; SBOM presence does not prove complete detection.

## Build-host Ruby tracking

The earlier Web194, Engine354 and Server548 jobs used a GitHub-hosted image
whose official SBOM includes Ubuntu Ruby and older cached/portable Ruby SDKs.
Their explicit use was not observed in those producer logs. Available Ruby
Onigmo fixes and these host-only inventories remain tracked separately from
product runtime findings; Ubuntu backport status is unverified. This evidence
does not establish a Ruby regexp-from-attacker path in the Node/Java/Go flows.
An absent scanner CVE is not a remediation result.

The Web Console producer captures actual build-host inventory without installing an
otherwise unused Ruby toolchain. Server intermediate-stage package coverage
gaps are retained; no unrelated base image rebuild is claimed as verification.
The Web195 build runs in its pinned Node container. Its before/after inventory
and absence gates found no Ruby interpreter, libruby, RubyGems or Onigmo in that
container. This result does not describe the enclosing GitHub runner or every
Server intermediate stage.

## Security and acceptance boundaries

The complete runtime gate retains 51 raw findings and, after exact existing
VEX dispositions, 29 officially unfixed LOW/MEDIUM occurrences across 18 CVEs.
HIGH/CRITICAL, fixed-available, unregistered findings and detected secrets are
zero. These dispositions do not claim zero vulnerabilities or complete browser
coverage. The six-stage build and final one-layer publication process are
preserved.

The official image passed startup and restart checks with HTTP 200/pong and
the public/private API contract before publication. These CI checks are
separate from the scoped deployment acceptance below.

## Scoped 8080 acceptance and rollback

The exact published digest passed the 8080 cutover. Environment variables,
HostConfig, all three data volumes, the existing Docker socket bind and AppArmor
were preserved. Before the upgrade,
all 104 InnoDB tables were backed up in one transaction; the backup SHA-256
and gzip integrity were verified. The v1.6.548 rollback container and matching
backup remain available.

Readback from the actual running container verified Server `v1.6.549`,
Web Console `1.6.195`, its exact producer/archive/lock identity and the original
runtime SBOM SHA-256 `ca31669f58aa342cd346e1d33ec7061d65f9b84d6a3afcbd132e09361425a88a`.
Its phase remained `runtime` and coverage remained `incomplete`.

Chrome `155.0.8059.41` passed OIDC login with IdP and platform TOTP, seven
authenticated JSON API reads returning HTTP200, three active Hosts and Agents,
session-preserving refresh and one received WebSocket frame. The audit read
returned ten retained records using a legitimate 24-hour window. The successful
pass recorded zero browser errors, HTTP errors, request failures and passive
DELETE requests.

Two earlier attempts remain in the evidence and are not product failures or
acceptance PASS: the wrapper initially omitted an existing fixture secret,
and a one-hour audit query had no new write records during the read-only smoke.
The final query read retained 24-hour history; it did not manufacture a new
audit event or change a product contract.

No additional manual Server restart was performed for this SBOM/build scope;
the publisher's fresh-candidate startup/restart checks remain the restart
evidence. The full permission matrix, unchanged VM configurations and unrelated
functional areas were not rerun. This is scoped acceptance, not a complete
feature matrix or a production deployment.

This change does not alter authentication, authorization, Catalog behavior,
database schema, host registration, named volumes or operator configuration.
Preserve the verified v1.6.548 image and matching database/volume backup for
rollback, and follow the [upgrade guidance](../upgrades/README.md) for later
deployments. After a database migration, selecting an older image alone may
not be a safe rollback.
