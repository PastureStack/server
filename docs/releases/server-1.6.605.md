# Server v1.6.605

Published image: `ghcr.io/pasturestack/server:v1.6.605@sha256:b8ee185b9479e43b746b97d178aef883e3e5b26b4ecde811bbbc35fa86523266`.

Source commit: `339b425bb851fc621dd4988d0df57be6d8d61944`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

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

The Web Console submits the complete selected primary and secondary launch
configurations through the native service upgrade action. Their previous
values form the native image rollback point until **Finish Upgrade** or
**Rollback**. Image-only upgrades do not first save the replacement image onto
the active service.

Actual name, description, scale and complete `lbConfig` edits use an
allowlisted partial service save before the image upgrade, without saving
launch configurations or public endpoints. These separately saved
service-level fields retain their existing metadata semantics. This patch
does not make changed port rules, certificates or other service metadata
transactional with native image rollback.

Keep the upgraded load balancer unconfirmed until the actual replacement
image, HAProxy version, HTTP routing and certificate-verified HTTPS pass.
Image rollback must restore the retained previous primary/secondary launch
configurations and image in the service and its actual containers.
**Finish Upgrade** consumes the native rollback point.

The corrected path applies to a new upgrade submitted with this Web Console.
It does not reconstruct previous launch configurations already overwritten by
an earlier UI operation. Existing operator pins and the `lb.instance.image` /
`lb.instance.image.uuid` settings retain precedence.
See the [upgrade guide](../upgrades/README.md#managed-load-balancer-image-settings).

## Validation and rollback boundary

The formal release must pass the existing source, artifact identity, security,
fresh-volume startup and restart gates. Published component and Server checks
do not establish deployment-specific workload or browser lifecycle acceptance.
The historical v1.6.604 Cron and API-driven LB evidence remains scoped to its
recorded artifacts and does not claim this corrected UI sequence has run.

Retain the previous Server container/image and persistent volumes. Server
rollback does not reverse a completed service upgrade; keep the service's own
rollback point until the affected behavior has passed.

## Published security evidence

The [published security summary](https://github.com/PastureStack/server/releases/download/v1.6.605/security-summary.txt)
retains 90 raw scanner findings and 58 vendor-pending findings. Its qualified
gate reports no untracked, critical/high, fixed-available or secret findings.
Browser scan coverage remains `incomplete`; this is not a claim of complete
browser coverage or an absence of all raw findings.

## Isolated load-balancer UI acceptance

The published image passed startup and an explicit restart on an isolated
existing installation. Host configuration, environment, mounts and AppArmor
were preserved, and the previous Server remained stopped and available for
rollback. The new runtime's complete 24-package signed-download manifest is
byte-for-byte identical to v1.6.604, with the manifest SHA-256 recorded above.

Minimal post-restart dependency readbacks retained both effective LB defaults
at v0.9.35, the same Catalog commit and readable exact legacy Container Crontab
revisions 3 and 4. These are readbacks, not repeated Catalog or Cron lifecycles.

One continuous seven-phase UI evidence chain, tied to seven observed browser
actions and the same service, passed. Its actual baseline was Load Balancer
Service v0.9.34 with HAProxy 3.4.7-8872a26. An image-only UI upgrade selected
v0.9.35 with HAProxy 3.4.8-1b15b69 while retaining v0.9.34 as the previous
launch configuration. UI rollback restored v0.9.34 and HAProxy 3.4.7 in both
the native API and actual running container.

The second round edited the description through the UI, upgraded to v0.9.35,
finished the upgrade, then refreshed the page. The description remained saved,
the API was healthy, and the finished container identity remained the same
after refresh. Ports, rules and certificates were unchanged throughout this
fixture. This acceptance covers native image rollback and separately saved
description metadata; it does not establish transactional rollback of changed
port rules, certificates or other service metadata.

All six observed runtime phases passed HTTP, certificate-verified TLS 1.2 and
TLS 1.3: eighteen probes returned success. No browser errors were recorded.
The accepted visible 1035-pixel viewport had no document overflow; visual
acceptance is limited to that visible view.

The temporary fixture Stack, its two services, certificate and test CA were
removed normally, leaving no fixture-owned Docker containers. The original
Stack/service inventory matched its baseline, all three Hosts and their
Agents were active, and protected images, volumes and the previous Server
rollback point were retained. This was isolated QA; no production site was
accessed or modified. Existing Catalog and Cron lifecycle evidence keeps its
original scope and was not replayed by this LB UI acceptance.
