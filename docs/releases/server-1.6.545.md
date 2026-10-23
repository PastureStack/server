# Server v1.6.545 — service upgrade and endpoint identity

This is a prepared source candidate, not evidence of a published image or a
completed deployment. Immutable component coordinates, the final Server digest
and actual acceptance results must be recorded before this document describes
the release as published.

The Engine component is now published as
[v0.183.353](https://github.com/PastureStack/orchestration-engine/releases/tag/v0.183.353).
Its tested producer is `e094944cd81da614187dbeba1f06354682af1d45`, with jar
SHA256 `d0a353b40b8b9f739ddd30b9ccae6fbf3ca64d45547cd95e9194aad738538f40`.
The original CI bytes passed anonymous release download verification. Both
frozen readonly/restricted schemas match the prior assembly. This does not
establish Web Console or Server publication.

## Corrected behavior

Web Console 1.6.193 completes 2,519 missing policy/matrix/audit translations
across 11 locales. Its original full CI passed 1,104 browser tests without
skips and produced two identical static archives. The tested producer is
`fa7fd399e3aef2a67282e8fbbe9f3fc83002710d`, with archive SHA256
`07dd68dddecec1d95c6932d4dd31084401ee67d517fb820ecbbe6afaa052a888`.
The browser test image includes CJK and Arabic-script fonts; no product layout
assertion or localization fallback exception was relaxed.

The Web Console service-upgrade path previously performed a generic service
save before sending the upgrade action. That save could return HTTP 422 when
the clone contained a derived `publicEndpoints` entry for a removed instance.
Service upgrades now retain the normal validation/preflight and shared saving
lifecycle, but wait for the upgrade action and send its strategy directly.
Ordinary create/edit persistence is not changed.

The Engine previously compared public endpoints using only address and port.
Replacing an instance while retaining its address/port could therefore leave
the old instance reference in the service. The comparison now uses an
order-independent set of address, port, service, host and instance identities.
Reordering an identical set does not write it again. Reference validation is
not relaxed, and removed resources do not become valid references.

The CA bootstrap package download uses the official locked Ubuntu snapshot
after the moving archive removed the pinned version. Its package version and
SHA256 remain identical, verified against the signed snapshot package index.
The source gate requires that exact snapshot and checksum in all three Server
recipes; this is a source availability repair, not a dependency downgrade or
an exception to the artifact security gate.

## Acceptance boundary

Required evidence includes the stale-endpoint regression, the complete Web
Console and JDK 25 Engine test suites, and a real QA service upgrade with a
published port and persistent volume. The browser must send no complete
service PUT, exactly one upgrade action followed by the existing service-link
action, and report no console/page/request/unhandled-rejection errors.

After finishing the upgrade, read back the new running instance, old removed
instance, service endpoints, expose map, ports and retained configuration.
Repeat the readback after refreshing and restarting the QA Server. Source
tests alone do not establish any of these runtime results.

## Upgrade and rollback

Keep the three existing persistent volumes, operator-provided environment,
restart policy, AppArmor configuration, HTTPS origin, authentication and
networking settings. Retain the previous official image and a pre-upgrade
database backup. This change does not require a schema migration.

Do not use a runtime JavaScript patch. A production installation with an older
read-only bundle override must not carry that old bundle into the new image;
its removal and deployment require separate authorization and acceptance.
This task does not operate on the company production site, proxy, firewall or
database. The QA Server rollout retains its previous container/image for
rollback and never removes persistent volumes.
