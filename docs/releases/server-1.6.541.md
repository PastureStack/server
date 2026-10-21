# Server v1.6.541

Server `v1.6.541` updates the Windows per-host-subnet bundle and its final-image
qualification. Install only the official immutable release after its publication
checks succeed. The release's `published.txt`, `SHA256SUMS`, scan reports and
SBOM identify the actual image and artifacts; this document does not substitute
for those results or establish deployment and full native-matrix acceptance.

## Official publication readback

Source/image producer `b4bbc6807f83e2bcc1a7ba46c132e4259ff48e79` passed
[official workflow39691051968](https://github.com/PastureStack/server/actions/runs/39691051968),
including clean source gates, exact build/flattening, JDK runtime checks,
startup/restart, final security/SBOM gates and provenance/SBOM attestations.
All 26 immutable release assets passed anonymous exact-set, byte-count and
SHA256 readback without a required-check bypass.

- Root manifest: `sha256:05976db2df0c39e2df6e133f2b228da6273676d7b0e6c82172be89704b14aff4`.
- Distinct OCI config: `sha256:3edd57c76ece4fe7b2a478abea6a03fecf10c7a5d56fbc03a4bda77b5cf7c599`.
- Platform: linux/amd64; one runtime layer, 516,480,269 compressed bytes.
- Final merged-rootfs-and-active-payloads gate: 73 raw findings, 29 exact unfixed
  LOW/MEDIUM package rows across 18 CVEs, review 2026-10-27; zero untracked,
  HIGH/CRITICAL, fixed-available or secret findings. This tracking is not a
  remediation or zero-risk claim.
- `server-nested-payloads.json` SHA256
  `36b396598ec2ceb6d1f90d7336110117e7a01d376e490b2f3e2ae2c7a9f15ce4`
  qualifies four actual Go1.27.3 binaries: Host Linux, Node Linux/Windows and
  CNI Windows. Each positive `gobinary` scan has zero vulnerabilities/secrets;
  the CycloneDX1.7 nested SBOM has 128 components and zero vulnerabilities.
  Qualification executes no payload and performs no runtime writes.

Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.541@sha256:05976db2df0c39e2df6e133f2b228da6273676d7b0e6c82172be89704b14aff4`.

These publication facts do not replace deployment or native acceptance evidence.
Later source documentation does not replace the image producer, tag, or immutable
release assets, including the producer-time `release-notes.md` attachment.

## Scoped QA deployment and evidence carry

The QA upgrade to this exact published image and an actual restart passed.
All three persisted volumes, runtime overrides and LB database settings were
preserved, with the previous 540 image retained for rollback; company production
was not touched. Read-only comparison against the actual 540 baseline confirmed
eleven unchanged runtime/JAR files, 88 console assets and thirteen translation
files byte-for-byte.

The unchanged bytes support scoped carry of the recorded 540 pending-request
revocation, revision-shrink, expiry, Full and Legacy controls, plus an additional
v1 pending-revocation control with an unchanged complete Stack database row,
native v1 audit identity and denied HTTP403. Their owned cleanup and session
revocation were verified. These are subcase results, not a complete BE10 row,
OIDC matrix, full UI matrix or Windows-native networking certification.

## Change and exact producer bytes

The only component replacement from published Server540 is the active Windows
per-host-subnet bundle `0.2.4` -> `0.2.5`, fixing its Go compiler to `go1.27.3`.
It consumes the producer's original CI bytes; Server does not rebuild the component.

| Input | Exact identity |
| --- | --- |
| Original producer | `e102e0bb38d84b0a9cbf87e5458cf1bc74d01904` |
| Verified integration main | `188f53ae35adf54eca7f357750a210cb2ab6edb8` (whole tree equal) |
| Original CI | run `39686844960`, artifact `12385818486` |
| Windows ZIP SHA256 | `7237e83e96a64e7f3de64eb86bff9721c4e879c35cda9e9de1e4cb1ba225f298` |
| PE SHA256 | `3d0e5b3f32eacf88cde9a8700432b64ad157810a053e59ebffe82a924a18ee30` |
| Startup SHA256 | `f22b41f18d1733c037babed4d2e0474efeedc6017a96849d4309dd864f5f86d1` (unchanged) |
| Formal anonymous-readback receipt SHA256 | `afa2db0e0755c6bd3ee28e111937c521a6d84e6d71d563e99202cf4693000eaf` |

The established Windows ZIP layout is `rancher/`,
`rancher/per-host-subnet.exe`, `rancher/startup_per-host-subnet.ps1`.
The producer intentionally retains `-buildvcs=false`: the PE has no embedded
VCS metadata. Its provenance is the exact reviewed CI/source/tree/archive/PE
receipt, not a fabricated source or `dirty=false` field. Host/Node still require
their exact embedded producer and clean VCS metadata; this adds no fallback.

## Assembly, scans and upgrade boundary

Local component inputs become 17. The qualifier and Trivy must identify exactly
four inner Go binaries (Host Linux, Node Linux/Windows, CNI Windows). The nested
raw/SBOM/qualification remain in the existing envelope; public release assets
remain exactly 26. Severity policy and the tracked vendor-pending set are
unchanged; raw findings and SBOM are generated from the actual image, not reused
from 540. No new VEX suppression is added. Only VEX and
vendor-document release identities move to 541, without changing findings.
The six stages remain; the current final-stage recipe has 31 RUN/COPY/ADD
instructions, within the existing 32 limit. The official readback above establishes
the actual layering and image identity; it does not establish broader native acceptance.

The image sets `RC16_PER_HOST_SUBNET_VERSION=0.2.5` and both default/effective
`CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL` to
`/usr/share/cattle/artifacts/per-host-subnet-0.2.5-windows-amd64.zip`.
Build-only cleanup removes only the explicitly superseded CNI024 bundle after
checking active regular files, links and all references; unrelated packages,
VMs, running hosts, volumes and rollback images are not touched.
Already-installed Windows binaries are not silently replaced by a Server image
upgrade; use the existing explicit Windows upgrade path and validate native
networking separately. This cross-built Windows package is not a Windows-native
certification.

All other 540 component source/archive/binary pins are unchanged, including
Engine351 actual WAR producer `1befd83278618f9a5b7cdaf96522004dd89918ba` and JAR
`efd0e826364c551f782b281f081d53cadb48faa7d5c37c2f101e6f9c7d7f9ea6`.
The exact new-image comparison above establishes the stated unchanged-byte
carry scope; source equality alone is not final-image or full-matrix PASS.
