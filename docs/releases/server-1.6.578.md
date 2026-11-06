# Server v1.6.578 candidate

Prepared source only; no Server image or release has been published.

## Verified component inputs

This source candidate retargets the existing Server packaging contracts to published Engine 0.183.380 and Web Console 1.6.221 / optional Bridge 0.2.23. Original public component bytes, source tuples, Engine role schemas, Web archive/runtime SBOM/lock hashes, matching source ABI and native release attestations are bound before packaging. Components are not rebuilt by this change.

The opt-in Stack graph view returns bounded currently authorized ordinary-Service links through the existing read workflow. It keeps opaque references and unknown completeness; an empty graph never establishes permission to stop, remove or modify resources. Ordinary get_resource has no graph query unless the view is requested.

Compose 0.14.43, Catalog 0.20.17, the existing APT19 inputs, runtime defaults, native role/Key authority and security gate policy remain unchanged. The clean-install load-balancer default remains 0.9.33; this candidate does not migrate stored settings. VEX/vendor content is retained with only the Server release identity retargeted.

## Candidate boundary

Normal Server CI, official image build, scans, startup/restart, immutable publication and deployment-specific native acceptance remain pending. Component qualification is not Server runtime acceptance or full 243-group coverage. Installation instructions continue to use published Server v1.6.577. The QA577 runtime baseline is not moved by this source change.
