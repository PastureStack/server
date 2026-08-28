# PastureStack Server v1.6.369

Server v1.6.369 embeds Web Console `1.6.72`, which restores the production UI
bootstrap while retaining the audit-log filter builder introduced in 1.6.71.

## Operator-visible result

- The login page and authenticated application now boot under Ember 7 without
  importing the removed global `ember` module.
- English and Traditional Chinese messages render through the Ember Intl 9
  flat-key format instead of showing missing-translation placeholders.
- Audit logs retain exact time-range, environment, and friendly user filters,
  plus addable event, description, resource, source-IP, and authentication
  conditions.
- The existing audit table, sorting, pagination, and detail view remain
  unchanged.

## Bound release inputs

- Web Console: `1.6.72`
- Web Console source: `86eff624661d41c5f7bca56c9ac8af733f2a8551`
- Web Console archive SHA-256: `be83ca8b036504c3e70710d9cd27c49064f9866f216f3949ae9235a0a98857bd`
- Web Console validation run: `33165643503`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its SHA-256, archive layout,
absence of links and source maps, localized labels, and audit-filter runtime
markers are verified. The existing Server publish workflow performs the final
merged-rootfs vulnerability scan, SBOM, restart smoke, provenance, and
immutable release. Any unmatched vulnerability at any severity remains a release blocker.
