# Server v1.6.510

Release packaging contract. The official immutable image digest, release source,
build/start/restart, security scan and SBOM are independently published in the
release assets. Component CI and publication are not browser lifecycle acceptance.

## Scope

The candidate packages Web Console `1.6.172` for request-local create-only first
delivery. Schema-defined first201 values belong to the originating save and its
noncanonical delivery clone, not to permanent canonical cache fields. The native
modal must still display the exact first response values and bind both visible,
enabled copy controls to those values. Clipboard clicks are not claimed by the
predicate-only offline tests.

Orchestration Engine remains official `v0.183.333`, exact source
`0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
`8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
The digest-pinned Server460 base and final single runtime layer are unchanged.
Role authorization, frozen schemas, database, OIDC/MFA, firewall, production
environment and persistent volume contracts are unchanged.
No migration or runtime patch is required.

## Verified component and pending Server gates

- Web172 signed artifact source: `daab6e8ed5206562feb60e6549a3b9e72b4c8381`.
- Web172 public archive SHA256: `9a21c5e6ff9fbb274dbc7c45ec1ccffdbff33a945544b64d5976b14ee9752bfa`.
- [Formal Web CI](https://github.com/PastureStack/web-console/actions/runs/37109872791):
  808/808 tests; zero failures, skips or todo; two byte-identical production builds.
  Public immutable release assets were anonymously read back and matched exact CI bytes.
  Signed PR164 head `47eba4985dcdda41d48d3d266118cee67dd51f68` has the same
  tested tree `8f6c8eb930fe77d6983a37e9b30912a384af5e7e`; tag/artifact source
  remains the tested commit above, not a rebuilt artifact.
- Build coordinates remain exact/fail-closed. A source-contract test is not Server build PASS.
- Server510 clean committed source, build/start/restart, exact merged-rootfs
  security scan, SBOM/licenses, official publication and anonymous readback.
- QA deployment profile and one fresh native API Key create/edit/deactivate/
  delete case, including actual first delivery and cookie-free issued-key reads.
- Fresh isolated Host lifecycle and the full permission/resource/locale/layout
  matrix remain separate pending outcomes; guest or fixture PASS is not Host PASS.
- KB projections and artifact/SBOM records await actual Server510 publication.

VEX51 statements and the 8 Medium package findings covering 4 vendor-pending
CVEs, with review date `2026-10-20`, are carried forward policy inputs only.
They are not a new Server510 scan or a zero-CVE assertion. No policy set,
severity threshold or existing exception is widened.

## Immutable prior evidence

Server509 remains official source `261bb23c980f5f896375923233e36f6554b99751`,
image `ghcr.io/pasturestack/server:v1.6.509@sha256:d934c9d7bc7387626fedca5d403210fac70b7b4e35e334dcdb439f79f555ab87`.
Its existing Account6974 scoped closure and Project6977 scoped removal stay
version-bound. The new key6982 run remains HOLD after only POST201; no issued
Basic reads, edit/deactivate/delete or cleanup completed. Its active resource
is retained without automatic retry or cleanup. Old HOLD evidence is immutable
and will not be replayed or promoted by this candidate.

Keep the verified509 immutable image for rollback. Use510 only after its official
image identity and artifacts have been independently verified. Publication does
not deploy or modify the company site, existing environments, volumes or database.
