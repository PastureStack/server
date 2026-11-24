# Server v1.6.605 candidate

## Candidate boundary

Prepared source only; no Server image or release has been published.
Server build, publication, deployment and affected native/UI workflows remain
pending. The Web Console input below is already officially published.

## Verified component inputs

Web Console [1.6.241](https://github.com/PastureStack/web-console/releases/tag/1.6.241)
is published immutably from `731f79004714150786b6e5e12d06683927a9d14e` by
[exact-main producer 45311119062](https://github.com/PastureStack/web-console/actions/runs/45311119062).
Its archive SHA-256 is
`ef9cc7c4b8828307c695d6d91d54356f0086bde354b0ec24d0b7f2a1d36b3ab8`;
the runtime SBOM SHA-256 is
`35e7d656ca97e100a03eeea7eb6af9ad7c2e4adb6ecd78e553eb4305f8d1a08c`;
the dependency lock SHA-256 is
`78113228da4436f01ad6c0f4561823dc76d1add75d0991bc2e1317622d63a9ff`.
The producer verified two matching builds and its SBOM/provenance attestations.
The archive retains the existing `enabled` WebMCP ceiling with initial mode
`off`; the complete Server archive/SBOM identity verifier passed this profile
before consumption. Browser inventory coverage remains `incomplete`.
The unchanged Web application source retains the 1164-test qualification,
including twelve load-balancer save regressions. These source and artifact
results do not establish an executed Server browser workflow.

Engine v0.183.395, Catalog Service v0.20.20, Load Balancer Service v0.9.35,
Compose Executor 0.14.46 and the new-registration Agent v1.2.36 retain their
v1.6.604 component identities. The complete default Catalog remains pinned to
`8c1c28318580d5ec18c14a13b224ce0e02e40bf8`; no template, scheduler or
load-balancer runtime image changes are introduced by this Server patch.

## Rebuildable Ubuntu security inputs

The disposable build stage downloads its existing security package versions
from the official `20261123T000000Z` Ubuntu snapshot. This avoids depending on
the live index retaining an older exact version. APT still authenticates the
signed index and enforces HTTPS peer/host verification, exact versions,
SHA-256, and package architecture; date and validity checks remain enabled.
The selected snapshot InRelease files have no `Valid-Until` field, so this
change does not introduce a short-lived expiry or disable time validation.

All 24 selected package/version/architecture/SHA-256 identities match the
signed-download manifest retained by the immutable v1.6.604 image. Its
manifest SHA-256 is
`f62b729812334de169b421075048027e32ffa1f24f57300d521f2039d19eeb71`.
The version lock bytes and network-free runtime installer are unchanged;
this build-source correction does not advance the runtime package set.

## Managed load-balancer upgrade and rollback

The Web Console change submits the complete selected primary and secondary
launch configurations through the native service upgrade action. It preserves the active launch configuration as
the previous configuration until the operator chooses **Finish Upgrade** or
**Rollback**. Saving the replacement image to the service before starting its
upgrade would overwrite that rollback state; image-only upgrades no longer
perform that save. Actual name, description, scale and complete load-balancer
configuration edits use an allowlisted partial save without launch configurations
or public endpoints.

Keep the upgraded load balancer unconfirmed until the replacement containers,
actual HAProxy version, HTTP routing, and certificate-verified HTTPS pass.
Rollback must restore the retained previous image and configuration; inspect
both the service and its actual containers. **Finish Upgrade** consumes the
native rollback point.

This behavior applies to a new upgrade submitted with the corrected Web
Console. It does not reconstruct a previous launch configuration already
overwritten by an earlier UI operation. Existing operator pins and the
`lb.instance.image` / `lb.instance.image.uuid` settings retain precedence.
See the [upgrade guide](../upgrades/README.md#managed-load-balancer-image-settings)
for selecting the managed component and retaining its rollback point.

## Validation and rollback boundary

The formal release must pass the existing source, artifact identity, security,
fresh-volume startup and restart gates. Published component and Server checks
do not establish deployment-specific workload or browser lifecycle acceptance.
The historical v1.6.604 Cron and API-driven LB evidence remains scoped to its
recorded artifacts and does not claim this corrected UI sequence has run.

Retain the previous Server container/image and persistent volumes. Server
rollback does not reverse a completed service upgrade; keep the service's own
rollback point until the affected behavior has passed.
