# PastureStack Server v1.6.385

Server v1.6.385 embeds Web Console `1.6.88` and keeps the final audit-log
results heading readable in longer locales without changing the table's data
or structure.

## Operator-visible result

- The authentication/IP heading wraps inside its existing cell instead of
  being clipped by the table's bounded viewport. This directly covers the
  Filipino `Paraan ng Authentication／IP Address` label.
- The style is scoped to the final heading of the audit-log results table and
  is present in all four light, dark, LTR, and RTL theme assets.
- Audit filters, result rows, column order, resizing behavior, and unrelated
  pages remain unchanged.

## Verification

- Web Console QUnit: `373/373` passed.
- Web Console validation run: `33321412671`; source gates, tests, and two
  byte-identical production builds passed on Node.js `24.20.0`.
- The Web Console release archive was verified at SHA-256
  `c0dbbe076043e30e2619c89adbd13f284026cf734938dceb28b06090ae88ea9c`.

## Bound release inputs

- Web Console: `1.6.88`
- Web Console source: `2f9bb4fce5f831119a3770d593e78425ad6a5fd8`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.88>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and the existing runtime
hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow performs the merged-rootfs vulnerability scan,
SBOM, restart smoke, provenance, and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
