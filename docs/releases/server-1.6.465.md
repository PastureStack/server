# Server v1.6.465

This patch release updates Orchestration Engine to `v0.183.321` for the
project-member detail authorization fix. A direct request for an
inactive or removed project-member row must return 404 even when the row remains in the
database. Active rows retain the established project access check. The same
contract applies to `/v1/projectMembers/{id}` and
`/v2-beta/projectMembers/{id}`.

## Component and release coordinates

- Orchestration Engine: `v0.183.321`, source commit
  `2adfd0f0338cf6ae637ceb36532e965ccf8ddb4e`, with `cattle.jar`
  SHA-256 `1be55ad6395989e4b73de102ef0db730ac6d5c378daef7a2f521ad74c85121ed`
  from the successful pinned-source CI artifact.
- Web Console remains `1.6.127`; Authentication Service remains `v0.4.42`.
  Other components, the digest-pinned `v1.6.460` runtime base, persistent
  volume layout, and deployment settings remain as in
  [Server v1.6.464](server-1.6.464.md).
- The immutable Server image digest and source commit are recorded only after
  the release build and registry readback. Neither is inferred from this
  source candidate.

## Verification before publication

In an isolated environment, create an active project membership and confirm
that authorized direct reads succeed in both API versions. Remove that
membership while retaining its database row, then confirm that direct reads
return 404 in both versions and active collections omit it. Also test an
unrelated project ID, unauthorized update attempts, and the five-role
owner/member/restricted/readonly/noaccess UI and API matrix. The current
published UI should display permission and missing-resource errors through its
existing localized messages. Record the exact tested image digest, QA cleanup
result, Server startup and restart, SBOM and security scan before publishing.

## Upgrade and rollback

After `v1.6.465` is built and its immutable digest is verified, update only
the Server image tag from `v1.6.464`. Preserve the existing Compose
environment, named volumes, restart policy, Docker socket, AppArmor, HTTPS
origin, OIDC configuration, performance parameters, and nftables setup. No
database migration is introduced. Rollback uses the preserved `v1.6.464`
image and the same configuration and volumes. This release procedure does not
deploy to a production host.
