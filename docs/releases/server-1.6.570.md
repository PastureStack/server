# Server v1.6.570 candidate

Not published. Server image and deployment acceptance remain pending.

## Verified component inputs

This assembly consumes published Engine v0.183.371, Web Console 1.6.209 and
optional Bridge 0.2.11. Catalog 0.20.17, Compose 0.14.41 and all other component
coordinates are retained. The four independent AI opt-ins remain default-off.

Engine producer: `55baa21d7952f6d0d54076af6b250a4d60f2d5d7`.
Engine artifact SHA256: `82a990e235891eb07a27d75bfd90fa54dc93a5cc4953abe3e05e5ac749b86a8e`.

Host metadata review now recognizes the native Docker Host model independently
of its API type. Name and description remain the only editable Host fields;
current account, role, schema, Key policy, revision and human approval still
bound every change. Host lifecycle and Node Agent configuration are unchanged.

Catalog launch delegation now supports the exact API-version-root metadata
handshake needed by the ordinary Compose executor. It does not grant child
resource access or repeat a dispatched launch after an uncertain response.
Denials retain safe audit attribution and fresh owner/Stack checks.

Engine build downloads reuse the existing official package versions and signed
APT plans with size and SHA256 verification. Local package cache binding and
the final security overlay use the same transport; installation restrictions
and the final package-version table are retained. No runtime patch is used.

Web Console 1.6.209 and Bridge 0.2.11 are unchanged from Server v1.6.569.
The selected-environment editor and new client-audit detail planned for Web
Console 1.6.210 are not included in this assembly. Existing Full/legacy Key
behavior, MFA, cross-tab sessions, performance settings and network backends
are preserved.

Original component CI and publication evidence do not establish deployment
acceptance. Host and Catalog business acceptance must be recorded separately;
full 243-group frontend coverage is incomplete. Upgrade and rollback must
preserve operator overrides, named volumes, restart policy, AppArmor, HTTPS
origin and the previous healthy image. Rollback after data changes requires
the matching verified database backup.
