# Server v1.6.559

Published image: `ghcr.io/pasturestack/server:v1.6.559@sha256:7af50ece5adc880a56e82cf39d70859f1faaea8393c0335a47da49dc7f8bc7cf`.
Producer `8d7c6033311c4152b6b0e8c888221372adef257f`; publisher 40977604932.
All original source/build/security gates, 35 public assets and native attestations
passed. Designated 8080 startup and actual restart passed with three active
Hosts/Agents, original persistent volumes/settings and the previous rollback.
Sixteen new-version layout profiles passed; the complete Core flow failed at
scoped Stack discovery (403) after successful creation. No partial flow is
promoted to full acceptance. Catalog/Archive and new domains remain pending.
Qualified component inputs do not establish Server559 runtime acceptance.

## Verified component inputs

Values below come from qualified CI and anonymous publication receipts, never
from a documentation merge head or rebuilt artifact. Web200 includes optional
bridge 0.2.2. Catalog/Compose SBOM and Go lock identities are retained explicitly;
their existing Server consumer contract pins original archive/binary bytes.
No unused ARG is invented to imply an additional consumer check.

### Web

- version: 1.6.200
- producer: 03e0d7b25b8dfcbc45baecf6d448834016aac649
- archive: web-console-1.6.200.tar.gz
- archiveSha256: 97fe46c426cb83263fcfc7f5884c15ca90f7ec3ebec71d9ca023d8b7ad2665c0
- runtimeSbomSha256: 0ce1f6b99e1e449c545d3d7df65302fdb58d1974fecea6477b20262c2148921c
- lockSha256: 1797dd27bb7b1c6b86b8689435e916b03523a9fdf45c5178ec7c2ea05706d4bd
- bridgeVersion: 0.2.2
- bridgeArchiveSha256: f6c2e4496aaa629925cbfc3217b7bdbfb96d710e9c51899bb8b15d8704c8da7c
- bridgeSbomSha256: dde9f55749b3d5d1d680fe0b334d7b4fb9b3fed10aa59abd4cd4a4cbeba6a723

### Catalog

- version: 0.20.17
- producer: 2f70559e340865eb6243662ed33d8cbc7b1efa90
- archive: catalog-service-0.20.17.tar.xz
- archiveSha256: 4f83f89763ce325262baf8984782da2c21fd81e3cc22c0a1c76aaa50b2a50f20
- binariesSha256.catalog-service: f2a63056d5d48e032bdfd0dbcbe1b2254f6353f1a76125f86a72a31ec532da45
- binariesSha256.catalog-service-sqlite: 94bd4729bd129c333435ab98963080f44d08bec00f814442c99c390ec97b46ce
- runtimeSbomSha256: 293e5938cb4aa0192ea2b29ee42ed36a5d39302f6785c9cfbed2a2d5bfc05c12
- goModSha256: d799cfa1b6acbe44b78027c56bfbaee88a06bd8894d220e61cce340e85dc1f66
- goSumSha256: 5f658cccf768ab6fa548d1ee7cd8fb371d32e7471d46a6a31470fba31ca925c5
- licenseSha256: 0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594
- metadata: catalog-2017-release-metadata.json
- metadataSha256: ac783ff2c6b7b7a3376dfcb0b5034066d989d80cbf83b81c62af3df45134f517

### Compose

- version: 0.14.40
- producer: 1835f8db645a8488e327b1f6e750bfdf3d1fb84d
- archive: compose-executor-0.14.40-linux-amd64.gz
- archiveSha256: fa7a4127793ef4e8e6ef18d926d74b50046a80dd2097b08878ef576ddfce6732
- binariesSha256.compose-executor: a5e5eaad64ac1938118c648546b63ee9e056ebea6d2a0f1618cb79ec0c3924cc
- runtimeSbomSha256: 4f8f477bfd6f4de63c2f51bc5977073dd63ac696dbf3749cebb79b1a3158bc7b
- goModSha256: c99c5d17dd458110a5feee3dbb8114f6125dad884bd5a9f0d94e27a5c8f60fca
- goSumSha256: 55bd76f3c5fef3851d40aea2fee602d452f06ac8f452d7d5053897e7bdfbde1a
- metadata: compose-1440-release-metadata.json
- metadataSha256: 1ccb7ef5ec9cb0f1c189f6d32dea029ec493679a5c08ec6c24a36eba8b454fa6

### Engine

- version: v0.183.359
- producer: eac3fde5fc7779b6107e2702785120a9c591927b
- tagSource: c11979a7426d942df3035583e4d0dea8f1a2553f
- artifactSha256: 07e7de2548bd98d5209bf3594d69fe5b9a5d7ddba36eed4b6b6e4406022c3f90
- runtimeSbomSha256: e0c3e7391370b1525517fc9335143db882b48b47e49c8ffd0f1df9c0436f1be1
- schemaSha256.readonly: 7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233
- schemaSha256.restricted: f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51
- tests.suiteCount: 396
- tests.errors: 0
- tests.failures: 0
- tests.skipped: 1
- tests.tests: 3748
- workflowRun: 40966528986

## Included behavior and boundaries

Server559 adopts Canonical Ubuntu 26.04 `libbrotli1 1.2.0-3ubuntu0.1`
after complete immutable-bundle verification. The earlier backport retains its
reviewed upstream-fix evidence; this switch follows the official-package
preference and does not assert that the earlier backport remained vulnerable.
The final official deb, signed index, dpkg identity, three SO hashes and native
controls are verified separately against actual rootfs/SBOM bytes. Original
bundle/helper/evidence bytes remain intact; other package checks stay exact.


The Compose OpenPGP applicability decision is bound to the reviewed 0.14.40
binary above. Its qualified source gate rejects OpenPGP dependencies; inspection
of the shipped Go function and inline-name table confirms absence of the affected
package while retaining positive maintained-crypto controls. Only this exact
consumer hash is refreshed; target/module scope and all severity gates stay.

The assembly includes opt-in typed Archive/restore and the first bounded
Catalog-to-new-Stack workflow with matching Catalog 0.20.17/Compose 0.14.40 owners.
Public tools never receive private Compose, question defaults, human secrets or
internal delegation proofs. Native owner validation, fresh actor/role/Key
ceilings, exact source/reference binding, human-cookie input/confirmation and
durable claim/receipt semantics remain. Restore neither starts resources nor
recursively restores children; existing stopped/system/parent rules still apply.

Scoped managed cleanup accepts only exact engine-captured legal parent-state
progress with UUID/owner/mapping/Key protections. Terminal AUTHORIZATION_DENIED
produces a safe failed receipt. Cancelled chains/uncertain writes are not replayed.
The original 558 Service-stop failure and fixture/transport/oracle histories
remain recorded; prior partial successes are not promoted to full workflow PASS.

## Required new acceptance: pending

Core Web200 lifecycle/receipt completion; Archive/restore including concurrency;
Catalog safe options, explicit human inputs/references, confirmation, launch and
completion; affected roles/Key denies, browser layouts and weak-model cases are
pending on the assembled Server. Designated 8080 must retain three healthy
Hosts/Agents and pass one actual helper restart, same operation/settings, and
first-generated random marker bytes on mounted storage. Earlier role/read/
layout/weak evidence carries only its original unaffected scope. This does not
complete all 243 business/query groups. Browser SBOM coverage remains incomplete.

## Opt-ins, performance and rollback

Preserve independent `api.ai.bridge.enabled`,
`api.ai.service.upgrade.enabled` and `api.ai.resource.change.enabled`.
The fourth opt-in is `api.ai.catalog.launch.enabled`; never enable it implicitly
or treat it as a permission grant. Normal Full/general and human UI/API routes
keep their existing contracts.

Preserve HTTPS/origin, MFA/session, operator settings, JVM performance settings,
mounts, AppArmor and all named/data volumes. At cutover reconcile new image
defaults with genuine operator deltas; do not copy old image-owned environment
values. This assembly does not change production, firewalls or authentication settings.

Back up the database and volumes, verify restore and retain the previous image/
container rollback point. Settle accepted work, cancel unused plans and revoke
temporary Keys before rollback. Keep durable receipts; never replay unknown
writes. Rollback may require a matching database backup. Do not remove volumes
or drop plan data. See the [upgrade guide](../upgrades/README.md) and
[Key rollback guide](../upgrades/api-key-policy-rollback.md).

Other component pins and all security statements remain unchanged. Ten Medium
occurrences across nine officially unfixed CVEs retain exact vendor tracking.
Applicable fixed, High/Critical, secret or untracked findings block publication.
No VEX exception is added.
