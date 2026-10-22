# Server v1.6.543 prepared assembly

This source candidate replaces only WebSocket Proxy `0.23.16` with the
official immutable `0.23.17` release. Server `v1.6.543` is not yet published
or deployed.

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

Only current release identities in VEX and vendor tracking move to 543;
statements, findings, review dates, policies and thresholds are unchanged.
Normal required PR checks and official Server final-image build, scan, SBOM
and anonymous artifact readback are still necessary. No Server digest,
publisher run, deployment result or stream/full-matrix/native PASS is claimed.

README installation examples remain on the actual published numeric
`v1.6.542` until official 543 publication and readback. Back up the database
and preserve all three persistent volumes and the previous official image
for rollback; do not restore stale Key policies, patch deployed binaries or
weaken MFA to apply the update.
