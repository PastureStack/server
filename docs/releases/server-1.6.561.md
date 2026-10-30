# Server v1.6.561

Published image: `ghcr.io/pasturestack/server:v1.6.561@sha256:c9dbda3065b3cd860a01745d0af289d38cd4b48cb74c8e1277de67d0c0497449`.

Source commit: `6d83ff4cef4cd6d105e07f69af5a09c61441c634`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

- Web Console 1.6.202 / bridge 0.2.4: published original producer
  `3350a566b77c46ccf3686975bdcc8d9c14ee2985`, tag source
  `1b426175a55fd63260466cacd02e962e1bd44f8f`; all 13 public assets verified.
- Web archive SHA256:
  `333bca5f68e128423bf398cd2b8e72ccf05f96e02bcde7260b84a09b09601ac6`.
- Web runtime SBOM SHA256:
  `54a17d3405535210d3f770a64b0708a6e3d8e908cbbe036fc737558eb0dfeaf8`;
  original lock `81b8b3d579373456953ed27619de4b003cf13e122c94dce115254c3e3bba4dae`.
- Engine 0.183.361 producer `592bd47ca9417f24d5acea07b567b9385852f381`;
  original JAR SHA256 `9346cdc844c56e76779e95b015246c4aba3c224ee8b7e3bdb6ba31989a615136`.
  Required CI, same-tree merge, original artifact checks and all 12 public assets
  passed; tag source `4e86a5890798d64f1f3f656c6c78e4dedef7aa39`.
  Official structured results: 412 suites / 3843 tests / zero failure or error / 1 existing skip.
  Runtime SBOM SHA256 `7163aba0bc8e77f0901a1d07be9ce23e77c548a7d20813a24b1bae22254701f8`.
- Catalog 0.20.17, Compose 0.14.40 and other package inputs remain unchanged.

## Corrected workflows

Standalone Container removal preserves its verified native remove frame and
owned retired NIC/IP cleanup. Current role, original Key revision, explicit
DENY and shared/foreign-resource ownership remain enforced. Genuine structured
child authorization denial becomes terminal instead of retrying as UNKNOWN.

Registered External Service, DNS Alias and Certificate metadata audit targets
remain in the existing durable metadata-only audit owner. Audit failure stays
fail-closed. This change does not grant access to those resource types.

The fixed private audit query CLI shares the operator-configured broker
upstream. Previously its 8082 literal and cleared child environment diverged
from the image topology. Java passes only that exact nonsecret operator
setting after clearing the other environment, reconstructed from fixed local
HTTP(S) origins and a bounded numeric port; credentials remain private stdin.
Callers cannot choose an upstream, executable, SQL or raw audit payload.

Certificate name/description plans use normal human approval and the native
metadata-only PUT. Certificate PEM, private key and chain are preserved and
excluded from tool snapshots. Other material operations stay in the human UI.

## Acceptance boundary

Required component CI, original artifacts, image/startup/restart and designated
business tests are separate gates. The original failing runtime reports remain.
Core lifecycle, External/Alias, all twelve audit-query cases, affected role/Key
and cross-ID boundaries, new layouts and actual weak-model workflows must pass
before their own matrix entries are marked accepted. Preserve unaffected PASS
at its original scope; do not promote a subcase to complete frontend coverage.
The baseline remains 243 groups and 3,089 source rows. New source coverage is
partial and does not establish whole-group or complete-product acceptance.

## Upgrade and rollback

Use only the newly published immutable numeric image tag. Preserve existing
volumes, operator configuration, origins, MFA/session protection, restart policy
and AppArmor. Retain the last healthy container/image and a compatible database
backup. A later downgrade does not reverse completed writes. Do not replay
uncertain operations, replace their captured Key identity or patch database state.
After deployment, confirm old denied work is terminal before a separately
authorized operator cleanup. Production, HAProxy and firewall are unchanged.

## Designated acceptance after publication

One actual restart and all three Host/Agent baseline checks passed while retaining
operator configuration, mounts, AppArmor and rollback. The complete scoped Core
workflow remains failed at ServiceIndex cleanup during Service scale-down. This
same native owner is used by Service/Stack removal and is being corrected; do not
replay an uncertain write. Audit query201/SUCCEEDED completion exists, with an
acceptance-status oracle correction pending. Other designated domain, role,
layout and weak-model cases remain separate gates. Prior evidence is retained.
