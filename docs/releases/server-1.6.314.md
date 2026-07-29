# PastureStack Server v1.6.314

This release corrects the OpenID Connect callback origin discovered during the
live browser authorization-code test of v1.6.313. It retains every runtime,
Catalog, table, storage, console-workspace, localization, Ubuntu 26.04,
Java 25, Docker-host compatibility, and authentication change from v1.6.313.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.313`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.314`
- Authentication Service: `0.2.1`
- Web Console: `1.6.56-pasturestack.26`
- Newest supported Docker Engine remains `29.6.2`.

The Web Console now persists the browser origin as the canonical `api.host`
setting before asking the Authentication Service to prepare an OpenID Connect
authorization URL. This follows the established external-authentication
configuration pattern and prevents the displayed callback URI and the
server-generated callback URI from diverging when `api.host` was initially
empty.

## Reviewed component coordinates

- Web Console source:
  `1567d88583d82710d06696288a7bd6e4e20843ec`
- Web Console artifact SHA-256:
  `b8201d03433d5d5f45a1a04d1ec37e81e86a00c43802f9bea672be1c19813081`

## Validation

- The callback-origin regression has a browser-side unit test and a dedicated
  source gate.
- The Web Console workflow must pass all browser tests, locale parity and ICU
  checks, source gates, and two byte-identical production builds.
- All Server source gates must pass.
- Two no-cache Server builds must produce the same image before publication.
- The live OpenID Connect test must complete configuration preparation, PKCE
  S256 authorization, test-token exchange, explicit activation, platform
  session creation, failure restoration, and final local-authentication
  recovery.

Operational image coordinates use semantic version tags. Artifact and image
hashes are release evidence and are not written into user-facing image fields.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
