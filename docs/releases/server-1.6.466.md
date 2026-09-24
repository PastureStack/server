# Server v1.6.466

This patch updates Web Console to `1.6.129` for capability-bound environment
editing. On a direct `?editing=true` URL, member add/change/remove controls
now require the project's `setmembers` action, project metadata uses its own
update action, and network-policy controls use the network's update action.
The detail page exposes an Edit entry for network-only capability. The save
path follows the same boundaries. A page without writable controls
retains Cancel without offering a misleading Save. No backend authorization,
database schema, or deployment configuration changes are introduced.

## Component and release coordinates

- Web Console: `1.6.129`, source commit
  `71fe325071e8a93a09c3eba122509e58caf4272a`; official artifact SHA-256
  `3cea709fc2b09f0088371b6ba3e4b5cff0e1b1ca54dbc76295668b2d8696580e`.
- Orchestration Engine remains `v0.183.321`; Authentication Service remains
  `v0.4.42`. All other components and the digest-pinned `v1.6.460` runtime
  base remain as in [Server v1.6.465](server-1.6.465.md).
- The immutable Server image digest is recorded only after the release build
  and registry readback, not inferred from this source candidate.

## Verification before publication

Run the focused Web Console unit and rendered-template permission tests and
its official clean-source build. In isolated QA, exercise owner, member,
restricted, readonly, and no-access accounts against direct environment view
and `?editing=true` routes. Owner must retain member controls and real save;
roles without `setmembers` must see the member list without add/role/remove
controls. Verify no-write Save is absent, Cancel works, and v1/v2-beta project
member authorization remains unchanged. Check browser errors and live API
responses separately. Network update authorization requires a disposable
editable network and is not implied by a hidden UI control or by a 405.

## Upgrade and rollback

After `v1.6.466` is published with an immutable digest, update only the Server
image reference from `v1.6.465`. Preserve Compose environment variables,
named volumes, restart policy, Docker socket, AppArmor, HTTPS origin, OIDC,
performance parameters, and nftables architecture. No migration is needed;
rollback selects the preserved `v1.6.465` image with the same configuration and
volumes. This release procedure does not deploy to a production host.
