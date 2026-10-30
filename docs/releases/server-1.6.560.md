# Server v1.6.560 candidate

Not published or runtime accepted. Install examples stay on published 559.
Both components passed required CI, same-tree merge and immutable publication.
All original public asset bytes were read back anonymously. Server assembly
and designated live acceptance remain separate pending gates.

## Verified component inputs

- Web 1.6.201 / bridge 0.2.3 producer: `24715414f143e2c58cf53084bd84cbea0922798f`; tag source `18acf40d85061533762e8d0d1b9c1f7be69afe9c`.
- Web archive SHA256: `5bc8142d9322657c5cbae782756c3aa5a45b6537074de8749066492fa8947eb8`.
- Runtime SBOM SHA256: `8b837eb330b9815df48b4256d3bf0c4e215864b996e2be40dd707ec532872503`; lock `d255b74a835ab7c0224d12613baacdf021d8b30d46204a71c22d57f35725666f`.
- Bridge archive SHA256: `aad5cadfd3806b0f2c7339a1585a6bd19f3e61585af91dd4da119514775e7e93`; 13 published assets verified.
- Engine v0.183.360 producer: `72230c8b471312377bae968c0c17d63e8ad97ffb`; tag source `d6845eedd1df5ae8e69cc075d80b166bc8d26731`.
- Engine JAR SHA256: `0ebbd517ee43e113f29cbc14fe542aa7c7900ae28d65d63a12c348b7f0ac9a21`; runtime SBOM `088ce2b94ea1c30a6d1e52e600d2ef45258aeb26cdded784407a91020a19f474`.
- Original Engine CI: 408 suites / 3822 tests / zero failure or error / one existing skip; 12 published assets verified.
- Engine provenance is original GitHub artifact/source/tree evidence; its workflow supplies no native SLSA attestation.
- Catalog 0.20.17 and Compose 0.14.40 retain the qualified original pins from Server559; other component/package inputs are unchanged.

## Behavior and owner boundaries

The matching Web Console 1.6.201 / bridge 0.2.3 and Engine 0.183.360 add bounded
External Service, DNS Alias and audit metadata workflows. External Service
creation is stopped; hostname and IP modes are mutually exclusive. DNS Alias
creation, local target binding and activation are separate reviewed changes.
Advanced links and incoming-consumer cleanup remain unavailable.

Fix project-scoped native and typed collection admission through the final
Catalog response validator. The actual SQL authorization guard attests only
this known query-preserving validator; unknown/synthetic filters and altered
query/pagination implementations still fail closed. RBAC and Key policy are
unchanged, including explicit denials and cross-project/parent isolation.

Audit queries use the installed broker's existing authorized sources via a
fixed bounded CLI and private stdin. Public tools receive safe metadata, never
cookies, Key secrets, arbitrary URLs/SQL or raw audit payloads. Engine records
the owner's actual query result; payload inspection/export remain human-only.
Catalog/Archive behavior and four independent default-off opt-ins are retained.

Audit events created in a Core write transaction retain their forced durable
spool until the existing independent replayer can commit delivery. A rejected
typed read must remain auditable after its outer write rolls back. The fix
keeps current metadata, capacity and failure behavior without nested account
locks. Source/transaction tests passed; designated live durability is pending.

## Required acceptance: pending

The previous 558 Service-stop failure, 559 post-create collection failure and
their original reports remain recorded. No partial result is promoted to a
whole workflow PASS. The designated 8080 complete Core lifecycle, Catalog
launch/Archive, new domains, affected Key/role/cross-ID, layouts and weak-model
cases remain pending. Retain only unaffected immutable evidence.

The baseline remains 243 business groups and 3,089 frontend inventory rows;
this release does not complete that inventory. Browser SBOM coverage retains
its recorded limits. KVM HOLD and explicit human ceremonies are not API grants.

## Upgrade and rollback

Deploy only the new immutable published image after necessary checks. Preserve
existing persistent volumes, origin/session/MFA controls, operator/JVM settings,
restart policy and AppArmor. Take normal database/volume backups and retain the
previous container/image. Never replay uncertain writes on upgrade/rollback;
settle or cancel plans and revoke temporary Keys. A matching database backup
may be required for rollback. Do not delete volumes or plan receipts.

Production, HAProxy, firewall and production data are outside this QA change.
Official Brotli package proof and all other package gates remain exact. No VEX
scope expansion or weakened security threshold is introduced.
