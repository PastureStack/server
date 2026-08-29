# PastureStack Server v1.6.378

Server v1.6.378 embeds Web Console `1.6.81` and completes the
permission-scoped audit investigation experience. Server `v1.6.358` remains
a visual reference only; no application code, dependency, runtime, security
fix, or current feature is reverted.

## Operator-visible result

- Time, environment, user, and operation source use one consistent filter-card
  system while the existing result table structure remains unchanged.
- The centered time dialog provides animated, infinite 15-minute wheels,
  direct input, and quick presets; the selected range is applied using
  `[from,to)` semantics and cannot be overwritten by a stale poll.
- Environment, user, and suggestion values are derived only from records the
  signed-in account may access. Users are shown as human labels rather than raw
  account IDs.
- WebUI, API, automation, system, IP, event, resource, description, and
  authentication filters can be combined for incident investigation.
- XLSX, CSV, and JSON exports use the same permission and time-bounded query,
  include request/trace identifiers, neutralize spreadsheet formulas, and omit
  raw request/response payloads.
- Result ordering uses natural comparison for human names and numeric suffixes.

## Bound release inputs

- Web Console: `1.6.81`
- Web Console source: `2249dccfef34cc7d6bd9741915473a7fefcd8cc6`
- Web Console archive SHA-256: `b0fb4a71e670c3366db5ad0af9946c7a7d5075df26e226514f7e84bd0269ab50`
- Web Console validation run: `33252007325`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.81>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The release keeps Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and all existing
runtime hardening.
