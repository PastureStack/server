# PastureStack Server v1.6.379

Server v1.6.379 embeds Web Console `1.6.82` and fixes the audit-log time
selector's actual browser input binding. Server `v1.6.358` remains a visual
reference only; no application code, dependency, runtime, security fix, or
current feature is reverted.

## Operator-visible result

- Mouse-wheel input now advances either time boundary through the native DOM
  `wheel` event instead of relying on an event absent from Ember's dispatcher.
- Each wheel step keeps the existing infinite 15-minute progression, centered
  five-row selection, and animated transition state.
- Arrow-key support uses the native `keydown` event on the same scoped control.
- The change remains confined to the audit-log filter; the result table and
  other application pages are unchanged.

## Bound release inputs

- Web Console: `1.6.82`
- Web Console source: `dde731f1191e5dd333619d70f9f9ab18deb39e05`
- Web Console archive SHA-256: `ceb9f9c1fe687601cc9725ff83e161675b8b231e4042af2ae64915c1c1fa9ddd`
- Web Console validation run: `33254687163`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.82>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The release keeps Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and all existing runtime
hardening.
