# Server v1.6.524

This source release packages officially published Engine `v0.183.342` and
unchanged Web Console `1.6.183`. At source preparation, Server524 publication,
final-image native repair acceptance and deployment are not yet verified.
Current installation examples continue to use the published Server523.

## Authorized mutation internal lookup repair

Engine342 repairs internal resource loading for an already-authorized operation,
including an update-only Key updating an existing Stack. The internal lookup
is not an external GET/list grant. Live owner RBAC, Key policy, scope, expiry,
and the actual mutation remain authoritative; no additional role is granted.
Focused component evidence is separate from final-image native acceptance.
The full API Key matrix is not claimed PASS by this release or by a prior run.

## Released component inputs

Engine source `ddae4bb8e12806f70816f5782cd999eccd0f2ce6`, tree `ac1aa0aff4719dec0c08ba89f857d3fbbc33038d`.
The original-package `cattle.jar` is 87871186 bytes, SHA-256
`3533f247392795329c92516a7966510aafbe81a52e3f922e5ec657a2071363b5`. The immutable component's actual anonymous asset
bytes and checksum were read back; local bytes match the same released asset.
Canonical component publication receipt SHA-256:
`e5dc116d94b9a164d2a0dab6b14ec3dc7118c9447c284a46fd01dfb4d8df75ba`.

Web183 source `e056a0111d20816742eff17a65dfabb5d003dae2`, archive SHA-256
`8540758ad4521f901f53fc79473570cf98862add2addcb49271d8dbf125b4217`.
All other component pins, role schemas, Ubuntu inputs, runtime configuration,
broker, registration and HA behavior remain unchanged in this Server scope.
Earlier passed evidence may be retained only for demonstrably unchanged paths;
it is not a new Server524 native PASS or a replacement for required gates.

## Publication, acceptance and rollback

The original source, image-build/flatten, startup/restart, MFA, seven-check
registration entry, merged-rootfs security/SBOM, provenance and immutable
numeric-release gates remain mandatory. Entry-only checks do not establish an
active node. Existing VEX decisions and vendor-pending policy are unchanged.
Final Server524 native update/denial/owner-boundary evidence and deployment
must be recorded separately; unknown outcomes remain pending.
Preserve all three named volumes, backups, environment and security settings.
Rollback to published Server523 preserves onboarding and HA repairs but restores
the known update-only internal-read defect. Follow the API Key rollback guide;
do not weaken a restricted or expired Key to make a request succeed.
