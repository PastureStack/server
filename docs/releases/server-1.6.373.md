# PastureStack Server v1.6.373

Server v1.6.373 embeds Web Console `1.6.76`, restoring the locale compatibility
required by Ember Intl 9 while preserving the completed audit-log filters.

## Operator-visible result

- The login page, language selector, and authenticated routes initialize
  reliably before and after locale bootstrap.
- Traditional Chinese selection is readable and remains active after login.
- Audit-log time range, environment, user, and addable-condition filters remain
  available without changing the existing table, sorting, pagination, or detail
  view.
- Login warning and error messages retain readable contrast.

## Bound release inputs

- Web Console: `1.6.76`
- Web Console source: `423c70862b70843da510464856614c6e4b513268`
- Web Console archive SHA-256: `cb4164ee9e4ec45f2065b54b498206c667aa92d0672508ce92f5c948d66bf765`
- Web Console validation run: `33192974289`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its immutable release digest,
archive layout, locale and audit-filter tests, localized labels, dropdown
destination, and production build are verified. The Server publish workflow
performs the merged-rootfs vulnerability scan, SBOM, restart smoke, provenance,
and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
