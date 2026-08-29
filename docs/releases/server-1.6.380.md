# PastureStack Server v1.6.380

Server v1.6.380 embeds Web Console `1.6.83` and completes the audit-log
investigation experience with a fluid, slot-style infinite time wheel and
verified compound filters. Server `v1.6.358` remains a visual reference only;
no application code, dependency, runtime, security fix, or current feature is
reverted.

## Operator-visible result

- Mouse-wheel and arrow-key input animate each 15-minute step before committing
  the selected value, with buffered rows above and below the visible window.
- Rapid input is queued one row at a time, so forward and reverse motion stays
  continuous without skipped values or hard jumps.
- A bounded completion fallback prevents the wheel from remaining stuck when a
  browser delays or omits the CSS `animationend` event.
- Time, environment, user, operation source, event, description, resource,
  client IP, and authentication filters use AND semantics and have positive and
  negative verification coverage.
- The change remains confined to the audit-log filter; the result table and
  other application pages are unchanged.

## Bound release inputs

- Web Console: `1.6.83`
- Web Console source: `6ae840b47cf02d8b1cd0d94e827558477ca3c784`
- Web Console archive SHA-256: `dc022c7c3027d7c4b7bb27e58626af00304d9dbbcf09e460c0e5b1a72634e48a`
- Web Console validation run: `33260206517`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.83>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The release keeps Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and all existing runtime
hardening.
