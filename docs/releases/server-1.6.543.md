# Server v1.6.543

This release replaces only WebSocket Proxy `0.23.16` with the official immutable
`0.23.17` release. Engine `0.183.352` and all other component pins are retained.

## Official Server release

[Server v1.6.543](https://github.com/PastureStack/server/releases/tag/v1.6.543)
was built from source `a9559b6ae3c46955e9665a0ccce7358707480af7` by successful
[publisher39714403303](https://github.com/PastureStack/server/actions/runs/39714403303).
All 26 immutable release assets passed anonymous exact-set/checksum readback
without bypassing required checks. The linux/amd64 image has one runtime layer,
516,486,942 compressed bytes.

| Image identity | Value |
| --- | --- |
| Registry manifest | `sha256:d5664f64924c089ff67ba155cd5a1fc195f06a45ed71c855e9a558fb689240a3` |
| Distinct OCI config | `sha256:b8cdbdd45afc1d69c36bdd5f960218bad63b62f04d333cb0913c4873e6250b51` |

Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.543@sha256:d5664f64924c089ff67ba155cd5a1fc195f06a45ed71c855e9a558fb689240a3`.
Use the published numeric `v1.6.543` tag in the
[installation examples](../../README.md#quick-start).

The QA8080 upgrade and actual restart passed with matching source and image
identities. All three persistent volumes, runtime overrides and LB database
settings were preserved; a 542 rollback and backup were retained. This result
does not establish stream or complete native-matrix acceptance.

## Official Proxy bytes

The assembly consumes the original tested bytes from the immutable
[Proxy v0.23.17 release](https://github.com/PastureStack/websocket-proxy/releases/tag/v0.23.17),
not a Server-side component rebuild. Both official assets passed anonymous
HTTP 200 exact-byte/checksum readback with no required-check bypass.

| Input | Exact identity |
| --- | --- |
| Actual CI/archive/binary producer | `6fc9f6a2ee3c010b5376887b387a32f243240026` |
| Verified merged main and numeric tag target | `9eb4bed975db048cf41acedfd03a058da34dd992` |
| Equal producer/merged source tree | `9438d9508628ac660b1e118ccffe11ffc2b1bb43` |
| Required Security / CodeQL runs | `39711488379` / `39711486336`, both successful |
| Archive | `websocket-proxy-0.23.17-linux-amd64.tar.xz`, 2,892,452 bytes |
| Archive SHA256 | `7c252aa0724b6b3d59aa77bc59bb9bb2516faecc67594a6ed0966e14547afd9a` |
| Extracted `websocket-proxy` | 9,412,732 bytes; Go `1.27.3`, linux/amd64, CGO disabled |
| Binary SHA256 | `68e1385ffed804382c74a49bb647306aab2f43060b7912ac437581c876926494` |
| Formal anonymous-readback receipt SHA256 | `180dd5257e24eccff6ae0bf6d8148a28b72968bc3662b55ac28a8fddad31692a` |

The proxy retains authenticated backend JWT binding and the exact
`key-audit-v1` / `key-delegation-v1` protocol capabilities. Its implementation
version check accepts only canonical `0.38.x` patch >= 5, so the compatible
Host API `0.38.6` security patch is not rejected solely for differing from
`0.38.5`. Empty, duplicate, malformed, leading-zero, prerelease and unknown
major/minor versions remain rejected. This does not change business
authorization, Key scopes, expiry/revision checks or durable audit gates.

## Unchanged assembly and acceptance boundaries

Engine remains `0.183.352`, actual WAR producer
`70ba8cff544fcd5607f3054d30ac8b5cf09783d6`, JAR SHA256
`1f17603554f1ee3fb651c6570690cb2d7b8c2fa27de17ae260d0cc68b402d826`.
Every other component source/archive/binary pin and frozen schema is unchanged
from published 542. The 17 local component inputs, 26 release assets and four
active nested Go payload qualifications remain required; no extra payload is
introduced. Compose, all three persistent volumes, runtime overrides, LB
database settings, custom audit-directory and rollback protections are retained.

The final merged-rootfs-and-active-payloads security gate reports 73 raw findings
and 29 tracked unfixed LOW/MEDIUM package occurrences across 18 CVEs, review
2026-10-27. Untracked, HIGH/CRITICAL, fixed-available and secrets are zero.
The four nested Host/Node/CNI payloads retain separate actual-binary qualification,
raw scans and CycloneDX SBOM in `server-nested-payloads.json`. Only current release
identities in VEX and vendor tracking move to 543; statements, policies and
thresholds are unchanged. Tracking is not remediation or zero risk. Publication
and candidate startup/restart checks are not complete native-matrix acceptance.

Back up the database and preserve all three persistent volumes, runtime overrides,
LB database settings and the previous official image for rollback; do not restore
stale Key policies, patch deployed binaries or weaken MFA to apply the update.
