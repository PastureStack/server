# Server v1.6.581 candidate

## Candidate boundary

This is a source candidate, not a published Server image or deployment result.
The normal Server publisher must build, scan, flatten, attest and qualify this
assembly before use. Server v1.6.580 remains the latest published release.

## Verified component inputs

This assembly pins the already published Engine `v0.183.383` and Web Console
`1.6.223` / optional Bridge `0.2.25`. Ordinary Service `update_links` replaces
the complete supported simple dependency set through a separately reviewed plan;
it preserves current authorization and the captured configuration. Registry
activate/deactivate uses its existing native lifecycle owner, without exposing
Registry credentials or adding credential writes.

Engine383 also enforces checked SETLINKS locking across the common dependency
writers, transaction completion and removal paths. Lock contention or loss fails
before mutation; this is not a broader role, API Key or generic HTTP permission.
The existing LB dependent-lifecycle boundary remains part of the Engine input.

The Engine producer `63c6a19c1d03172297c400ab3ad98bde3ed0da08` passed 460 suites,
4,145 tests and all 330 required methods, with zero failures/errors and one
inherited skip. Its cattle.jar SHA-256 is
`c1ce37023c9ad6fa648f198189bf9fe0ca087dbd0e15b2b54caf9cfe30f82f9b`.
All sixteen serialized role schemas retain the published382 bytes.

Web223 producer `4409b1ce6e70ab60e28b04e42a5ab9f3a2386593` passed 126 distinct
focused source cases (113 Node and 13 QUnit), including the Service-link,
Registry-lifecycle and port-conflict changes. Its runtime archive SHA-256 is
`ceb947eb598afd822993b2b68117d62d761df36043315d98918bb66b1617e9b4`;
the optional Bridge0.2.25 ZIP SHA-256 is
`69e8bf9242e66eecfeb3df9d0263686c559fc4c6428b6859ebbea966541ce2a1`.
The immutable component publications have local cryptographic-attestation and
anonymous-byte readback receipts. These are component evidence, not native
Service/Registry/TCP/weak-model or all243 frontend acceptance on Server581.

The recipe's multistage and flatten steps, proxy, Agent, Host API, Catalog,
Compose, official APT pins and security thresholds are unchanged. Existing
exact-package pending/VEX statements retain their scope and still require the
new assembly's normal scanner gates. No previous image's scan is a Server581
scan result. Feature opt-ins, origins, JVM options and native roles/Key ceilings
remain authoritative.

Preserve the operator's mounts, named volumes, restart policy, AppArmor and
firewall configuration. This batch introduces no data migration. Retain the
qualified Server580 image, operator configuration and matching database backup
for rollback; restore the complete assembly rather than swapping live bundles.
