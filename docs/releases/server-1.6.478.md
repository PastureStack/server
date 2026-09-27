# Server v1.6.478

This patch assembles Web Console `1.6.143` with the unchanged Orchestration
Engine `v0.183.326` on the preserved Server `v1.6.460` runtime base.

Creating a private ProjectTemplate from Default now sends only editable fields
and deep-copies its initial stacks. The new record does not inherit Default's
creation time, lifecycle state, ID, UUID, or external catalog identity. Shared
new-resource cloning removes server-owned identity and lifecycle fields from
Host, Service, Container, and VM create copies while leaving edit and upgrade
copies unchanged. Receiver clones omit inactive driver configuration, including
`forwardPost`; unsupported drivers cannot be submitted from the create form.

These are client-side create-flow changes. They change no Engine authorization,
authentication, API schema, database, or existing resources.

## Immutable component inputs

- Orchestration Engine `v0.183.326`, commit
  `66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, `cattle.jar` SHA-256
  `6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
- Web Console `1.6.143`, commit
  `c6d288bdf99e107af3fa6db735ab996b01da729d`, archive SHA-256
  `5c0c131900f55a6b9a1ab6e18603d8b4cfac4319e3f4ca9d7c2e2a7dd6001a32`.
- Webhook Automation Service remains `0.10.3`; Authentication Service remains
  `0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

Server publication requires source and image gates. The separate `8080` QA
installation must still verify ProjectTemplate Add/Edit/Remove, cancellation,
role denial, readback, and cleanup as well as the affected clone flows.

## Upgrade and rollback

After release verification, upgrade by selecting the immutable numeric tag
`ghcr.io/pasturestack/server:v1.6.478` and its verified digest. Preserve Compose
environment variables, named volumes, restart policy, AppArmor, HTTPS origin,
OIDC, performance settings, and firewall backend. Rollback selects the
preserved `v1.6.477` image with the same configuration and volumes. Neither tag
is overwritten; `stack.ascdc.tw` is outside this QA deployment.
