# Server v1.6.603 candidate

## Candidate boundary

Server build, publication, deployment and affected native/UI workflows remain
pending. The released image digest and source revision will be supplied by the
publication workflow. The earlier v1.6.602 manual recovery results do not prove
this product change or a production deployment.

## Verified component inputs

This release integrates Catalog Service v0.20.19 and a complete default Catalog
Git bundle pinned to `6e7b935b6f08e711e1884ef8369cd9dcd110901f`.
Catalog Service producer: `151d62fff93deaca9b2486b0b071df6772d1a27b`.
Its archive SHA-256 is
`dc46d200cfe8f454b234ca36c04043beeaa3cc48eac921f85118ee9c8db5e0c2`.
The bundle SHA-256 is
`601c60291ad0f1d9a548c6d10027e5c01b7fc0182a88481800c79778cdce1181`.
Source attribution, license and offline verification commands are included under
`/usr/share/pasturestack/catalog-sources/`.

Catalog Service owns source verification, serialized refresh and index readiness.
Matching default sources are indexed locally before requests are served, without
GitHub access. The source policy remains enforced. Invalid source, parse errors
or missing required revisions cannot replace a usable index with partial data.
An older index, missing revision or modified cache is rebuilt from the verified
source. Custom sources are not silently replaced or allowed local-file access.

The component passed its official test, reproducible-build and security gate.
Raw build-image kernel-header findings are retained with exact-package impact
statements; they do not describe a Host kernel or an absence of all raw CVEs.

The shell launcher no longer reports a nonempty list as verified. Publication
checks the indexed commit and eight exact template/templateversion reads during
fresh startup and restart with external Git access deliberately unavailable.
This does not claim that a remote installation has been updated or that images
can be pulled without access to their registries.

Engine v0.183.395, Web Console 1.6.239 and new-registration Agent v1.2.36 are
unchanged from v1.6.602. Existing runtime overrides and persistent volumes remain
supported. No production site, HAProxy or firewall change is part of this release.

See the [Catalog upgrade and rollback guide](../upgrades/README.md#bundled-default-catalog).
