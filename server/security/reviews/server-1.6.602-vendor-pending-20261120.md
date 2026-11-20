# Server v1.6.602 vendor-pending review, 2026-11-20

The current database scan of the immutable published v1.6.602 SBOM reports 86
raw package/CVE occurrences. The original top-level Server VEX leaves 55;
the original Server VEX together with the already-shipped qualified bundle VEX
leaves 54. Restoring the one omitted exact custom p11-kit statement produces
the same 54-occurrence set. Raw findings remain preserved.

This review retains the previous 27 pending package/CVE occurrences and adds
27 across seven CVEs. All 54 have empty scanner FixedVersion and Ubuntu vendor
severity Medium (53) or Low (1). The release qualifier remains v1.6.602.

| Newly tracked CVE | Exact packages | Occurrences |
| --- | --- | ---: |
| [CVE-2026-105712](https://ubuntu.com/security/cves/CVE-2026-105712.json) | gpgv 2.4.8-4ubuntu3.1 | 1 |
| [CVE-2026-107778](https://ubuntu.com/security/cves/CVE-2026-107778.json) | libgssapi-krb5-2, libk5crypto3, libkrb5-3, libkrb5support0 1.22.1-2ubuntu4.1 | 4 |
| [CVE-2026-14739](https://ubuntu.com/security/cves/CVE-2026-14739.json) | libdbi-perl 1.647-1ubuntu0.26.04.4 | 1 |
| [CVE-2026-48962](https://ubuntu.com/security/cves/CVE-2026-48962.json) | libperl5.40, perl, perl-base, perl-modules-5.40 5.40.1-7ubuntu0.4 | 4 |
| [CVE-2026-76642](https://ubuntu.com/security/cves/CVE-2026-76642.json) | bsdutils 1:2.41.3-3ubuntu2.2; login 1:4.16.0-2+really2.41.3-3ubuntu2.2; libblkid1, libmount1, libsmartcols1, libuuid1, mount, util-linux 2.41.3-3ubuntu2.2 | 8 |
| [CVE-2026-77214](https://ubuntu.com/security/cves/CVE-2026-77214.json) | libexpat1 2.7.4-1ubuntu0.2 | 1 |
| [CVE-2026-78410](https://ubuntu.com/security/cves/CVE-2026-78410.json) | Same eight exact util-linux packages above | 8 |

All 20 pending CVEs were checked against live Canonical JSON for the matching
Resolute source package: nine are deferred and eleven needed, with no released
fixed version. Each tracker entry records the current official URL, response
SHA256, verification time and review deadline 2026-11-27. Official Resolute and
Resolute-updates package listings offer no newer applicable fixed package.
Other Ubuntu releases' USNs and upstream fixed versions do not establish a
released compatible Resolute fix. Upstream CVSS scores remain disclosed,
including DBI's 9.8; Ubuntu vendor priority controls this existing pending policy.

## Already-qualified p11-kit correction

The [published v1.6.602 backport evidence](https://github.com/PastureStack/server/releases/download/v1.6.602/ubuntu-backports-evidence.tar)
already contains a fixed statement for CVE-2026-13757 and the exact custom
libp11-kit0 0.26.2-2+pasturestack.1 PURL. Its qualified native run 40121338859
records 1081 PASS, zero FAIL/ERROR/SKIP. The qualified source includes upstream
commit 0eedd4ddd7c924f9cbb4ac496b3fda699435c3cf. The top-level statement restores
only the installed custom libp11-kit0 product. The older official 0.26.2-2
not_affected statement remains separate and unchanged.

The immutable bundle image is
`ghcr.io/pasturestack/ubuntu-security-backports@sha256:45d6b507b63a18459ae5cf76afd4d9731f8ef43b9c40e4c3dbb01899e1752b19`.
The image manifest and both layer digests were verified directly. Its
`payload/libp11-kit0.json` SHA256
`85e82706689f1c6860bc3aa83e51f77440883790f4a32977e64eaa4236b31a64`
matches the shipped bundle manifest. Actual QA port 8080 package readback is
0.26.2-2+pasturestack.1:amd64; the resolved installed ELF
`/usr/lib/x86_64-linux-gnu/libp11-kit.so.0.4.8` SHA256
`faaf9102a495426ad38ba0ba30445cca7c9d964193ad190a2aff716381f25438`
matches that qualified payload. This restores existing qualification metadata;
it introduces no newly asserted fix, broader product waiver or runtime change.

## Verification boundary

Trivy 0.76.2 rescanned the published CycloneDX SBOM with the current local
database and both native --vex inputs. The source VEX yields exactly the same
54 occurrences as the two original immutable VEX documents. The sole difference
from the former top-level-only 55 is the qualified custom libp11-kit0 occurrence.
This is an SBOM rescan, not a new full rootfs/secret scan or a new publication.

The existing native exact-set validator accepts the resulting 54 and rejects
the former 55, missing rows, untracked rows, HIGH/CRITICAL, available fixes,
retired findings and expired reviews. TSV validation normalizes only the SBOM
report's target label to the original declared `/rootfs (ubuntu 26.04)` label;
package, version, severity, CVE and FixedVersion come from scanner output.
Focused VEX regression cases reject broader products, wrong versions/statuses,
missing custom qualification, duplicate products and overlapping legacy scope.
Existing publication workflow and pending validator policy are unchanged.

Input SBOM SHA256: `05b85f035266d99c4bbca068bb3f78fdf42166c4b19bc1e97628dc79b05f09d2`.
Preserved raw 86-occurrence report SHA256:
`33d784b9f80951d07e3fcd68a6c1ff0835260e23b022f4d3077d7b456f86cd14`.
Updated source-VEX effective 54-occurrence report SHA256:
`8bd701639b3a1745292258800757a441be795f0ff73fa4696ddcdc217026d142`.
