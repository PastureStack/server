# PastureStack Server v1.6.313

This release adds provider-neutral OpenID Connect authentication while
retaining every runtime, Catalog, container-table, storage, console-workspace,
localization, and Docker-host compatibility change from v1.6.312.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.312`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.313`
- Authentication Service: `0.2.1`
- Web Console: `1.6.56-pasturestack.25`
- Newest supported Docker Engine remains `29.6.2`.

Exact source commits and reviewed artifact SHA-256 values are recorded below,
in the image environment, and in the GitHub release notes. Operational
coordinates continue to use semantic version tags.
Artifact hashes are verification evidence and are not written into Catalog,
API, Compose, Web Console, or active service image fields.

## Reviewed component coordinates

- Authentication Service source:
  `c9a3a9d67a43d474caa6fa63ace0a359cb1c72aa`
- Authentication Service artifact SHA-256:
  `7ce684ac6c54d5902b466660dd2a71fcce14a7226a80c57990433917438642c6`
- Web Console source:
  `9445f5a544afbe85a120e55309620695fb933a58`
- Web Console artifact SHA-256:
  `546bcdec0b9d73c13e75afec80d739c86c8a62eda5f8df64b82bbec03bbe880a`

## OpenID Connect behavior

- One generic OpenID Connect configuration supports standards-compliant
  providers without vendor-specific buttons or data fields.
- Authorization-code login supports discovery, PKCE S256, nonce validation,
  asymmetric ID-token signatures, UserInfo subject matching, custom
  certificate authorities, and configurable profile and group claims.
- The client secret uses the existing encrypted authentication-configuration
  storage and is never returned to the browser after it has been saved.
- The access-control page validates configuration first, then performs a real
  test login without changing the active authentication method.
- Activation requires an explicit administrator action and a fresh,
  single-use authorization code. The normal platform token endpoint creates
  the final browser session.
- Existing local authentication remains the recovery channel throughout the
  test-before-enable flow. A failed final exchange restores the previous
  authentication configuration and retains the administrator's existing
  session.
- All 13 selectable Web Console locales contain the complete OpenID Connect
  message contract, including Taiwan-localized Traditional Chinese.

## Validation

- Authentication Service race-enabled tests cover discovery, authorization
  code exchange, PKCE, nonce, issuer, audience, issued-at time, asymmetric
  signing keys, UserInfo subject matching, unsafe endpoints, ambiguous keys,
  schema defaults, and request-size limits.
- Authentication Service and Web Console release workflows each build the
  selected source commit twice and require byte-identical artifacts.
- Web Console browser tests, source gates, localization parity, and production
  build validation must pass before publication.
- All 48 Server source gates must pass. Two Server candidate builds must
  produce the same image, followed by embedded-artifact inspection, isolated
  startup, controlled restart, live OpenID Connect test-provider validation,
  local-authentication recovery, and anonymous GHCR pull.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
