# Server v1.6.591

Published image: `ghcr.io/pasturestack/server:v1.6.591@sha256:5f45c51a9b9fdc226281f1099d841b601803c8b8d98a06ca34dbc13714a1cc5b`.

Source commit: `f3913bbc4c4ebe3431024dc4426afe5b4ef111ab`.

## Known limitation

Do not deploy this image. Its Compose0.14.45 archive and executable are the
qualified patched bytes, but `PASTURESTACK_COMPOSE_EXECUTOR_COMMIT` still names
the previous producer. Deployment qualification rejected this mismatch before
8080 was changed. The immutable tag is preserved; Server592 supplies the corrected
provenance and a pre-build coordinate-consistency guard.

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
