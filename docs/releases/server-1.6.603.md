# Server v1.6.603

## Published artifact

Immutable image: `ghcr.io/pasturestack/server:v1.6.603@sha256:bfcbfe9b9494bf7692fcd7ff68aa5dcdf3d342735986d9ed6fda3c6eb640c8f0`.
Image producer: `82cf63ff2c6ec974d91dd4f7aee8d342593b6fd1`.
[Publication and required runtime/security checks](https://github.com/PastureStack/server/actions/runs/45106191247).

The published image passed fresh-volume MySQL startup and restart with external
Git access unavailable. On an existing isolated installation, an older index
and empty desired-pin cache recovered automatically from this image's bundle;
no operator cache import, refresh call or runtime patch repaired the new image.
The same offline instance passed a further real restart before normal runtime
overrides were restored.

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

## Affected acceptance and boundaries

- Catalog component tests, race checks, reproducible build and security checks passed.
- The publication first-start and restart checks read the pinned commit and eight
  exact template/templateversion APIs. Existing-installation checks read the
  same global Catalog in two project contexts: sixteen exact API reads per phase.
- Four existing system Stacks completed twenty-four upgrade, finish and rollback
  actions across twenty observed phases. Named launch configurations and the
  eleven current/previous runtime images remained consistent with the Catalog.
- Three mounted data fixtures and twelve workload volumes were preserved.
  A disposable service verified scheduling, DNS, direct HTTP and a host port;
  its resources were removed normally. Three Hosts/Agents and eight system
  Stacks were active/healthy at final readback.
- The current scan newly identifies CVE-2026-107708 in four exact Ubuntu Kerberos
  libraries. Canonical has no published Resolute fix; raw findings remain and
  the vendor-pending record requires review by 2026-11-27. This is tracking,
  not remediation or a not-affected statement. Existing severity/fix gates remain.
- Unchanged LB, browser-language, cross-host encryption, AWS and KVM evidence
  was not rerun or promoted. No production system was accessed or modified.

Keep the previous Server container/image and all existing persistent volumes.
Server rollback does not reverse completed Stack upgrades; use each retained
Stack rollback point before finishing, or restore a matching backup when needed.
Older Server releases regain their original external-Git dependency.
