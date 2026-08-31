# PastureStack Server v1.6.386

Server v1.6.386 embeds Web Console `1.6.89` and rebalances the audit-log
results table so the final authentication/IP heading receives useful default
space without removing its longer-locale wrapping protection.

## Operator-visible result

- The identity column default is reduced from `175` to `150` pixels.
- The authentication/IP column default is increased from `150` to `300`
  pixels and can receive useful remaining table width.
- Japanese and similarly sized headings are no longer forced to wrap merely
  because left-side columns consumed the table width.
- Longer translations still wrap inside the final cell instead of clipping or
  causing horizontal page overflow.
- Audit filters, result rows, column order, resizing behavior, and unrelated
  pages remain unchanged.

## Verification

- Web Console QUnit: `373/373` passed.
- Web Console validation run: `33344232400`; source gates, tests, and two
  byte-identical production builds passed on Node.js `24.20.0`.
- The Web Console release archive was verified at SHA-256
  `2347e9b5ddec67fce341dd8cdf76e3c54ed2777cf7cb80a943f16f070e98142c`.

## Bound release inputs

- Web Console: `1.6.89`
- Web Console source: `a4c65158a88f4761ad0ac7f407bf2c66e07505ff`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.89>
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
