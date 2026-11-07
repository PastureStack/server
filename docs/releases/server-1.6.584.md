# Server v1.6.584

Server `v1.6.584` packages Engine `0.183.386`, Web Console `1.6.226`, optional
Bridge `0.2.28`, Host API `0.38.9`, Node Agent `0.13.35`, Catalog `0.20.17` and
Compose `0.14.43`. The bootstrap Agent remains `1.2.34`.

## Changes

- Reviewed Service dependencies support complete named/plain link replacement.
- External Service creation supports a bounded HTTP health-check request line.
- Reviewed non-Global load-balancer scaling preserves native execution authority.
- Denied changes to a readable target retain useful, authorized audit identity.
- Bounded Container logs drain the final frame before EOF; cancellation and
  existing stream authorization and size limits remain intact.

Native account roles, live memberships, API Key restrictions, target identity and
review confirmation remain authoritative. The four independent AI feature flags
remain disabled by default. This release does not complete every frontend workflow.

## Release identity and verification

- Image: `ghcr.io/pasturestack/server:v1.6.584`.
- Immutable digest: `sha256:40a7aa6cbc6ac6e96b2581009bb2855ad100e82b662d74e80de545b45634d0b6`.
- Publisher source: `71c5369368fdc89a36296a76f98f589c651a3a56`.
- Publisher: [successful normal release run](https://github.com/PastureStack/server/actions/runs/42419433474).

The normal release verified 35 public assets, 36 cryptographically signed release
subjects and both OCI proofs. Component CI passed 1,142 Web Console browser tests
and 4,241 Engine tests (one inherited skip); Server packaging passed 50 checks.
Artifact SBOMs and the vulnerability ledger accompany the release. Unfixed findings
remain tracked separately and are not represented as patched.

An isolated deployment passed startup, one restart, HTTP health checks, three
active Hosts/Agents and installed-file verification of the 19 scoped APT files.
Mounts, named volumes, operator configuration and the previous Server were retained.
The affected log, dependency, HTTP-health and scaling business matrices remain in
progress; deployment success alone is not their acceptance result.

## Upgrade and recovery

Use the numeric release tag in the [installation examples](../../README.md).
Preserve the existing Compose configuration, named volumes and a verified backup
before upgrading. Retain the previous image and configuration for recovery.
Follow the existing database compatibility and downgrade checks; where restoration
is required, restore the matching database/data backup rather than attaching an
older Server to incompatible upgraded data.
