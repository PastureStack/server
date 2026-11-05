# Server v1.6.571

Published immutable image. The designated QA deployment passed initial health
and a subsequent restart; new business acceptance remains separately pending.

## Verified component inputs

This assembly consumes published Engine v0.183.372, Web Console 1.6.210 and
optional Bridge 0.2.12. Catalog 0.20.17 and Compose 0.14.41 are retained.

Engine producer: `de36aa7eab37ce84f08cc4ca3c0159f5299e1a3d`.
Engine artifact SHA256: `2533d79cbd5a0ff65c27d7f94e109129c990c9cb4a597b8acc6842aa2a6b6545`.
Web Console producer: `23f2bbd3d820ab681771599248dc8b3d9fab5786`.

## Changes

The optional AI collaboration workflow adds name and description changes for
the selected environment and load balancers. Queries provide opaque references;
previews retain the exact target, approved fields and revision. A human reviews
the changes in the existing inbox before execution. Current native role, schema,
object access and Key authority are checked again when the queued work runs.
Load-balancer receipts reject changed target or parent identities, including
cases where the requested name and description happen to match.

Shared-profile Bridge requests for an unbound environment receive a clear
confirmation requirement. The human Key audit view distinguishes bounded client
reports from authoritative platform decisions and exposes the matching reason.
Credentials and sensitive payloads remain excluded from these projections.

The four independent AI opt-ins remain default-off. Existing Full and legacy
Key behavior, MFA, cross-tab sessions, performance options and network backends
are preserved. Component validation observed 4,014 Engine tests and 1,134 Web
Console tests with zero failures; the Engine retains one pre-existing skip.

## Upgrade and rollback

Preserve operator overrides, named volumes, restart policy, AppArmor, HTTPS
origin and the previous healthy image. Back up the database and volumes and
verify recovery before deployment. Rollback after data changes requires the
matching database backup. Component CI and immutable publication do not replace
deployment-specific business, permission or browser acceptance.

## Publication evidence

Official publisher: [42054870171](https://github.com/PastureStack/server/actions/runs/42054870171).
Artifact source revision: `a578c4cac1f8d79386f2168f856a6a4aee7eecb2`.
Tested tree: `63a18511b6fc631be4ce7730794874fbca0b6889`.
Published image: `ghcr.io/pasturestack/server:v1.6.571@sha256:d59fce0b3eda6abd11de6bc0b43fecf35c1ac9c37ad05f57ed234351164c4e25`.
All 35 anonymous assets, OCI/component identity, provenance and SBOM attestations
passed independent readback. The official build ran unfiltered console-broker
Go tests successfully, including the two new client-report projection methods.
Effective scan findings retain nine MEDIUM entries; no CRITICAL/HIGH entries.

This repository note is aligned after publication. The original public release
asset stays immutable. The designated QA deployment retained the exact Server571 container through restart,
HTTP200/pong, 3 Hosts/3 Agents, 4 mounts and all 19 Docker data volumes. All 19 official
APT ELF hashes, package pair, runtime manifest and embedded lock matched; the
three-daemon busybox cache was read back without new pulls. The prior healthy570
container remains a rollback point with its matching-data requirements.

Project7, LB7, Host12, B3, Bridge restart/ref/weak-model and client-audit 52-cell layout
acceptance remain pending their own scoped receipts. No complete 243-group or
workflow-SLSA acceptance is claimed.
