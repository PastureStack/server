# Server v1.6.516

Status: source candidate packaging published components. The immutable Server
image, independent artifact readback, isolated deployment and native acceptance
are pending. Full functional/authorization/localization matrix: INCOMPLETE.
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
unchanged. The official publisher must regenerate artifact scans, SBOM, startup,
restart, checksums and provenance before a published image can be claimed.

Quick Start remains pinned to published 515 until immutable 516 artifact readback.
Keep the previous image, Compose environment overrides, named volumes, runtime
security settings and database backup. A later isolated deployment must preserve
them and independently verify the actual image/config identity. No SQL DML,
production HAProxy change or company-site deployment is part of this repair.
Catalog API template IDs may remap within the existing refresh transaction;
semantic template identity and operator overrides must still be preserved.
