# PastureStack Server v1.6.425

This release aligns both public API schema generations with the established
container hardware contract and fixes the shared Web Console action-menu
lifecycle.

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

## Compatibility and release boundary

The database schema, ports, persistent volumes, authentication model,
host-agent protocol, and unrelated UI/table behavior are unchanged from
`v1.6.424`. Publication still requires the Server source gates, clean-image
build, restart smoke, merged-rootfs scan, SBOM, provenance and attestations.
Production acceptance additionally verifies both API schema generations and
the account-edit interaction on the real 8080 deployment while retaining
`v1.6.424` as the rollback point.
