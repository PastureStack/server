# Server v1.6.566 candidate

Server publication and designated runtime acceptance remain pending.

## Verified component inputs

This release consumes published Engine v0.183.367 and Web Console 1.6.206 /
optional Bridge 0.2.8. Catalog 0.20.17, Compose 0.14.41 and all other component
coordinates remain unchanged.

Service image-upgrade plans retain the exact approved startFirst, batchSize and
intervalMillis through human review, native apply and operation reads. Genuine
legacy image-only plans retain their defaults; older engines reject new
strategy-bound plans before claiming or dispatching them.

Typed Audit input is validated before ordinary schema normalization. Catalog,
resource-change and upgrade action operands use authorized read snapshots to
preserve application-before-row lock order. Ordinary receipt observation,
current role/Key authority, preflight, revision checks and one claim remain.

| Component | Producer commit | Original artifact SHA256 |
|---|---|---|
| Engine v0.183.367 | `7cdacb4aad8cfbee3db239bb602a6a047da31fcf` | `4435aec3508fafeb1b1d88f455b7cef815c026957820b9127a391728130aa86c` |
| Web Console 1.6.206 | `d890c430f5c6e72578b1585d1ccc11103bc47bfe` | `c385bd89cb9458650259a9fc46baa5a46e60dd6a67fd116a3ed13bcf372a2075` |
| Optional Bridge 0.2.8 | `d890c430f5c6e72578b1585d1ccc11103bc47bfe` | `b851fc1bf13657a696a571ca9b8747a85e43be09f7820ac1506218324150e568` |

Engine original CI passed 3,940 tests with zero errors/failures and one existing
skip; all 125 required method identities were observed. Web original CI passed
1,122 browser tests and nine new source cases. All 12 Engine and 13 Web public
assets passed anonymous checksum/length readback. Web archive provenance and
runtime-SBOM attestations passed. Bridge dependency installation/SDK evidence is
carried from the unchanged graph, rather than claimed as a fresh installation.
These component results do not establish Server runtime or full frontend QA.

The four AI opt-ins remain independently default-off. Existing environment,
named volumes, restart/security settings and HTTPS origin must be preserved.
Back up data and retain the prior immutable image/configuration for rollback;
never remove volumes. No production site, HAProxy, firewall or database settings
are changed. This update adds no VEX statements or security-policy exemptions.

QA8080 Audit remainder, Catalog launch/archive/restore, upgrade strategy,
native-role boundaries, human review and weak-model cases are tracked separately.
Unaffected PASS and original failures are retained; all 243 frontend groups are
not claimed complete.
