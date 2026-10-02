# Server v1.6.503

Published through official publisher
[37015013747](https://github.com/PastureStack/server/actions/runs/37015013747)
and verified immutable public release/registry readback. Server source is
`df061d5c93d0e4fdbc0e06664493ac5328a6f596`; the image is
`ghcr.io/pasturestack/server:v1.6.503@sha256:4a8997768c5c16a9aefdc682f906aab34417e204d622d03116e62b2fcfe0af79`.
Publication and QA deployment below are distinct from the scoped native
permission checks; none establish complete matrix acceptance.

## Shared schema lookup

Web Console `1.6.167` aligns synchronous schema lookup with the ID normalization
already used when schemas enter the API store. Mixed-case resource types such
as `registryCredential` otherwise miss a correctly cached permission schema.
Only IDs looked up in the normalized `schema` group are normalized. Ordinary
resource IDs remain opaque and case-sensitive. Actual store regression tests
must cover inherited Resource schema lookup, readonly/member methods, missing
schemas and separate project stores; no fallback permissions are introduced.

Server build inputs pin Web167 source
`dff35fc4bce340e21cac7204146a7bcb20a7b60b` and archive SHA-256
`e8e714fc06282de75a3570aac1d4d4d04a3c9478d982d0d5aaeae14efa8ebbaf`.
Exact-source component validation 37012345421 passed 772/772 tests with zero
failures, skips or todo cases and byte-identical production archives. Four new
Store/schema regressions and the local Chrome 4-test/43-assertion run passed.
The component's signed immutable numeric release and anonymous public readback
match the formal archive (2,976,297 bytes);
these results are not packaged browser or complete matrix acceptance.
Engine `v0.183.331` and its exact WAR, API/schema, backend authorization,
authentication/session ownership, OIDC/MFA, runtime overrides, nftables settings,
security thresholds and multi-stage/single-runtime-layer contracts are unchanged.
No database migration or runtime patch is required.

## Official publication checks

The isolated publisher's first start and restart returned HTTP 200/pong after
13 and eight attempts respectively. All 34 MFA/API checks passed. OpenSSL TLS
1.2 and 1.3 returned HTTP 200; an untrusted TLS certificate was rejected. These
are isolated publisher results, not QA deployment or browser acceptance.

The final linux/amd64 image has one runtime layer. Anonymous tag and immutable
manifest/config byte hashes, version/source labels and SBOM identity match.
All 22 checksum entries and 23 release assets including the manifest were read
back successfully. Engine `v0.183.331` remains pinned to source
`515a5d37a1194f827bc3ffde34db729905ecb2b1` and WAR SHA-256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`.

The merged-rootfs scan retains 52 raw findings and exactly eight vendor-pending
Medium package findings covering four CVEs, with review due 2026-10-20. The
unchanged gate reports zero Critical/High, fix-available, untracked or secret
findings and requires exact vendor-pending/VEX sets. This is not a zero-CVE
claim or a relaxation of security thresholds.

## QA deployment preservation

The immutable Server503 image was deployed to QA8080. First start and one
restart returned HTTP 200/pong after nine attempts each. The runtime-contract
comparison had zero differing bytes, environment overrides and named mounts
were preserved, and `docker-default` AppArmor, bridge networking and the
`unless-stopped` restart policy remained unchanged. Docker health is `null`;
no Docker `healthy` result is claimed.

The account/credential/setting/project-membership/host count baselines remained
530/4095/38/14/3 before the upgrade, after first start and after restart. This
is a five-table count comparison, not a whole-database row comparison. The
stopped immutable Server502 rollback container and database backup were
retained. Deployment preservation does not establish native-browser,
permission/locale-matrix or company-site acceptance.

## Acceptance and recovery boundaries

Registry/credential QA on Server502 stopped before resource writes at the
missing credential-model schema. Its original HOLD remains unchanged. A new
503 forward-only case subsequently confirmed the actual GET-only registry and
credential models, hidden create controls and disabled edit/remove controls for
the readonly role. The no-access role showed the environment-unavailable screen;
both roles used existing human-readable permission errors. All 24 normal-CSRF v1/v2-beta
write denials passed: 12 readonly HTTP 405 and 12 no-access HTTP 403. A member
completed three advertised cleanup writes; the registry remains inactive and
its final removal is pending thirteen-locale badge validation. These are
bounded exact-fixture results, not a complete create/edit/delete lifecycle or
all API authorization. The full permission/resource/locale matrix remains
INCOMPLETE. Historical HOLDs remain unchanged; publication, deployment or a
later partial check does not promote them.

After verified publication and successful packaged QA, change only the Compose
image to the new tag and verified digest. Preserve environment variables, named
volumes, restart policy, AppArmor, HTTPS origin, OIDC/MFA, performance parameters
and firewall mode. Keep the previous immutable Server502 image/container and
database/volume backups. Roll back code using that image with the same data and
configuration; do not delete volumes or run SQL repair statements.

No deployment to `stack.ascdc.tw` is authorized. Existing vendor-pending CVEs
remain documented under the unchanged gate; no zero-vulnerability or complete
matrix claim is made by publication.
