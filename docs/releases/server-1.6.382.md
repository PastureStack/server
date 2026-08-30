# PastureStack Server v1.6.382

Server v1.6.382 embeds Web Console `1.6.85` and fixes the audit-log filter
completion path without changing the result table, time selector, or other page
regions.

## Operator-visible result

- **Clear all** no longer remains stuck on “Updating results” when the resulting
  query parameters are identical to the current URL.
- Reapplying an unchanged filter query now performs one explicit refresh and
  always returns the controls to their ready state.
- Clearing optional conditions restores a bounded last-24-hours query that
  exactly matches the time range shown in the filter panel.
- Changed query parameters still use Ember's normal route transition, avoiding
  a duplicate request.

## Verification

- Focused audit-log controller and route tests: `16/16` passed.
- Full Web Console QUnit suite: `370/370` passed.
- Web Console validation run: `33286795013`; source gates, tests, and two
  byte-identical production builds passed.
- The immutable Web Console release archive was verified at SHA-256
  `ba54eed407cdea0a00d91102a81e9716b092ddf53f1c4ff0cdedf315f0dea2bf`.

## Bound release inputs

- Web Console: `1.6.85`
- Web Console source: `3f3ec2acd4664cd31ff5de9c5769c8a19531c3fb`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.85>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

This release retains Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and the existing runtime
hardening.
