# Server v1.6.494

Published Server artifact verified. Certificate QA remains pending. This release packages
two CI-verified, published components for the Certificate defects reproduced on
`v1.6.493`. Publication and isolated `8080` start/restart do not establish
Certificate API/browser acceptance or a completed resource/role matrix.

## Published Server artifact

The [official release](https://github.com/PastureStack/server/releases/tag/v1.6.494)
and numeric tag point to Server source
`c3b50ad6891ebbde4612e89dd5a1114bc731431c`. Official
[publication run `36704785404`](https://github.com/PastureStack/server/actions/runs/36704785404)
passed source gates, the exact image build, flatten/configuration comparison,
candidate start/restart, merged-rootfs security/SBOM, image publication,
provenance/SBOM attestations and immutable Release asset checks.

The published immutable image is
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`.
Public GHCR tag and immutable manifest bytes resolve to that digest; image
version/revision/source labels and the SBOM identity match the release.
The final Linux/amd64 image has one filesystem layer. All 22 `SHA256SUMS`
entries and the checksum manifest match both the downloaded bytes and GitHub
asset digests.

Trivy `0.74.0` scanned the merged rootfs: 52 raw package findings, with the exact
eight Medium vendor-pending package findings (four CVEs) remaining after OpenVEX
`0.2.0`. The scan JSON, TSV and tracked pending set match; untracked,
Critical/High, fixed-available and secret findings are zero. Vendor review remains
due `2026-10-20`. This is not a zero-CVE claim.

## Published component coordinates

Orchestration Engine `v0.183.327` source
`dce2f2473ffea1510fe10676a771eb1fe5d0b161` passed normal validation run
`36701559252`; its source changes are merged in
[PR #60](https://github.com/PastureStack/orchestration-engine/pull/60).
Assembly packages `cattle.jar` at the numeric `v0.183.327` release coordinate,
with SHA-256
`c6d4c3003a19db19d1be73e69aa52358a0a4166bf726cbefe7e2ab9ed5664b56`.
The published numeric release asset's registry-reported SHA-256 was independently
read back and matches this source pin. The executable WAR also completed an
isolated JDK 25.0.3 H2/MySQL-mode startup with `--exit` (exit 0); no platform
volumes, ports or database were used. This is not a complete SQL integration suite.

Web Console `1.6.160` source
`63964fa3a6da5cbd452cdc1061c1e18340055362` passed normal CI.
Official validation run `36702030007` passed with 725/725 tests;
its source changes are merged in
[PR #138](https://github.com/PastureStack/web-console/pull/138).
Assembly packages `web-console-1.6.160.tar.gz`, containing
`VERSION.txt=1.6.160`, with archive SHA-256
`705946b96e693c55a8ab5de3bc96b14020a52a050bf3992c302b9fb3c1408a51`.
The published numeric release asset's registry-reported SHA-256 was independently
read back and matches this source pin. The two CI production archives are byte-identical.

## Certificate behavior

The Engine's shared update filter derives metadata only when a request
explicitly supplies `cert`. Name-only and description-only edits therefore
preserve the stored certificate and private key without parsing an omitted
field as null. Explicit null is rejected by the existing non-nullable API schema
with 422 / NotNullable; empty and malformed non-null certificate inputs fail
with 422 / InvalidFormat. Certificate create validation, private-key
masking and project authorization are unchanged.

The shared DELETE and remove-action guard checks the actual alternate IDs in
`lbConfig.certificateIds`, along with the existing default and v1 references.
References from non-removed load balancer services in the certificate's
account block removal with 405 / InvalidAction. Unused certificates remain
removable. No database migration or account teardown change is introduced.

Public resource action names remain case-sensitive. The advertised `remove`
action reaches the reference guard; an undeclared action such as `ReMoVe`
receives 422 / InvalidAction from schema validation before that guard. Rejecting
an invalid action name is not evidence that the reference guard ran.

The console maps only the known 405 / InvalidAction certificate-in-use
response to an explanation that the load-balancer references must be removed
first. English, Traditional Chinese and Japanese are covered. Service names
and IDs are not displayed; 403, 404 and unrelated 405 responses retain neutral
feedback. No authentication, session, OIDC, MFA, proxy or API contract changes
are included.

## Preserved assembly and remaining acceptance

Assembly retains the `v1.6.460` immutable runtime base used by `v1.6.493`,
its JDK policy, curl `8.18.0-1ubuntu2.7`, signed Ubuntu OpenSSL
`3.5.5-1ubuntu3.6` package pins and verification of the CLI, libraries, engines
and legacy provider. All other component coordinates, runtime parameters,
security thresholds, VEX statements and the exact eight Medium vendor-pending
findings are carried forward unchanged. Release-specific security metadata
targets `v1.6.494`; the published artifact independently passed its security
gates. No vulnerability is newly excluded or declared fixed by this release.

Isolated `8080` deployment start/restart passed with `runtime-contract.diff=0`
and unchanged database row counts before startup, after startup and after restart.
Certificate API/browser acceptance remains pending. The original 69-step planned scope must
verify name-only and description-only PUTs on both `/v1` and `/v2-beta`,
unchanged certificate/key storage, native owner-editor Cancel/Save/refresh,
and denied DELETE/remove of default and alternate referenced certificates.
The normal role and exact-resource authorization boundaries also remain
required. Publication, component CI and deployment start/restart results do not
complete those Certificate checks or the broader resource/role matrix.

Retain the published immutable rollback image
`ghcr.io/pasturestack/server:v1.6.493@sha256:61067362a2d91b791c7e80cb2ec4a5a907bc03884774d2019dccf1bf0e29788f`
with its original named volumes and runtime settings. That prior image still contains
both known Engine Certificate defects; do not remove a referenced certificate
through it. No company-site deployment is claimed by this release.
