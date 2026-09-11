# PastureStack Server v1.6.427

This release completes the frozen `/v1` service hardware schema and retains
the Web Console resource-action menu lifecycle fix shipped in `v1.6.426`.

## Operator-visible result

- Every frozen `/v1` role schema now exposes `runtime`, `shmSize`, and typed
  `deviceRequests` on both direct `container` resources and service
  `launchConfig` payloads. `/v2-beta` keeps the same contract.
- Schema validation compares field type plus create and update authorization
  between `container` and `launchConfig`, and verifies the nested GPU request
  fields for all 12 frozen role snapshots.
- Service create and upgrade requests continue through the established shared
  memory, runtime, GPU/device, init, CPU, PID, tmpfs, sysctl, ulimit, host
  placement, and Docker conversion path. This release changes schema discovery,
  not that business-logic path.
- Selecting Edit from an account or resource row closes the shared action menu
  before the modal is opened, so the menu cannot remain above the form.

## Reviewed release inputs

- Orchestration Engine `0.183.297`, GitHub-verified main commit
  `9beb27e228d65dc89166f681b81478addbcfc887`; release artifact
  `orchestration-engine-0.183.297.jar` SHA-256
  `22d126442aab342f6f94d88fc3706c50008d1e437ce86cea8f32dda81c896fb7`.
  Workflow `34585836168` passed the merged-main build, artifact scan, Dapper
  scan, and frozen v1 schema test.
- Web Console `1.6.115`, GitHub-verified main commit
  `25dd612a380a56b5af002fbda96b8427cc6dc6a9`; release artifact
  `web-console-1.6.115.tar.gz` SHA-256
  `a89ba273de9369665cfb223722b4bc24e692221ba66f8d489aa8a862aeed5599`.
  Workflow `34577533792` passed the pinned Node 24 test and build pipeline.

## Security evidence and vendor-pending boundary

The merged-rootfs policy remains fail closed for every Critical or High
finding, every vendor-fixed finding, every unlisted or changed occurrence, an
expired review record, and every detected secret. Ubuntu currently publishes
no fixed package for the seven tracked Medium curl advisories, represented by
21 exact occurrences across `curl`, `libcurl3t64-gnutls`, and `libcurl4t64`.
They remain recorded in `server/security/vendor-pending.json`; the release does
not misrepresent them as fixed or not affected.

The inherited base retains curl and libcurl `8.18.0-1ubuntu2.5` for
`CVE-2026-8932`, glibc `2.43-2ubuntu2.4`, and GNU coreutils `uniq` upstream
commit `d64e35a8a4c0e4608321433e0d84d917e4e36371`. Ubuntu still marks
`CVE-2026-18374` as needing evaluation for Resolute. The OpenSSL closure for
`CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910` are inherited unchanged; unmatched vulnerability at any severity remains a release blocker.

Tracked vendor-pending CVEs: `CVE-2026-13608`, `CVE-2026-18924`,
`CVE-2026-19931`, `CVE-2026-80229`, `CVE-2026-80230`, `CVE-2026-80255`, and
`CVE-2026-82209`.

## Compatibility and acceptance boundary

The database schema, ports, persistent volumes, authentication model,
host-agent protocol, and unrelated UI/table behavior are unchanged from
`v1.6.426`. Publication requires the focused source gate, exact dependency
hashes, clean-image build, initial and restart smoke, merged-rootfs scan,
artifact SBOM, provenance, and attestations. Deployment acceptance verifies a
fresh `/v1/schemas/launchconfig` response, the corresponding `/v2-beta`
contract, the account-edit menu/modal interaction, and `/ping` before and after
one real container restart while retaining one tested rollback image.
