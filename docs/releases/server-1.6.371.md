# PastureStack Server v1.6.371

Server v1.6.371 embeds Web Console `1.6.74`, which restores the hidden-state
compatibility contract required after the Bootstrap 5 migration.

## Operator-visible result

- Inactive full-screen underlays are removed from hit testing, so authenticated
  navigation and page controls remain clickable.
- Audit logs retain exact time-range, environment, and friendly user filters,
  plus addable event, description, resource, source-IP, and authentication
  conditions.
- The existing audit table, sorting, pagination, and detail view remain
  unchanged.

## Bound release inputs

- Web Console: `1.6.74`
- Web Console source: `2818786f41998e4d419620abf3cebdc5f7185a9a`
- Web Console archive SHA-256: `09722a8e754ba7bcbd8a2b8eb1a581f89885591ce8dbe9540486e7d7d53c8bc2`
- Web Console validation run: `33177330126`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its SHA-256, archive layout,
absence of links and source maps, localized labels, hidden-overlay contract,
and executable Bootstrap runtime boundary are verified. The existing Server
publish workflow performs the final merged-rootfs vulnerability scan, SBOM,
restart smoke, provenance, and immutable release. Any unmatched vulnerability
at any severity remains a release blocker.
