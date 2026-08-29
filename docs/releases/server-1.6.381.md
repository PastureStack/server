# PastureStack Server v1.6.381

Server v1.6.381 embeds Web Console `1.6.84` and corrects the audit-log
time-range interaction without reverting current application code, dependencies,
security fixes, or features.

## Operator-visible result

- The time-range editor now applies motion only to the three intended columns:
  hour, minute, and AM/PM.
- Wheel and touch movement use a monotonic ease-out, then snap to the nearest
  exact value without spring-back or reverse oscillation.
- The hour, minute, and AM/PM columns visually repeat around the current value,
  support mouse wheel and keyboard input, and recenter invisibly after selection.
- Date fields remain direct calendar inputs; the removed whole-range 15-minute
  animation no longer interferes with date selection.
- Event-type and description operators are now carried into the actual API
  query, including prefix and negative matching.
- The result table and all non-filter page regions remain unchanged.

## Verification

- Web Console unit suite: `367/367` passed.
- Web Console validation run: `33265488164`; source gates and two byte-identical
  production builds passed.
- Real API validation covered time, environment, user, operation source, event,
  description, resource, client IP, and authentication filters with AND
  semantics, plus a negative zero-result control.
- Browser motion sampling was monotonic and settled on the exact 36-pixel row
  boundary.

## Bound release inputs

- Web Console: `1.6.84`
- Web Console source: `b208744711c6e7e3f43504fd807fa301abb2558f`
- Web Console archive SHA-256: `8e7a4343766ebf98cf69f94797f3bd335741a0638b8557df161a4657ae473e1f`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.84>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The release keeps Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL
`3.5.8`, zlib `1.3.2`, the current OpenVEX closure, and all existing runtime
hardening.
