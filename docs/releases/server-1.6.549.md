# Server v1.6.549 candidate

Prepared source only; no Server image or release has been published.
The Web Console 1.6.195 producer, archive, runtime SBOM and lock pins are bound
to its successful official producer evidence. Server publication and deployment
acceptance remain separate and have not been established.

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
reads that same file from the actual candidate rootfs, verifies its pinned
identity, and retains `web-console-runtime.cdx.json`, its SHA-256 sidecar and
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

## Security, publication and acceptance boundaries

The existing Server runtime CVE/VEX dispositions and scanner thresholds are
retained with the v1.6.549 release binding. Fresh source, image, security,
startup/restart, rootfs equivalence and release readback checks remain required;
the earlier v1.6.548 results are not a v1.6.549 release or deployment PASS.
The six-stage build and final one-layer publication process are preserved.

This change does not alter authentication, authorization, Catalog behavior,
database schema, host registration, named volumes or operator configuration.
No production deployment or new VM acceptance is claimed. Preserve the
verified v1.6.548 image and matching database/volume backup for rollback, and
follow the [upgrade guidance](../upgrades/README.md) for any later deployment.
