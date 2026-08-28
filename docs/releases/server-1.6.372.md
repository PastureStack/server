# PastureStack Server v1.6.372

Server v1.6.372 embeds Web Console `1.6.75`, which restores the global
dropdown destination required by the maintained PowerSelect runtime.

## Operator-visible result

- Audit-log environment and user selectors now render their actual options
  instead of opening an empty dropdown.
- The legacy Bootstrap positioning shim no longer throws when Bootstrap 5
  owns a dropdown's positioning.
- Time ranges, addable conditions, the existing audit table, sorting,
  pagination, and detail view remain unchanged.

## Bound release inputs

- Web Console: `1.6.75`
- Web Console source: `7499f6e49cd5cc3acfd488f89cae95b618d8b114`
- Web Console archive SHA-256: `d27442f880bb42a91441019dc9ef7f780035065389f981bcbe07be07db059ecb`
- Web Console validation run: `33181387689`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its SHA-256, archive layout,
absence of links and source maps, localized audit-filter labels, dropdown
destination, and executable Bootstrap runtime boundary are verified. The
Server publish workflow performs the merged-rootfs vulnerability scan, SBOM,
restart smoke, provenance, and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
