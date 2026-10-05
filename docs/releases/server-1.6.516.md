# Server v1.6.516

Status: immutable Server image published; independent public artifact readback
passed. Isolated QA deployment passed; complete native acceptance remains pending.
Full functional/authorization/localization matrix: INCOMPLETE.
Historical HOLD evidence is retained; no production deployment is authorized.

## Repair

Web Console `1.6.178` repairs inactive environment details. Global project and
member reads settle first. Only exactly inactive projects omit the scoped network
and policy-manager reads that the Engine correctly denies. Global view, metadata
edit, members and removal remain governed by their existing capabilities.
The existing help-block explains why network settings are unavailable; stale
cached network values cannot be submitted. Other states, global errors and 401/403
handling are not converted into fabricated empty collections. All 13 packaged
locales have the new hint.

The previous ended logs/terminal workspace repair is retained. API contracts,
session generation/mutex, OIDC, TOTP, Passkey and MFA are unchanged. This is a
source release and normal image assembly, not a runtime patch.

## Published Web component

- Numeric lightweight tag `1.6.178` binds signed source
  `60a494e943150ecd300d1aa653ee397f590b575b`; the tag itself is not signed.
- Reviewed tree `26f727e39de73cc217494e3544d94a9881960195`; normal PR #177
  squash merge `f8ac3e2bf5854ab854adc1062321bcc16e29d224` has the same tree
  and verified signature.
- [Formal CI 37273270200](https://github.com/PastureStack/web-console/actions/runs/37273270200):
  848/848 passed, zero failures, skip or todo; 7 new inactive-project regressions
  and 17 retained ended-workspace regressions. CodeQL checks passed.
- `web-console-1.6.178.tar.gz`: 2983001 bytes, SHA256
  `7d4476f3ae1ecd455d0de25008b62327d8c2fa02fafe2b5252ce79fb3309d981`.
  Both CI builds and anonymous immutable public download are byte-identical.
- Public component receipt SHA256
  `a506a27699eeed6464878d1b46ef7453e74ace6410422da9870f3bf6e5ae1e7a`.

The first localization-gate failure remains recorded; missing keys were fixed,
not exempted. Build advisory GHSA-vfj7-8cjw-p6xm retains its 2026-10-10 review
deadline. Absence of affected build modules from static output is not a global
zero-CVE claim or native browser acceptance.

## Catalog and plugin boundary

Image defaults pin Catalog commit `7670ffd81d5f0b5570197fb03c7e55b46da45bf3`,
the verified normal PR #16 merge. Exact-source CI 37270871104 passed four Catalog
API integration cases with one unrelated case deselected, source contracts and
CodeQL. IPsec Overlay 12 (visible version v0.3.10) references the published
runtime `v0.14.38` at exactly four existing image locations; version 11 remains.

The published IPsec runtime source is
`c143e9a5f21ba6df2d1c5002340c71777f875c89`, manifest digest
`sha256:5b29e08dca8a92fc0ecc7f9d0fdae0457b89daa9d02b1c1c3257bc9dd617c3ae`.
That digest is verification evidence, not a rewritten catalog deployment tag.
Backend selection, XFRM namespaces, CNI/sidekick ownership and explicit user
catalog settings are unchanged. Template publication does not activate or upgrade
existing stacks. Managed upgrade and deployed plugin/firewall lifecycle acceptance
remain pending; no legacy module loading or firewall fallback is introduced.

## Assembly, verification and rollback

Engine `v0.183.333`, Catalog Service `0.20.12`, Server460 immutable base, four
build stages, one merged runtime layer and all remaining component pins remain.
VEX and vendor-pending declarations change only their release identity; the 51
reviewed statements, exact vendor-pending set and 2026-10-20 review deadline are
unchanged. [Official publisher 37275775509](https://github.com/PastureStack/server/actions/runs/37275775509)
completed artifact scans, SBOM, isolated candidate startup/restart, checksums and
image provenance. Independent public artifact readback passed; this is not QA
deployment or native browser acceptance.

- Server source: `e024e054be7371c60d719d0590ca3f5b86bdb6ee`, reviewed tree
  `673ab3cc35c4477b8604eec0e3691e0636af4f0e`; normal PR #255 merge retains that tree.
- [Immutable release](https://github.com/PastureStack/server/releases/tag/v1.6.516):
  `ghcr.io/pasturestack/server:v1.6.516@sha256:3741b7d87273387f36b49e44d407c240658db0ab7fc7fb8d518ae08f55ac733c`.
- Config digest: `sha256:0809df0b2a6c3c8d074139ad397a9662db772740b2a56a99b6bcd384664337c3`.
- Single compressed runtime layer: 531164624 bytes, digest
  `sha256:8af8706d94e582b3100738c1daeed2e84c2f3073cbdb8868332242ca13474127`.
  Registry metadata does not prove a complete layer transfer or deployment.
- `server.cdx.json`: 964181 bytes, SHA256
  `7c7bddb2dbf9017cbf7cbbcccbc7400b7651c61721f9c064c55ae25e774028a1`;
  CycloneDX 1.7, 892 components, exact image digest/revision identity.
- Security gate: 52 raw findings, eight tracked vendor-pending findings,
  zero untracked, actionable Critical/High, fixed-available or secret findings.
  This is not a zero-CVE claim; existing review deadlines remain.

## Isolated QA and bounded native observations

The actual isolated 516 deployment passed independent readback. First start and
restart each reached HTTP 200/pong after ten bounded probe attempts; this does
not mean every probe returned 200. Runtime settings and five core-table counts
have zero differences. Existing AppArmor, three named volumes, environment and
`unless-stopped` policy are preserved. Docker health is null, not healthy.
No company-site deployment is claimed.

For one existing inactive environment, native detail and reload, write-free
edit/remove cancellation, one native DELETE 200 and three full guard
acknowledgements were observed. The native finalizer and list/reload absence
checks completed without browser errors. The parent still recorded HOLD after
its cleanup wait timed out. A separate read-only database observation confirmed
the environment and four networks were purged, with no remaining members or
dependent resources. Three foreign host-row hashes differed and were not
excluded or classified as harmless. Fresh API and complete foreign-data
preservation verification remain incomplete. These observations do not establish
a complete native lifecycle PASS or promote any historical HOLD. The full
role/resource/locale matrix remains INCOMPLETE.

Quick Start now pins the independently read-back immutable 516 image.
Keep the previous image, Compose environment overrides, named volumes, runtime
security settings and database backup. The isolated QA deployment preserved
the runtime configuration and verified the actual image/config identity. No SQL DML,
production HAProxy change or company-site deployment is part of this repair.
Catalog API template IDs may remap within the existing refresh transaction;
semantic template identity and operator overrides must still be preserved.
