# PastureStack Server v1.6.370

Server v1.6.370 embeds Web Console `1.6.73`, which restores Bootstrap 5
interaction execution at application boot.

## Operator-visible result

- Authenticated navigation collapse and dropdown controls work in the packaged
  production console instead of remaining inert.
- Audit logs retain exact time-range, environment, and friendly user filters,
  plus addable event, description, resource, source-IP, and authentication
  conditions.
- The existing audit table, sorting, pagination, and detail view remain
  unchanged.

## Bound release inputs

- Web Console: `1.6.73`
- Web Console source: `73586670dd20bc6f835cb8155571ba8d5ad1ff3e`
- Web Console archive SHA-256: `54b57c983cfc25d8518914c1c09de512f8c384482b5c3f3b0329e00381364db1`
- Web Console validation run: `33173024470`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its SHA-256, archive layout,
absence of links and source maps, localized labels, and executable Bootstrap
runtime boundary are verified. The existing Server publish workflow performs
the final merged-rootfs vulnerability scan, SBOM, restart smoke, provenance,
and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
