# Server v1.6.579

Published image: `ghcr.io/pasturestack/server:v1.6.579@sha256:f2b7e409457aa95e0b622101a355e000d82be846a66b59f837163298705aabbe`.

Publisher revision: `4ad463e7149536b8c2bc17b3321c6f0fb4988926`; [official workflow](https://github.com/PastureStack/server/actions/runs/42303807649) passed source, image build, security, startup/restart and immutable publication checks. All 35 public assets passed anonymous size/SHA256 readback, the release attestation verified 36 subjects, and OCI provenance and SBOM verification passed.

## Changes and compatibility

Engine 0.183.381 fixes false `PermissionDenied` responses when native framework validation returns numeric Stack/backend references during typed load-balancer creation. Positive native numeric identities are compared directly; String references retain canonical API ID validation. Web Console 1.6.222 / optional Bridge 0.2.24 aligns legacy administrator Project discovery with the native collection and explains how to correct a legacy Stack/Service reference supplied to generic resource tools.

Native roles, membership, API Key limits and explicit human approval remain authoritative. Web222 retains its published minimum-compatible/matching Engine380 metadata; this Server assembly separately verifies the current fourteen-input ABI against the published Engine381 source. Components are consumed from their original immutable releases rather than rebuilt.

Compose 0.14.43, Catalog 0.20.17, APT19, the other component inputs, runtime flags, origins and security gates are retained. Original Engine CI passed 4,084 tests with zero failures/errors and one inherited skip; Web CI passed 1,142 browser tests and 102 focused cases. The Server image retains 13 tracked vendor-pending MEDIUM findings; effective CRITICAL/HIGH, available-fix and untracked findings remain blocking. Original raw reports and the disclosed browser scan-coverage limitation are preserved.

## Acceptance, upgrade and rollback

Publication and component checks are distinct from deployment-specific business acceptance. They do not establish complete coverage of all 243 frontend groups. Use the [Server installation guide](../../README.md#quick-start) with its numeric release tag and preserve the operator's Compose environment, named volumes, restart policy, AppArmor, HTTPS origin, OIDC, performance and firewall configuration.

Retain the previous qualified Server v1.6.578 image, original operator configuration and matching database backup for rollback. This native-reference repair introduces no data migration. Restore the complete qualified Server assembly rather than replacing a running Engine or mounting an older Web bundle.
