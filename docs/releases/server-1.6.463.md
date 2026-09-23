# Server v1.6.463

PastureStack Server v1.6.463 packages Orchestration Engine 0.183.320 and the
unchanged Web Console 1.6.126. The Engine checks the requested project before
loading a project-member collection. A token authorized for project A cannot
combine `X-API-Project-Id: A` with `?projectId=B` to read B's members through
`/v1/projectMembers` or `/v2-beta/projectMembers`. Malformed or unauthorized
project IDs return 404 before a membership read. Direct member-ID access keeps
its existing project check.

## Immutable component coordinates

- Orchestration Engine `v0.183.320`, release commit
  `268469153c299987bd42e288dd68bb62af91002e`, release asset `cattle.jar`
  SHA-256 `8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e`,
  and CycloneDX asset `cattle-cyclonedx.json` SHA-256
  `9869f1d6bd9ca5a193a89bc5d68d5ccae79b26291c320766df7332c078c7ae7e`.
- Web Console remains `1.6.126`, commit
  `5cba85d3ab954c416b86910f760f987ec2bfc526`, release artifact SHA-256
  `a278904a10ce757510ed516507bd3926b02bab42a52a27bd153ff5e94e2998aa`.
- The remaining component coordinates and the digest-pinned `v1.6.460` base
  remain those of [Server v1.6.462](server-1.6.462.md).

## Release and QA verification

The Engine commit and both artifact digests are pinned to the immutable
`v0.183.320` GitHub Release. The Server source gate, image build, merged
runtime scan, SBOM identity check, and candidate startup/restart must pass for
the exact Server commit. On isolated QA, run v1 and v2-beta project-member
collection checks with an authorized header for A and query project B, plus
authorized collection and direct member-ID allow/deny cases. Preserve the
existing direct-user and OpenID Connect group role matrix.

## Upgrade and rollback

Upgrade from v1.6.462 by changing only the image tag after the new image is
published and verified. Preserve environment overrides, named volumes, Docker
socket, port 8080, restart policy, and AppArmor configuration. This Engine
change does not add a database migration.

Rollback uses the preserved v1.6.462 image and the same configuration and
volumes. That image contains Engine 0.183.319 and lacks this collection-read
authorization fix, so restrict access while diagnosing a rollback. Production
deployment is outside this release procedure.
