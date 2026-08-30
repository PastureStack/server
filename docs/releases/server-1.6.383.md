# PastureStack Server v1.6.383

Server v1.6.383 embeds Web Console `1.6.86` and completes the audit-log filter
translations without changing the result table, filter behavior, time-wheel
animation, or any other page.

## Operator-visible result

- All 13 selectable locales now provide their own complete audit-log filter
  interface instead of inheriting the English filter-builder text.
- Time ranges, environments, users, operation sources, added conditions,
  shortcuts, export choices, result status, and time-dialog controls are
  localized together as one coherent workflow.
- Deleted users and unnamed environments have localized fallback labels.
- The existing filter behavior, query contract, result table, and page layout
  are unchanged.

## Verification

- Every selectable locale contains all `110` audit-log message keys.
- Localization quality: missing `0`, orphan `0`, invalid ICU `0`, untranslated
  audit-filter values `0`.
- Focused audit-log controller and route tests: `16/16` passed.
- Web Console validation run: `33292055054`; source gates, tests, and two
  byte-identical production builds passed.
- The Web Console release archive was verified at SHA-256
  `3e7afe1eb87990979f51ede5101fdf0a29eb2261a2057e5a45b35310c50d1783`.

## Bound release inputs

- Web Console: `1.6.86`
- Web Console source: `279da505680acda91ce7ed1028e4354b8abbd9fd`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.86>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and the existing runtime
hardening.
