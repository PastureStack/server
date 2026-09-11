# PastureStack Server v1.6.426

This release aligns both public API schema generations with the established
container hardware contract, fixes the shared Web Console action-menu
lifecycle, and records newly disclosed vendor-pending operating-system
findings without inventing unavailable package fixes.

## Operator-visible result

- `/v1` now exposes `runtime` and typed `deviceRequests` anywhere its frozen
  role schema already exposes `shmSize`; `/v2-beta` remains unchanged.
- The nested GPU request schema preserves role-specific create and update
  permissions for driver, count, device IDs, capabilities, and options.
- Service create and upgrade requests continue through the same validated
  hardware-to-Docker conversion path for shared memory, runtime, GPU, device,
  init, CPU, PID, tmpfs, sysctl, ulimit, and host-placement settings.
- Selecting an account or resource action closes the global row menu before
  opening the edit modal, so the menu cannot remain layered above the form.

## Reviewed release inputs

- Orchestration Engine `0.183.296`, GitHub-verified main commit
  `3f857fbdb8f402e152f4c1111c81ecb7e27c43af`; artifact
  `orchestration-engine-0.183.296.jar` SHA-256
  `3a2db2749994011fd404077bde8242f7ba35027545a5f762a5da7fac0950bf53`.
  Workflow `34577535514` passed the full Maven build, artifact and Dapper
  scans, and the zero applicable Critical/High gate.
- Web Console `1.6.115`, GitHub-verified main commit
  `25dd612a380a56b5af002fbda96b8427cc6dc6a9`; artifact
  `web-console-1.6.115.tar.gz` SHA-256
  `a89ba273de9369665cfb223722b4bc24e692221ba66f8d489aa8a862aeed5599`.
  Workflow `34577533792` passed the pinned Node 24 test/build pipeline and
  produced two byte-identical release candidates.

## Vendor-pending security findings

The 2026-09-11 merged-rootfs scan reports seven Medium curl advisories across
`curl`, `libcurl3t64-gnutls`, and `libcurl4t64`, for 21 exact occurrences.
Canonical currently marks all seven Ubuntu 26.04 records as `Needs evaluation`
and publishes no fixed package version. They are recorded in
`server/security/vendor-pending.json` with their exact package version,
severity, official Ubuntu URL, scan target, and a 2026-09-18 mandatory review
date.

The release gate still fails for any Critical or High finding, any finding
with a vendor fix available, any unlisted or changed occurrence, an expired
review record, or any detected secret. The non-empty unresolved TSV and the
vendor-pending tracker are both retained in the release evidence and SBOM
workflow; this release does not claim that these findings are fixed or not
affected.

Tracked CVEs: `CVE-2026-13608`, `CVE-2026-18924`, `CVE-2026-19931`,
`CVE-2026-80229`, `CVE-2026-80230`, `CVE-2026-80255`, and
`CVE-2026-82209`.

## Compatibility and release boundary

The database schema, ports, persistent volumes, authentication model,
host-agent protocol, and unrelated UI/table behavior are unchanged from
`v1.6.424`. Publication requires the Server source gates, clean-image build,
initial and restart smoke, merged-rootfs scan, artifact SBOM, provenance and
attestations. Production acceptance additionally verifies both API schema
generations and the account-edit interaction on the real 8080 deployment while
retaining `v1.6.424` as the rollback point.
