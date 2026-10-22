# Server v1.6.544

This document describes the 544 assembly. Source changes alone are not publication
proof; official release assets and `published.txt` identify the actual Server
source and distinct registry manifest and OCI config digests.

## Official component bytes

The assembly consumes the original tested Linux bytes from
[Host API v0.38.7](https://github.com/PastureStack/host-api/releases/tag/v0.38.7)
and the original tested Linux and Windows packages from
[Node Agent v0.13.31](https://github.com/PastureStack/node-agent/releases/tag/v0.13.31).
Their immutable assets passed anonymous exact-byte/checksum readback without a
required-check bypass. Server assembly does not rebuild these components.

| Component | Actual CI/binary producer | Archive SHA256 |
| --- | --- | --- |
| Host API 0.38.7 | `cd2a8d2b5e37f1b79a4b487760db5f3f7b3f818b` | `f0e0033da7661d1444b73e2dc43f8b5c5dad6c9169ff2d19c1dcb6aa1c4435d9` |
| Node Agent 0.13.31 Linux | `68ae58d886621540208b98378ed517b3525244e0` | `d12da35517448fd26467ee71249976b224da8d07c9dd9feec7c3e49d2977df62` |
| Node Agent 0.13.31 Windows | `68ae58d886621540208b98378ed517b3525244e0` | `5b5e4610200139e89d962e2f10b6961d85ca2972a86cc4d4ddddbb8b600115ae` |

Host API preserves confirmed scoped authorization loss when a transport
disconnect races its authorization watcher. Before reporting an eligible
cancellation it can recheck the same signed grant within the existing total
report budget; this does not postpone closing the stream. Network or server
failure is not proof of revocation. Genuine completed EOF and backend failures,
ordinary JWT behavior and the single immutable terminal record remain preserved.
The final reason records authorization at finalization, not the first watcher.

Node Agent requires exactly Host API `0.38.7`, with no version fallback. Both
platform binaries retain Go `1.27.3`, CGO disabled, exact producer revision and
`vcs.modified=false`. Windows package qualification is not Windows-native
acceptance. The `key-audit-v1` and `key-delegation-v1` protocols are unchanged;
Proxy `0.23.17` needs no additional patch.

## Preserved assembly and upgrade contracts

Engine `0.183.352`, Web Console `1.6.192`, CNI `0.2.5`, CLI `0.6.19`, LB
`0.9.32` and all remaining component pins and frozen schemas are unchanged.
The 17 local inputs, 26 release assets, four actual nested Go qualifications,
independent nested scans/SBOM, separate JDK stage and one runtime layer remain
required. VEX and vendor tracking change only their current release identity;
the actual new publisher scan determines findings, not the preceding release's
counts. Policies, exclusions and security thresholds are not changed.

Keep all three persistent volumes, runtime overrides, LB database settings,
custom audit directories and the previous official image and backups for rollback.
New bundled defaults do not upgrade existing running hosts by themselves. Source
and component CI evidence do not establish Server deployment, active-stream
remediation or complete native-matrix acceptance. Do not patch deployed binaries,
restore stale Key policies or weaken MFA to apply the update.
