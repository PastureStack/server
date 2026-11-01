# Server v1.6.562

Published image: `ghcr.io/pasturestack/server:v1.6.562@sha256:0528940e29aabf142d852df14fb954be3cbf240db3be6b43822fbe48ea62af0d`.

Source commit: `d6bec333a5852ced8f33733f614ee5a21aa7b38d`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Corrected workflows

- External Service review now shows the actual current hostname/IP before
  values through native dynamic fields, retaining safe display, owner and CAS
  checks. The exact ServiceIndex cleanup fix for Service scale-down and
  Service/Stack removal is retained without a generic cleanup grant.
- Key discovery explicitly distinguishes legacy `apiKey` from restricted or
  expiring `apiKeyRestricted`, including same-name candidates. Existing current
  actor/role, Key scope and policy revision checks still decide access.
- Human confirmation maps sanitized permission codes to clear account/Key
  guidance and stale/session codes to re-query/preview guidance. Raw error
  messages are not forwarded and hidden foreign targets are not disclosed.
- Pending-review and authorization notices remain in content flow so footer
  controls stay actionable, including the reviewed narrow/RTL profiles. Original
  CI includes the compiled theme rules and 96 parameter combinations; those
  combinations are not 96 unique tests or a completed browser/locale matrix.
- Official MariaDB Connector/J `3.5.11` replaces `3.5.10` on the existing 3.5
  line. The four reported JDBC CVEs are absent from qualified original component
  scans; the assembled image passed its own security gate. SQL, connection
  configuration and privilege contracts remain; real JDBC business compatibility
  acceptance is separate.

## Verified component inputs

- Engine v0.183.363: producer `6b23ada41c0324d708739433b68f5ff00d2209c3`; tag source `0173d171053fd9d232d59ebe2adbf4c91f132ccf`; tested tree `4a0f382ec4371e0343060cc567103e5611fe5430`.
- Original cattle.jar SHA256 `b2c1beca47f0654c22633012359eb8171202cb8192f7590ceddb02289875deda` (88234250 bytes); runtime SBOM `48896415699a4f4cb8d44d9429e63e8f32f35ece266f63f016dc5bb7f7405783`.
- Original Security run 41276564016 attempt 1; CodeQL 41276563988 / 41276564757; 3858 tests in 414 suites, zero failure/error, 1 existing skip(s). Seven new preview cases and eight inherited cleanup cases are separate.
- Operation contract: 431 inputs / 1396 tuples / 1397 projection rows; source fingerprint `5bd56f773b6d57827ee04cfb5fb51f3e9ff95969a152edbbbff40abf3bb338fc`; zero tuple/semantic delta and historical review chain retained.
- Packaged official JDBC3.5.11 SHA256 `42604178b9e57ec08ee0035079961516f086e455d0141f0b22c6eff29fb2fff4`; four reported JDBC CVEs absent from qualified original scans. No new exception is added.
- Web 1.6.203 / bridge 0.2.5: producer `d97a8990801a281b519573a48b0db7dd12c9a616`; tag source `ae409b8404e946512297f00a71bdb4c141a3d5eb`; tested tree `6fff4d815fa34edc0287626e2ab83990fbc3a061`.
- Web archive SHA256 `81e2e81becb2a006f0a753d781d7ec0383a908081c10864f451e8372b246b59d`; lock SHA256 `a0dfad456f43949e8c7c707197a0d73c2bb54b1a2a6d0ce763db1e3be7038452`; independent browser runtime SBOM `a34c07e7c6289a72174ddf5be4e83d1ccc8db0ad5fea07264f0b623eb77f013e`.
- Optional bridge ZIP SHA256 `cafe59ca00122dfaf9534f65f2cbd96500e6c014f4819dd8c49fd3cd4fa23b93`. All 12 Engine and 13 Web public assets passed anonymous SHA256 readback against fresh metadata bytes.
- Engine provenance is original GitHub artifact/source/tree evidence; no native Engine SLSA attestation is inferred.

Catalog `0.20.17`, Compose `0.14.40` and the other qualified component/package
pins, base image, VEX statements and vendor entries are retained. Component
publication reused original qualified bytes; Engine artifact/source provenance
remains separate from the Server image's native attestations.

## Publication verification

The original [publisher 41279691957](https://github.com/PastureStack/server/actions/runs/41279691957)
passed source/build, security, startup/restart and protocol gates. All 35 public
assets and the OCI digest above passed anonymous SHA256 verification; native
image provenance and SBOM attestations passed. Documentation changes do not
replace the source commit, rebuild the immutable image or rewrite release assets.

The merged-rootfs, active nested payload and independent browser runtime scans
passed the existing exact VEX/vendor policy. Critical/High, available-fix,
untracked and secret counts were zero. Ten registered Medium occurrences remain;
passing the gate does not mean zero vulnerabilities. Raw/effective evidence is
retained, and browser runtime SBOM coverage remains incomplete.

## Designated deployment and pending acceptance

Sealed 8080 cutover, one actual restart and smoke passed for this exact digest
and producer, with three active Hosts and three active Agents. Host configuration,
mounts and AppArmor were preserved, the explicit operator plan was verified,
and the rollback container was retained. This designated baseline did not
change production or replace the original publisher.

Core, External, Certificate, Audit and B3 business workflows remain pending.
Native ownership, role/Key/revision and cross-ID behavior, actual JDBC read/write
and transaction compatibility, browser/footer/locale layouts and designated
weak-model workflows require their own results on this image. Published source,
component CI and baseline health are not business completion or full 243-group
acceptance. Original failed and unaffected evidence keeps its original scope.
Human confirmation, Full/legacy behavior and the four independent default-off
AI properties remain unchanged.
