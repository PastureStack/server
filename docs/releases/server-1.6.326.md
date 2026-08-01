# PastureStack Server v1.6.326

This release retains the complete `v1.6.325` database, API Explorer,
authentication, authorization, Catalog, Orchestration Engine, node-agent, and
host compatibility behavior while replacing only the embedded Web Console.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.325`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.326`
- Web Console: `1.6.56-pasturestack.37`
- Web Console source: `d6a08d34469258ce6f9288cbc8d857f795f6a641`
- Web Console artifact SHA-256:
  `f0966f47f70987ee67b658a6ed3618e2a47c502e2edd63653fa7af526c6995f9`

Operational image coordinates use semantic version tags. Artifact and image
hashes remain verification evidence and are not written into user-facing image
fields.

## Web runtime boundary

The embedded Web Console now uses Ember and Ember CLI `6.12`, the active LTS
line selected for this compatibility release. The modern runtime remains
behind a reviewed global compatibility bridge so the existing classic
application behavior can be preserved without presenting an untested Ember 7
module conversion as complete.

The project subscription disconnect callback no longer creates a second
connection while the socket utility already owns the automatic reconnect
timer. When route activation explicitly creates a replacement connection, the
close handler preserves its state and does not queue a competing timer. A late
close event from an older connection also cannot clear the replacement. This
removes the race that could log `Socket refusing to connect while another
socket exists` after a server restart. Expired interactive terminal session
identifiers are intentionally not reusable; opening a new terminal creates a
new authenticated WebSocket session.

The exact source passed the complete Chrome test suite, Node.js 24 lock and dependency gates,
Traditional Chinese and ICU localization checks, source artifact layout gates,
and two byte-identical production builds. The release archive contains the
exact Ember MIT license with SHA-256
`84e97eb6663fa5fa07f36661e6040ab8a557b165c13860e2e72c1a692ca3c2a0`,
its pinned upstream provenance, 13 production locale files, no pseudo-locale,
and no source maps.

The release gate also requires non-empty light, light RTL, dark, and dark RTL
theme stylesheets. Ember Fetch `5.1.3` retains its pinned upstream provenance.
The production runtime uses Ember Power Select `9.0.2`, Ember Basic Dropdown
`9.0.0`, Ember Concurrency `5.2.0`, and Ember Modifier `4.3.0`. Their exact
upstream provenance and license files are verified again while assembling and
inspecting the Server image. The legacy dependency licenses retained in the
source artifact are checked separately from these production runtime packages.

## Preserved behavior

The API Explorer remains `1.1.15`, the Orchestration Engine remains
`0.183.273`, the Authentication Service remains `0.2.5`, and the vSphere CLI
bundle remains `0.55.1-pasturestack.1`. Image assembly compares their critical
executable and API Explorer hashes with `v1.6.325`.

No database schema, state volume, authentication policy, account record,
Catalog template, workload, node-agent coordinate, or host registration is
changed by this patch.

## Release acceptance requirements

- The Server source gates and Web Console runtime patch gate must pass.
- Two no-cache image builds must produce the same image identifier.
- The Web Console release asset must be downloaded anonymously and match the
  pinned SHA-256 value.
- High and Critical image vulnerabilities and secret findings must be zero.
- An isolated candidate must use a copy of the formal data and preserve stable
  API object counts, account business fingerprints, credentials, Docker socket,
  networking, volumes, and restart policy.
- Browser acceptance must include a new terminal session, a forced project
  subscription reconnect, login, Traditional Chinese locale, Catalog, API
  Explorer, and the existing account-security flow.
- Formal `8080` cutover must retain an exact stopped rollback container and
  record the deployment state.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
