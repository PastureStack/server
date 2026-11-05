# Server v1.6.569

Published image: `ghcr.io/pasturestack/server:v1.6.569@sha256:0de2f923e9edc215e6aa2e520d3eeac0bcbd7b0d09bf8ec9eefea0028c26fb50`.

Source commit: `b65aa8d9641950c375135eb82c675abd5e71d3ea`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

This assembly consumes published Engine v0.183.370, Web Console 1.6.209 and
optional Bridge 0.2.11. Catalog 0.20.17, Compose 0.14.41 and other component
coordinates are retained. The four independent AI opt-ins remain default-off.

| Component | Producer commit | Original artifact SHA256 |
|---|---|---|
| Engine v0.183.370 | `efa6e4acf2bb023411ee7ab213c4a84d346e2662` | `c2f9726b61f8e147e4f0045a7feec251aa1a9da6cbdcaeb25de3642e5ddba765` |
| Web Console 1.6.209 | `caf5e8e9be78c89cacbdbf11891be1ed21772f89` | `88d295429b6de18bcd89c2367b99131c5a0e3ab5f9a024a93c5b05557026b3fb` |
| Optional Bridge 0.2.11 | `caf5e8e9be78c89cacbdbf11891be1ed21772f89` | `a50ea86c9c17e1ec1a4197a900af4fd6b26a6b7ed446a63fbfd542e380cffef5` |

Host changes are limited to name and description through immutable human review.
Host workload references are bounded and freshly checked against the current
account, role, schema and Key policy. They do not authorize Host lifecycle,
capacity, labels, credentials or Node Agent changes. Hidden identities and counts
stay excluded; unknown completeness never establishes an empty or removable Host.

Legacy container references may resolve their Stack through one non-removed Service
relationship only when the persisted Stack ID is absent. Fresh Service/Stack
permissions and final relationship checks remain required; hidden, ambiguous or
changed relationships remain unknown. No native reference validation is relaxed.

Catalog launch plans now bind to the created Stack before normal scheduling.
A dispatched launch is not repeated after an uncertain response. Ordinary object
creation and original exception propagation retain their existing behavior.

The builder and final image install the official Ubuntu APT 3.2.1ubuntu0.1 package
pair for CVE-2026-109518, with exact package, architecture and SHA256 checks.
The new VEX entry applies only to those fixed Ubuntu 26.04 amd64 package identities.
Other pending findings and security thresholds are retained; Server artifact scan,
startup and restart results must come from the original publication workflow.

Engine original CI passed 3981 tests with zero failures/errors and one inherited
skip; all 166 required methods passed. Its twelve public assets and native release
attestation passed. Workflow SLSA remains NOT_PROVIDED and four inherited lower
CodeQL findings remain disclosed. Web CI passed 1129 browser tests; its thirteen
public assets, original archive/SBOM evidence and native release attestation passed.
Bridge carries the existing 0.2.5 clean-install evidence and a current SDK handshake;
no new installation claim is made.

Deployment-specific Catalog, Host metadata/workload, Volume reference and role/Key
audit acceptance is separate. Full 243-group frontend coverage is incomplete.
Upgrade and rollback must preserve operator overrides, all existing named volumes,
restart policy, HTTPS origin and the previous healthy Server. Rollback across data
changes requires the matching verified database backup.
