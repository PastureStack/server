# PastureStack Server v1.6.330

This release retains the complete `v1.6.325` database, authentication,
authorization, orchestration, host-agent, API Explorer, and workload behavior.
It replaces the embedded Web Console and the console-broker executable while
retaining the pinned first-party Catalog snapshot and all persisted workload
definitions.

## Runtime coordinates

- Base image: `ghcr.io/pasturestack/server:v1.6.325`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.330`
- Web Console: `1.6.56-pasturestack.41`
- Web Console source: `c6e3cef5bd0376087543df2fbf6db68715ebaa6c`
- Web Console artifact SHA-256:
  `b89584ae644bb4f1ee3d1919bb194e8cf212f1eae9e8b923168ef16f4e6f9976`
- Catalog snapshot: `57707ddf891e36066a144d7821adc458dbf8da9c`

Operational image coordinates use semantic version tags. Hashes are integrity
evidence and are not written into user-facing image fields.

## Terminal recovery and layout fixes

The broker status endpoint now represents a missing or expired console session
as an HTTP `200` response with `{"status":"missing"}` and `Cache-Control:
no-store`. The Web Console treats that explicit state as a request to create a
new session through the existing container execute action. It also retains the
HTTP `404` compatibility path when paired temporarily with an older broker.

This prevents a normal stale-session recovery from being reported as a failed
network request in browser diagnostics. It does not hide authorization,
credential-conflict, transport, or server errors.

The terminal and log resize handle is reduced from 22 by 22 pixels to 11 by 11
pixels. It remains keyboard-labelled and pointer-resizable but now stays within
the footer corner instead of covering the rightmost control.

The exact Web Console source passed all 295 Chrome tests and 783 assertions.
Two clean production builds were byte-identical. The archive contains 13
production locale files, no pseudo-locale, no source maps, and the verified
upstream license and provenance files required by Server image assembly.

The console broker is rebuilt reproducibly with Go `1.26.5`; its package tests
and a dedicated missing-session response test run during image assembly.

## Preserved components

The API Explorer remains `1.1.15`, the Orchestration Engine remains
`0.183.273`, the Authentication Service remains `0.2.5`, and the vSphere CLI
bundle remains `0.55.1-pasturestack.1`. Image assembly compares their critical
executables and the API Explorer tree with `v1.6.325`.

No database schema, account, permission, authentication policy, workload,
node-agent coordinate, host registration, Docker socket, or persisted volume is
changed by this patch.

## Release acceptance requirements

- All Server source gates and console-broker package tests pass.
- Two clean image builds produce the same image identifier.
- The Web Console release asset downloads anonymously and matches its pinned
  SHA-256 value.
- An isolated candidate returns a recoverable `missing` status for an expired
  session without an HTTP failure and preserves the expected API object counts.
- Browser acceptance covers login, Traditional Chinese, OpenID Connect
  settings, project subscriptions, stale-session recovery, and the resized
  terminal and log handle.
- Formal `8080` cutover keeps the proven `v1.6.329` image and original persistent
  volumes available as an exact rollback target until acceptance completes.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
