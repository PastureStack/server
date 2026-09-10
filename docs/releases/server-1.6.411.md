# PastureStack Server v1.6.411

This release fixes the OpenID Connect browser flow behind an HTTPS-terminating
reverse proxy without changing the established platform API, database, or
container-runtime contracts.

## Operator-visible result

- Web Console `1.6.103` displays nested OIDC validation errors instead of an
  empty alert, activates a validated provider for unrestricted valid external
  identities, and clears an authenticated browser session only after an actual
  HTTP 401 or 403 response. An unrelated initialization failure is shown rather
  than being misreported as a timed-out login.
- WebSocket Proxy `0.23.14` accepts the optional
  `PROXY_PLATFORM_PUBLIC_ORIGIN` deployment setting. It applies that exact
  public HTTP(S) origin only when the request Host matches the configured
  authority, so internal HTTP hops can produce HTTPS absolute API links without
  trusting a foreign Host.
- The Console Broker marks `/v1*`, `/v2*`, and `/v3*` platform API responses
  `Cache-Control: private, no-store`, removes upstream `Age`, and preserves the
  cache policy of fingerprinted static assets.

For a public deployment such as `https://stack.example.com`, configure:

```yaml
environment:
  PROXY_PLATFORM_PUBLIC_ORIGIN: https://stack.example.com
```

The value cannot contain credentials, a path, query, or fragment.

## Reviewed artifacts

- Web Console `1.6.103`, source commit
  `00ff7a76a1606aab4fc5c08e0c863989d266eec9`, archive SHA-256
  `8d469d7eb3329402a3a201bdbd8d7a0bc3c1600eb0bdf3a5c99f0d7484fc65ee`.
- WebSocket Proxy `0.23.14`, source commit
  `3b5788bdc52f4edab0097a3d97afccf138c64089`, archive SHA-256
  `c55108c3dbfd8e6579fc768a1988920db83c6f605ca1284b60edf92ae8d0160e`,
  and installed binary SHA-256
  `efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d`.
- Orchestration Engine `0.183.295`, source commit
  `6c7922b492b45eccb28e46fe485864104a9ed075`, and release JAR SHA-256
  `f06f1ebff2457f87f93402562007fcb29cd34d5afc00d15940c4a2e63947166e`
  preserve the reviewed public-origin setting in the Engine-managed proxy
  process. API Explorer `1.1.18`, Compose Executor `0.14.36`, Node Agent
  `0.13.27`, and the remaining reviewed runtime coordinates are unchanged
  from `v1.6.410`.

## Release validation

Publication requires source gates; Console Broker unit and vet checks; a clean,
no-cache image build; initial and restart `pong`; and an integrated request
through the public `:8080` broker. The integrated check requires
`X-Api-Schemas: https://stack.example.test/v2-beta/schemas` and private,
no-store headers on both `/v2-beta/accounts` and `/v1-auth/config` before and
after restart. Merged-rootfs Trivy vulnerability and secret scans, CycloneDX
SBOM generation, provenance and SBOM attestations, and an exact-source GitHub
Release remain mandatory. Any unmatched vulnerability at any severity remains a release blocker.

These deterministic checks prove the packaged proxy and browser logic. A real
Synology OIDC plus TOTP browser login still depends on the deployment's issuer,
client, callback, claims, certificates, and outer reverse-proxy configuration;
perform that one interactive login after installing this release.

The runtime security layer uses the signed Ubuntu snapshot from 2026-09-10,
including the official curl, libcurl3t64-gnutls, and libcurl4t64
`8.18.0-1ubuntu2.5` fix for `CVE-2026-8932`, plus glibc
`2.43-2ubuntu2.4` and Perl `5.40.1-7ubuntu0.2` packages.
Ubuntu still marks `CVE-2026-18374` as needing evaluation for Resolute; its
OpenVEX status remains an explicit runtime-path determination rather than a
claim that the package revision fixes it. GNU coreutils `uniq` retains upstream
fix `d64e35a8a4c0e4608321433e0d84d917e4e36371`; the OpenSSL closure for
`CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910` are unchanged.
