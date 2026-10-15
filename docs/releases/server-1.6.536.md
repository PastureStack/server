# Server v1.6.536

Immutable Server producer `b8cefb51db7f5e88341fdf231f6ae43d773fb9c7` passed the original official workflow [38681298101](https://github.com/PastureStack/server/actions/runs/38681298101) and anonymous release readback. Manifest: `sha256:84b701244ccd83abc313cfad47c52edf9c58fa49cdd5c2da129cdac0c81d8094`. Distinct OCI config: `sha256:4b56a5f4f58edf2ff08414fde91cc70da440562d7b6264ec62aaca133c256237`. Artifact identity (not an installation command): `ghcr.io/pasturestack/server:v1.6.536@sha256:84b701244ccd83abc313cfad47c52edf9c58fa49cdd5c2da129cdac0c81d8094`. Documentation commits do not replace the producer. Numeric installation tags remain required.

This packaging update retains Web Console `1.6.189`, Engine `v0.183.349`, API Key policy, authentication, volumes, performance settings and firewall behavior. QA startup/restart passed with the original runtime configuration. No database migration or runtime binary patch is used.

### Maintained CLI error reporting

Official immutable [CLI `v0.6.18`](https://github.com/PastureStack/cli/releases/tag/v0.6.18), producer `2fd1298ffdc25e17008cb089fccf7780ed8728d5`, passed its original release/security gates and anonymous archive/SHA256SUMS readback. The three external download defaults use the producer's platform-before-version names. `PASTURESTACK_CLI_RELEASE_BASE_URL` follows the effective `CATTLE_RANCHER_CLI_VERSION`; without it the historical RC16 layout remains available. Explicit DEFAULT/active URLs and saved database settings remain authoritative. Existing custom mirrors are not silently migrated. Changing a download setting does not install a binary inside Server.

On the official Server535 QA runtime, the maintained native CLI performed the same ordinary inspect command with Full, absent-policy legacy and Closed Keys. Full/legacy DTOs matched exactly; Closed returned nonzero with HTTP403 `KeyPolicyDenied`, no DTO and matching authorization/response audit pairs. The single empty Stack, three Keys and temporary client directory were normally removed. This evidence retains its actual535 provenance; it is not a536 rerun or a whole-client/role matrix. The old0.6.14 silent exit-zero defect and original failure receipts remain historical evidence.

E2E-02 acceptance is the bounded original F-G evidence plus root review of exact unchanged UI pointers, with original versions and original FAIL retained; no new browser run is claimed. Unchanged535 action/role/rollback evidence is carried only within its original scope. Remaining matrix gaps, historical HOLDs and deferred KVM work remain unverified.

The Server final-image gate retains 22 unfixed package findings across 11 CVEs, review 2026-10-20. CLI retains 100 exact reviewed LOW/MEDIUM tracker rows under the approved no-fixed policy. Raw findings, vendor status and precise VEX decisions are preserved separately; tracking is not remediation, not_affected or a HIGH waiver. Source SBOM inventories do not prove runtime safety or zero risk.

Preserve the existing named volumes and runtime overrides; retain the previous working container for code rollback without restoring old policy/revocation/expiry or database state.
