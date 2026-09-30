# Server v1.6.494

Source target; component releases verified; Server artifact pending. This preparation pins two
CI-verified, published components for the Certificate defects reproduced on
`v1.6.493`. It does not declare a published Server image, an immutable Server
digest, a Server artifact/security PASS or accepted `8080` Certificate QA.

## Candidate coordinates

Orchestration Engine `v0.183.327` source candidate
`dce2f2473ffea1510fe10676a771eb1fe5d0b161` passed normal validation run
`36701559252`; its source changes are merged in
[PR #60](https://github.com/PastureStack/orchestration-engine/pull/60).
Assembly expects `cattle.jar` at the numeric `v0.183.327` release coordinate,
with candidate SHA-256
`c6d4c3003a19db19d1be73e69aa52358a0a4166bf726cbefe7e2ab9ed5664b56`.
The published numeric release asset's registry-reported SHA-256 was independently
read back and matches this candidate. The executable WAR also completed an
isolated JDK 25.0.3 H2/MySQL-mode startup with `--exit` (exit 0); no platform
volumes, ports or database were used. This is not a complete SQL integration suite.

Web Console `1.6.160` source candidate
`63964fa3a6da5cbd452cdc1061c1e18340055362` passed normal CI.
Official validation run `36702030007` passed with 725/725 tests;
its source changes are merged in
[PR #138](https://github.com/PastureStack/web-console/pull/138).
Assembly expects `web-console-1.6.160.tar.gz`, containing
`VERSION.txt=1.6.160`, with candidate archive SHA-256
`705946b96e693c55a8ab5de3bc96b14020a52a050bf3992c302b9fb3c1408a51`.
The published numeric release asset's registry-reported SHA-256 was independently
read back and matches this candidate. The two CI production archives are byte-identical.

## Certificate behavior

The Engine's shared update filter derives metadata only when a request
explicitly supplies `cert`. Name-only and description-only edits therefore
preserve the stored certificate and private key without parsing an omitted
field as null. Explicit null, empty and malformed certificate inputs continue
to fail with 422 / InvalidFormat; certificate create validation, private-key
masking and project authorization are unchanged.

The shared DELETE and remove-action guard checks the actual alternate IDs in
`lbConfig.certificateIds`, along with the existing default and v1 references.
References from non-removed load balancer services in the certificate's
account block removal with 405 / InvalidAction. Unused certificates remain
removable. No database migration or account teardown change is introduced.

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
targets `v1.6.494`; the new artifact must independently pass its security
gates. No vulnerability is newly excluded or declared fixed by this
preparation.

After component publication and Server artifact gates, isolated acceptance
must verify name-only and description-only PUTs on both `/v1` and `/v2-beta`,
unchanged certificate/key storage, native owner-editor Cancel/Save/refresh,
and denied DELETE/remove of default and alternate referenced certificates.
The normal role and exact-resource authorization boundaries also remain
required. Source and component CI results do not complete those browser or
runtime checks, or the broader resource/role matrix.

Retain the published immutable `v1.6.493` image with its original named
volumes and runtime settings for rollback. That prior image still contains
both known Engine Certificate defects; do not remove a referenced certificate
through it. No company-site deployment is claimed by this source target.
