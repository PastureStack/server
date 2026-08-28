# PastureStack Server v1.6.374

Server v1.6.374 embeds Web Console `1.6.77`. It preserves the login and locale
compatibility repair from 1.6.76 and ensures audit-log text operators are stored
in the query-backed filter state.

## Operator-visible result

- Login, Traditional Chinese selection, and authenticated routes initialize
  reliably before and after locale bootstrap.
- Audit logs support local time ranges, named environments, named users, and
  addable text conditions with exact, contains, prefix, exclusion, and
  not-contains operators.
- Selected text operators survive query serialization and route refresh.
- The audit table, sorting, pagination, and detail view are unchanged.

## Bound release inputs

- Web Console: `1.6.77`
- Web Console source: `6ec6d9a35540e66dba0d9210db24ecd35ce367fc`
- Web Console archive SHA-256: `999e4cb9d809ea01d280c39cd27cc75797f8e61baf7c198e938c9c77412daf61`
- Web Console validation run: `33197097278`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow verifies the embedded Web Console archive, runs
start and restart smoke tests, scans the merged root filesystem, generates an
SBOM and provenance, pushes the immutable image, and creates the matching
immutable release. Any unresolved vulnerability remains a release blocker.
