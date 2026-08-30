# PastureStack Server v1.6.384

Server v1.6.384 embeds Web Console `1.6.87` and closes the two remaining
locale-selector defects without changing the audit result table or unrelated
pages.

## Operator-visible result

- The audit time-range calendar now follows the selected application locale
  for month names, weekdays, date formatting, and the locale's week start.
  It no longer depends on the Chrome user-interface language.
- The footer language menu opens upward, remains aligned to its trigger, and
  stays inside the viewport instead of shifting beyond the right edge.
- All 13 selectable locales include the calendar labels used by the new
  application-rendered date picker.
- Existing audit filters, query parameters, time wheels, result table, and
  application layout remain unchanged.

## Verification

- Web Console QUnit: `373/373` passed, including localized calendar and footer
  menu viewport-boundary tests.
- Localization quality: missing `0`, orphan `0`, invalid ICU `0`.
- Web Console validation run: `33318984639`; source gates, tests, and two
  byte-identical production builds passed on Node.js `24.20.0`.
- The Web Console release archive was verified at SHA-256
  `25ca6c0a1ed1f3f9e55d40cee454609718522d6cf7ff446d4b19e85ae38bffc6`.

## Bound release inputs

- Web Console: `1.6.87`
- Web Console source: `177dfbccde2ae691b9426aedd8d60b0f7cfeaa36`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.87>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and the existing runtime
hardening.

The image retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.

The Server publish workflow still performs the merged-rootfs vulnerability
scan, SBOM, restart smoke, provenance, and immutable release. Any unmatched vulnerability at any severity remains a release blocker.
