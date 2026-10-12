# Server v1.6.524

This immutable published release packages Engine `v0.183.342` and unchanged
Web Console `1.6.183`. Current installation examples use the numeric
`ghcr.io/pasturestack/server:v1.6.524` tag.

The published producer is `cc52ce16363333ef77345ff768acddcdf839dde7`.
The linux/amd64 image contains one runtime layer. Its registry reference is
`ghcr.io/pasturestack/server:v1.6.524@sha256:0b4ae5f87ef54f25081d728e2ae5eda51ea093ab52768bb7451229ab512092ba`;
the distinct OCI configuration digest is
`sha256:65061d2f1d4baf2b7e1fd75fe96cfcfaa4a0a22e251ac2ea7fd9ec4c74d61cd6`.

## Authorized mutation internal lookup repair

Engine342 repairs internal resource loading for an already-authorized operation,
including an update-only Key updating an existing Stack. The internal lookup
is not an external GET/list grant. Live owner RBAC, Key policy, scope, expiry,
and the actual mutation remain authoritative; no additional role is granted.
The final image passed 96 native cases across four writable roles, two
independent accounts per role and both v1/v2-beta API roots: 32 update/delete
operations succeeded, 32 direct GETs were denied, and 32 collection GETs
returned no unauthorized rows. Each request used its own write-only Key,
with matching decision/response audit events and protected-resource readback.
No read grant was added. Test containers, accounts, Keys and owned volumes
were removed; existing data was preserved.
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
numeric-release gates passed. Entry-only checks do not establish an
active node. Existing VEX decisions and vendor-pending policy are unchanged.
Native mutation/read-boundary acceptance, startup and one restart passed.
The upgrade preserved runtime settings, AppArmor and all three named volumes,
with pre/post resource counts unchanged. Whole role/resource lifecycles remain
separate; unknown outcomes remain pending.
Preserve all three named volumes, backups, environment and security settings.
Rollback to published Server523 preserves onboarding and HA repairs but restores
the known update-only internal-read defect. Follow the API Key rollback guide;
do not weaken a restricted or expired Key to make a request succeed.
