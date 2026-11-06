# Server v1.6.579 candidate

## Verified component inputs

This candidate retargets the existing Server packaging contracts to published Engine 0.183.381 and Web Console 1.6.222 / optional Bridge 0.2.24. Packaging binds their actual immutable publication receipts, source tuples, Engine archive and role schemas, and Web archive/runtime SBOM/lock hashes. The current Web222 source checker verifies the fourteen assembly ABI inputs against the published Engine381 source. Web222's public minimum-compatible and original matching Engine380 metadata remain unchanged; Server579 records the Engine381 assembly match separately.

Engine381 preserves native load-balancer backend identity when rendering the prepared TCP plan. Web222 uses bounded native Project discovery and distinguishes generic resource references from legacy Stack/Service references. Native account, role, Key authority and explicit human approval remain binding. Component publications and source checks do not establish deployment or full frontend acceptance.

Compose 0.14.43, Catalog 0.20.17, the nineteen existing component inputs, APT19, firewall, runtime feature flags, origins, mounts, named volumes and security gates remain unchanged. VEX/vendor findings and policy retain their existing content; only the Server release identity changes. Components are consumed from their published original bytes, not rebuilt by this source change.

## Candidate boundary

Server579 is not yet published or accepted on a runtime cohort. Its normal Server CI, image/security/startup/restart gates and immutable publication must complete before installation instructions are updated. Preserve the current image and matching database backup for rollback; do not replace volumes or stored settings.
