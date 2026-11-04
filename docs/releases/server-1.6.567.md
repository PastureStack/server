# Server v1.6.567 candidate

Source candidate only. Server publication and matching runtime acceptance remain
pending. Installation defaults continue to reference published Server v1.6.566
until this candidate passes the original publisher's required gates.

## Verified component inputs

This candidate assembles published Engine v0.183.368, Web Console 1.6.207 and
optional Bridge 0.2.9. Catalog 0.20.17, Compose 0.14.41, all other component
coordinates, four independent default-off AI opt-ins and security gates remain
unchanged.

| Component | Producer commit | Original artifact SHA256 |
|---|---|---|
| Engine v0.183.368 | `1098514b65518d2cde4068884cf6f130576290f3` | `0904ced4a19c9f43ad5e62500d24be9c0a7a61da18ee8c6615097ccf204b893b` |
| Web Console 1.6.207 | `e3f8fbe872d91df6837d5de3339a0efde645ac74` | `f61c21737a41bb3c1fadab8399d07509bfd144aacf2520ed6a73779a0139021a` |
| Optional Bridge 0.2.9 | `e3f8fbe872d91df6837d5de3339a0efde645ac74` | `06705876cd79071c505bb573c9f5d7fc346ea4c6b4512c3eeb3d01e57851f3a9` |

Engine original CI passed 425 suites / 3,947 tests with zero failures/errors and
one inherited skip; all 132 required identities passed. Seven TCP methods and
41 inherited methods form the 48-method affected set. All 12 original Engine
assets passed anonymous byte readback and the cryptographic immutable-release
attestation; the Engine build workflow did not provide SLSA attestations.

Web full/enabled CI and CodeQL passed: 1,127 browser tests, including five new
Audit-modal QUnit cases; four new Node utility cases also passed. All 13 original
Web assets passed anonymous checksum/length readback; archive provenance and
runtime-SBOM attestations passed. Bridge retains 35 source files / 37 ZIP entries /
92 dependency components. Its unchanged dependency clean-install evidence is
carried from 0.2.5; the 0.2.9 SDK handshake is a new verified result.

The typed External Service CREATE owner accepts an optional closed TCP
healthCheck: required port and four optional timing/threshold integers, without
adding defaults. Approved fields remain immutable through native role/Key and
Stack checks, human review, a single claim and verified stopped-create readback.
HTTP controls and External health-check updates remain unsupported. Ordinary
Service health checks and existing Full/legacy permissions are retained.

Service-create review resolves real authorized Stack names, including cache
misses, without user-entered raw IDs or model-supplied labels. The shared Audit payload
modal safely renders metadata-only, empty and non-JSON values as escaped text;
existing human-only payload permissions are unchanged. This source correction
does not reclassify any earlier runtime failure as passed.

The qualified Web build contains the exact minimatch 10.2.6 compatibility
backport for nine existing build-dependency locations. Original npm identities,
raw audit reports and the remaining Moderate findings are retained. The unused
embedded upstream glob matcher is outside that qualification; no complete
runtime or whole-product vulnerability-free claim is made.

Server 1.6.566 remains the designated deployed release. This candidate adds no
VEX statements or policy exemption. The publisher must produce the actual final
Server image scan, SBOM, startup and restart evidence before publication.
External TCP role/Key boundaries, human review, native receipt completion and
the new Audit modal still need acceptance on the matching deployed tuple.
Original failures and unaffected scoped PASS keep their scope; the full
243-group frontend matrix remains incomplete.
