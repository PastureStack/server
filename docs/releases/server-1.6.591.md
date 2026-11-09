# Server v1.6.591 candidate

Prepared source only; no Server image or release has been published.

## Verified component inputs

Packages Compose Executor 0.14.45, retaining Engine 0.183.391, Web Console
1.6.233 and optional Bridge 0.2.35. A transitioning child could outlast the
three-second Compose wait; a wrapper then swallowed the timeout and all other
handler errors. The Stack could remain waiting until a later Engine retry.

The executor now observes each child for at most five minutes, publishes
original-event keepalive every ten seconds while pending, and lets the existing
worker report terminal errors. It never replays the handler or repeats an
already dispatched child action. Native rollback/finish owners, active-child
isolation, Stack environment restoration and authorization are unchanged.

Compose PR24 passed all eight required checks, original reproducible builds,
race tests, native compatibility and full security gates. Its twenty immutable
public assets and 21 release-attestation subjects were verified. Fresh binary
OpenPGP-absence evidence preserves the existing exact executable/module scope;
no vulnerability gate or authorization check is relaxed.

Matching 8080 rollback/finish, data preservation, refresh and restart acceptance
remain pending. Do not treat component or source checks as runtime PASS. Keep
the previous qualified Server container/image and all persistent volumes for
rollback; reverting restores the former short-wait limitation.
