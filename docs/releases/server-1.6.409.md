# PastureStack Server v1.6.409

This release completes the container logs and interactive shell repair from
v1.6.408 by handling the short backend-registration interval after a Server
restart.

## Operator-visible result

- Container log and shell windows retain the v1.6.408 internal WebSocket
  Origin repair.
- If the authenticated node backend is still registering after a Server
  restart, session creation retries the exact same fixed internal endpoint up
  to three times instead of immediately leaving the window in an error state.
- Retries apply only to HTTP 401 from the internal WebSocket proxy, use a fixed
  five-second interval, honor request cancellation, and stop after three total
  attempts. Other handshake failures remain fail-closed without retry.
- Existing Web Console HTML, CSS, layout, translations, action menus, charts,
  audit filters, volumes, port bindings, and runtime settings are unchanged.

The console-broker tests cover both logs and terminal Origin rebinding, a
backend that becomes available during the bounded retry window, exhaustion at
exactly three attempts, cross-origin rejection, authenticated attachment,
terminal ownership, replay, capacity, and termination.

The release uses the same immutable Web Console `1.6.102`, Orchestration Engine
`0.183.293`, Compose Executor `0.14.36`, catalog commit
`06dfff6234ba8bf163d98e148cc61c0ebd0b2656`, and runtime base as v1.6.408.
Publication still requires initial and restart smoke tests, a merged-rootfs
vulnerability and secret scan, CycloneDX SBOM, provenance and SBOM
attestations, and an immutable GitHub Release. Any unmatched vulnerability at any severity remains a release blocker.

The unchanged runtime base retains the glibc fix
`9765a538ebf8661a6e5578e01e35a3dd30db7eb4`, GNU coreutils fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, the OpenSSL closure for
`CVE-2026-75803`, and removal of the unreachable `diff3` path for
`CVE-2026-53910`.
