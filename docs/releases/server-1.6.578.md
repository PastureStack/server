# Server v1.6.578

Published image: `ghcr.io/pasturestack/server:v1.6.578@sha256:05a2e55fe05c9101b367b09aaa058d4c617a7583b6e81f162780b5889b3a3a9d`.

Publisher revision: `27cff5bbdbf46fde0ebf8c737640eaca48c3c40e`; [official workflow](https://github.com/PastureStack/server/actions/runs/42276197533) passed source, image build, security, startup/restart and immutable publication checks.

## Verified component inputs

This release retargets the existing Server packaging contracts to published Engine 0.183.380 and Web Console 1.6.221 / optional Bridge 0.2.23. Original public component bytes, source tuples, Engine role schemas, Web archive/runtime SBOM/lock hashes, matching source ABI and native release attestations are bound before packaging. Components are not rebuilt by this change.

The opt-in Stack graph view returns bounded currently authorized ordinary-Service links through the existing read workflow. It keeps opaque references and unknown completeness; an empty graph never establishes permission to stop, remove or modify resources. Ordinary get_resource has no graph query unless the view is requested.

Compose 0.14.43, Catalog 0.20.17, the existing APT19 inputs, runtime defaults, native role/Key authority and security gate policy remain unchanged. The clean-install load-balancer default remains 0.9.33; this release does not migrate stored settings. VEX/vendor content is retained with only the Server release identity retargeted.

## Acceptance and rollback

Operator deployment and the new Stack-graph business acceptance remain separate from publication. Component CI and workflow smoke checks do not establish full 243-group coverage. Reuse the original Compose settings, feature opt-ins, origin, mounts, named volumes and runtime protections. Preserve the previous image and matching database backup for rollback; do not remove an existing custom bundle override until its replacement is deployed and verified.

## Reproducible CA bootstrap

The live Ubuntu archive removed the pinned CA package and the first Server578 build correctly rejected the HTTP error content. The five active Server/agent bootstrap recipes now use the fixed official Ubuntu snapshot `20261104T000000Z`. The package version, 137,978-byte payload and SHA256 `5b6326f1932cfd7be57130561dc78192f09ed9f58bfbe6606ed0c50510c3b6cd` are unchanged. Package validation, HTTPS peer/host verification, signed APT metadata and all runtime inputs remain enforced. The two source-bound recipes for previously qualified backport artifacts remain byte-for-byte unchanged; this release consumes those immutable artifacts rather than rebuilding them.

Ubuntu USN-9001-1 (2026-11-05) announces a separate CA/JKS synchronization update. Its applicability is tracked separately; this identical-payload download repair does not claim to include that update or change the Java truststore.
