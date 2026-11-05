# Server v1.6.568 candidate

Source candidate only. Server publication and matching runtime acceptance remain
pending. Install published Server v1.6.567 until this candidate completes the
original publisher's required gates.

## Verified component inputs

This Server assembly uses immutable-published Engine v0.183.369, Web Console
1.6.208 and optional Bridge 0.2.10. Catalog 0.20.17, Compose 0.14.41, all other
component coordinates, four independent default-off AI flags and security gates
remain unchanged.

| Component | Producer commit | Original artifact SHA256 |
|---|---|---|
| Engine v0.183.369 | `69eba9f0e7e60907334a0514f19c84bb48a22f4c` | `7eb607a12d02c9d98a7b3e7377b01be1daf141de8730705a677de337b53e484b` |
| Web Console 1.6.208 | `4f20e5d2f707086bdb4506f8f01b271104d04019` | `91384580cf5cb0e5ac618ed883638643f62701aefefca431fc771671e4c98894` |
| Optional Bridge 0.2.10 | `4f20e5d2f707086bdb4506f8f01b271104d04019` | `f3a551df17051242365267a30726013f506f20de9a72323cd364a674e8dd111f` |

Engine original CI passed 427 suites / 3957 tests with zero failures/errors and
one inherited skip; all 142 required identities passed. Ten new and sixteen
inherited affected methods passed. Its twelve assets passed anonymous byte
readback and native immutable-release cryptographic attestation. Engine workflow
SLSA was not provided. Existing lower CodeQL and Dapper findings remain disclosed
in that component's release evidence; they are not claimed patched.

Web full/enabled CI passed 1129 browser tests with zero failures, including two
new scoped layout QUnit cases. Three Volume Node cases, the thirteen-locale
LB-warning case and four install-version Python controls passed. All thirteen
Web assets passed anonymous checksum/length readback. Original archive
provenance, runtime-SBOM and native immutable-release attestations passed.
Bridge retains 36 source files / 38 ZIP entries / 92 dependency components. The
unchanged graph explicitly carries genuine published 0.2.5 clean-install
evidence; its current 0.2.10 real SDK stdio handshake passed without a new install.

Volume detail adds at most fifty currently readable active/stopped container
references from SQL bounded to fifty-one relationships. Context-bound opaque
references and separately authorized Stack names retain current account,
object, role and Key boundaries. Hidden identities/counts, host source paths and
secrets are excluded. Completeness remains unknown; empty or limited references
never establish unused or safe-to-delete status. No grant, tool, write or
native deletion-oracle change is introduced.

External TCP review states the native load-balancer-target-only boundary.
Scoped AI confirmation and Audit detail dialogs preserve full long values in
narrow RTL viewports, native code scrolling and desktop limits. Bridge download,
checksum, extraction and cd instructions bind to the source package versions;
valid Windows CRLF is accepted without changing archive bytes or hashes.

Published Server 1.6.567 remains the designated runtime. Final Server image scan,
SBOM, startup and restart evidence is produced by the original publisher;
deployment-specific native role/Key/reference/audit, weak-model and RTL layout
acceptance remain separate. Existing VEX statements, pending finding identities
and security thresholds are unchanged. Raw reports and incomplete browser SBOM
coverage remain explicit. No whole-family or 243-group completion is claimed.
