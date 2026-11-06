# Server v1.6.578 candidate

Prepared source only; no Server image or release has been published.

## Verified component inputs

This source candidate retargets the existing Server packaging contracts to published Engine 0.183.380 and Web Console 1.6.221 / optional Bridge 0.2.23. Original public component bytes, source tuples, Engine role schemas, Web archive/runtime SBOM/lock hashes, matching source ABI and native release attestations are bound before packaging. Components are not rebuilt by this change.

The opt-in Stack graph view returns bounded currently authorized ordinary-Service links through the existing read workflow. It keeps opaque references and unknown completeness; an empty graph never establishes permission to stop, remove or modify resources. Ordinary get_resource has no graph query unless the view is requested.

Compose 0.14.43, Catalog 0.20.17, the existing APT19 inputs, runtime defaults, native role/Key authority and security gate policy remain unchanged. The clean-install load-balancer default remains 0.9.33; this candidate does not migrate stored settings. VEX/vendor content is retained with only the Server release identity retargeted.

## Candidate boundary

Normal Server CI, official image build, scans, startup/restart, immutable publication and deployment-specific native acceptance remain pending. Component qualification is not Server runtime acceptance or full 243-group coverage. Installation instructions continue to use published Server v1.6.577. The QA577 runtime baseline is not moved by this source change.

## Reproducible CA bootstrap

The live Ubuntu archive removed the pinned CA package and the first Server578 build correctly rejected the HTTP error content. The five active Server/agent bootstrap recipes now use the fixed official Ubuntu snapshot `20261104T000000Z`. The package version, 137,978-byte payload and SHA256 `5b6326f1932cfd7be57130561dc78192f09ed9f58bfbe6606ed0c50510c3b6cd` are unchanged. Package validation, HTTPS peer/host verification, signed APT metadata and all runtime inputs remain enforced. The two source-bound recipes for previously qualified backport artifacts remain byte-for-byte unchanged; this release consumes those immutable artifacts rather than rebuilding them.

Ubuntu USN-9001-1 (2026-11-05) announces a separate CA/JKS synchronization update. Its applicability is tracked separately; this source-only download repair does not claim to include that update or change the Java truststore.
