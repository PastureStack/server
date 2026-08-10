# PastureStack Server v1.6.356

Server v1.6.356 packages Authentication Service `0.4.35`, Web Console `1.6.69`,
the reviewed Catalog snapshot, and the Resource Scheduler catalog revision
without changing the established Orchestration Engine or Node Agent runtime
coordinates.

## Runtime components

- Orchestration Engine: `0.183.281`
- Orchestration Engine source: `17c9b856a8004fb71c64f876ad120942429eb260`
- Orchestration Engine artifact SHA-256:
  `da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682`
- Node Agent: `0.13.22`
- Authentication Service: `0.4.35`
- Authentication Service source:
  `b5f50c57407fcc1b789bff680084226fba2e3171`
- Authentication Service archive SHA-256:
  `17c10c2d907d75cc2ead63b9b7ec7c3535b9d45e812afede94c0df799251172b`
- Authentication Service binary SHA-256:
  `a49f60048d841b5e164a3f9d60f52f125e8d6b663f337b4aafb7a20b4e4034dd`
- Web Console: `1.6.69`
- Web Console source: `ee53830526df5fb49aa457ffc56947352e98fed2`
- Web Console artifact SHA-256:
  `ea49b88b49af64ad4d35fe9355b60b19b931224a413df07a4935ef6ae8e33ddd`
- Catalog snapshot: `bc446236c16f1170eb9130b4901af3d57dd82db4`
- Resource Scheduler catalog release: `v0.8.16`

## Corrected behavior

Web Console `1.6.69` retains the deterministic loading-overlay lifecycle and
the rectangular PastureStack stack-panel loading state. The numeric version
advance gives every theme a new `?1.6.69` cache key, so a browser reload cannot
reuse the earlier theme URL. A monotonic transition identifier ensures that
stale completion callbacks from overlapping transitions cannot show or hide
the current overlay. Successful, rejected, and aborted transitions all release
the overlay, and a 30-second watchdog prevents an unresolved transition from
blocking the interface indefinitely. The image gate requires the project mark,
three stack layers, and progress rail, and rejects the retired grass,
celestial-body, orbit, and rotating-ring scenes. Reduced-motion mode retains a
low-displacement layer pulse and progress-colour cycle.

All noVNC logging levels now keep untrusted message text out of browser-console
sinks. The build smoke harness uses a constant failure event for the same
reason. The exact source revision passed GitHub CodeQL with no open alerts.

Authentication Service `0.4.35` preserves the established route, token,
identity, encrypted-provider configuration, SAML callback, and launch-wrapper
contracts while retaining the provider-neutral OpenID Connect flow and
identity-link proof. Assembly verifies both the release archive and extracted
static binary by SHA-256 before replacing only
`/usr/bin/authentication-service.real`.

The Catalog snapshot retains every prior immutable Resource Scheduler template
revision and keeps `v0.8.16` as the current revision. Its public image reference
uses a semantic version tag; digest evidence remains in the matching GitHub
Release and is not exposed in the user interface.

This release retains the authoritative storage validation introduced by the
previous releases. An ordinary pending live check still disables Create. A
same-tick volume recheck that races with an already accepted click continues to
the server-side validation instead of becoming a stale client-side error.

The `volumepreflight` action keeps the real core add-on type set,
project-scoped authorization, authoritative create and upgrade validation, and
the creatable `volumePreflightInput` contract. The packaged-image gate rejects
the retired `String.prototype.dasherize` path. The `pasturestack-nfs` driver requires environment scope, `multiHostRW`, and complete active-host coverage.
Every successful selected-volume deletion refreshes the visible rows,
pagination, selected count, and controls immediately; failed rows remain
visible.

## Validation

The exact Web Console source passed its Chrome browser suite plus source,
dependency, workspace, focused-transition, production-build,
reproducible-artifact, 13-locale, and visible-DOM gates. The two release
candidates were byte-for-byte identical, contained no source maps, and carried
the exact `1.6.69` version marker. CodeQL closed all five reviewed
medium-severity log-injection findings as fixed and reported no open alerts.

Server assembly verifies the public release checksum, archive root, version
marker, required licenses, branded loading markers, and absence of the retired
scene before producing the image. The publication workflow builds two clean
candidates, compares their runtime payload and image configuration, enforces
zero Critical or High image findings and zero embedded secrets, retains a
CycloneDX SBOM, and publishes provenance and SBOM attestations.

Live deployment acceptance checks `/ping`, local login, OpenID Connect, MFA,
authenticated route navigation, overlay dismissal, Catalog revision discovery,
Resource Scheduler continuity, container restart count, persistent volume
identity, and rollback readiness.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE. Existing licenses and upstream attribution remain
applicable; see the repository license and notices.
