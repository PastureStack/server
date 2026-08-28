# PastureStack Server v1.6.368

Server v1.6.368 updates the embedded Web Console to `1.6.71` and keeps the
continuous Docker Engine support interval introduced in v1.6.367.

## Operator-visible change

- Audit logs now provide a dedicated filter panel with exact time range,
  environment, and friendly user selectors.
- Additional conditions can be added or removed for event type, description,
  resource, source IP, and authentication type.
- Text conditions support exact, contains, starts-with, not-equal, and
  not-contains matching.
- The existing audit table, sorting, pagination, and detail view are unchanged.

## Bound release inputs

- Web Console: `1.6.71`
- Web Console source: `040ee8ac2c7454ac8a56c330f6496b09863e810b`
- Web Console archive SHA-256: `386e00ad85d86d073fe2d9d46fc875d3d8a4ac347f0833c1abbaaad01dccfea5`
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Web Console archive is accepted only after its SHA-256, archive layout,
absence of links/source maps, localized labels, and audit-filter runtime markers
are verified. The final merged-rootfs vulnerability scan, SBOM, restart smoke,
provenance, and immutable release are produced by the existing Server publish
workflow. Any new or unmatched vulnerability at any severity remains a release blocker.
