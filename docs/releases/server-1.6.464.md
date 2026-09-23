# Server v1.6.464

PastureStack Server v1.6.464 retains Orchestration Engine 0.183.320 and updates
Web Console 1.6.127. The console shows a localized, actionable error when an
environment or its environment member list cannot be loaded because the
resource is missing or the caller lacks permission. A 5xx environment-load
failure displays a localized retry message without exposing the raw server
response. A 403 or 404 during save identifies the failed project, membership,
or network-policy step. If an
earlier step may already have been stored, the message asks the operator to
refresh and verify before retrying. Identity search now distinguishes an empty
result, an expired session, forbidden access, and server or network failure.

The API permission decision remains on the Engine. The console follows the
project's `projectMembers` link and does not infer permission from a role name
or hide an API failure as an empty result.

## Immutable component coordinates

- Web Console `1.6.127`, artifact source commit
  `0f21118a871a1b72558a2fa11b4f33675fd6ae15`, signed release tag commit
  `580cb3bc472b9e8105787d76ca20b0189ace84bf`. Release archive
  `web-console-1.6.127.tar.gz` SHA-256:
  `dcaaad16bbdf38c82af1cecb9cfc0867dcceab76503f632e151da6a17952f852`.
- Both Web Console commits have source tree
  `cdfafb8c77963f61587298f593a90baa7b57e49f`. CI run `35892291179`
  produced the published archive using `SOURCE_DATE_EPOCH=1790182621` from the
  artifact source commit. CI run `35893346372` rebuilt the release tag with
  `SOURCE_DATE_EPOCH=1790182948`. The archive hashes differ only because the
  tar member modification times differ: all 140 member headers excluding
  modification time and all 123 file sizes, modes, and SHA-256 hashes match.
  Image metadata records the actual published archive's source commit.
- Orchestration Engine `v0.183.320`, commit
  `268469153c299987bd42e288dd68bb62af91002e`, `cattle.jar` SHA-256
  `8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e`.
- Authentication Service remains `v0.4.42`; the remaining component pins and
  digest-pinned `v1.6.460` runtime base remain as documented for
  [Server v1.6.463](server-1.6.463.md).

## Verification before publication

The source gate requires the final Web Console commit and archive digest. The
archive must pass SHA-256 verification and retain its own
`VERSION.txt`, all supported locale assets, and the compiled project-access
messages. Verify authorized environment view/edit/save, unauthorized project
and member-link load, permission-denied member and network-policy saves,
identity search failures, 5xx environment-load errors, and refresh after a
partial save in an isolated QA environment. Record the actual browser result
alongside the v1 and v2-beta project-member API matrix. The release image,
SBOM, scanner result, startup, and restart are release gates.

## Upgrade and rollback

After the immutable `v1.6.464` image and digest are published and verified,
upgrade from v1.6.463 by changing the image tag. Preserve environment
overrides, named volumes, Docker socket, port 8080, restart policy, and
AppArmor configuration. No database migration is introduced by this console
change. Rollback uses the preserved v1.6.463 image and the same configuration
and volumes. Production deployment is separate from this release procedure.
