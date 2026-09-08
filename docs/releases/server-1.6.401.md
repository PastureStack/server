# PastureStack Server v1.6.401

This release makes Catalog install and upgrade version choices concise and
consistent without changing any workload image reference or runtime contract.

## Operator-visible result

- Every current infrastructure and project template displays a plain numeric
  semantic version such as `v0.3.16`; internal brand and Windows platform
  suffixes no longer appear in the version selector.
- The 22 template defaults remain bound to their newest version directories,
  and each template's visible upgrade versions remain unique.
- Container image references, compatibility requirements, template questions
  and deployment behavior are unchanged.

## Bound release input

- Catalog Templates source:
  `d8641d291d7262c07251ba64e06c229a7db5e4b5`
- Catalog source validation: 22 templates, 48 image references and no
  deployable-image blockers.
- The CA bootstrap package is fetched from its official Launchpad file URL and
  remains pinned to the byte-identical SHA-256 used by v1.6.400.
- Because this release changes only image metadata and the Catalog authority,
  its runtime filesystem is inherited byte-for-byte from the immutable
  `v1.6.400` digest. This avoids rebuilding unrelated native dependencies while
  the final merged rootfs is still scanned and exercised by the normal release
  smoke test.
- Web Console remains `1.6.101`; Node Agent remains `v0.13.27`; Orchestration
  Engine remains `0.183.289`.

Publication retains the same source gates, initial and restart smoke,
merged-rootfs vulnerability and secret scan, SBOM, provenance, attestation and
immutable release requirements as v1.6.400.

The runtime still carries the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`. An unmatched vulnerability at any severity remains a release blocker.
