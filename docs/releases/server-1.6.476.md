# Server v1.6.476

This patch assembles Orchestration Engine `v0.183.326` and Web Console
`1.6.141` on the preserved Server `v1.6.460` runtime base. Other component
versions remain unchanged from `v1.6.475`. It includes no database migration,
OIDC configuration change, HAProxy change, or production deployment.

Orchestration Engine restores `projectTemplate.isPublic` as a read-only field
in the frozen `/v1` non-admin user schema, matching `/v2-beta`. The
administrator's create/update schema and ProjectTemplate authorization remain
unchanged. Web Console gives ProjectTemplate direct edit URLs the same
localized denial for 403, 404, and owner mismatch; 401 still follows the
existing session recovery path. API-key save failures display the existing
API error inside the modal without exposing key values.

## Immutable component inputs

- Orchestration Engine `v0.183.326`, commit
  `66160dfc1d9d134d1c9c85b4f2908c3f07f99365`, `cattle.jar` SHA-256
  `6427120ef0047deb0c436a5cd9167a9afb3a2fb3075123b50340ec1216a5fe81`.
- Web Console `1.6.141`, commit
  `9a8bb1166a076d08962cd0a653c7233e2166b11d`, archive SHA-256
  `3643944c1c9ed098a030ec8947f0b33e290c09d49257bd51e8401cc0196fe2f3`.
- Webhook Automation Service remains `0.10.3`; Authentication Service remains
  `0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

The Server build verifies release asset hashes and contents, component
versions, source records, and nested Engine jar identities. Publication
requires the isolated boot/restart gate, merged-rootfs security inventory,
source and SBOM identity checks, and image digest readback. Image publication
does not establish role-by-role behavior on the existing QA service.

## QA and deployment boundary

The ProjectTemplate matrix should cover administrator, exact owner,
different owner, public, and private templates across list controls, direct
edit URLs, schema action links, and actual API mutations. Check 403, 404,
owner-denied, and 401 direct-edit responses in English and Traditional Chinese.
Check failed API-key save feedback in the modal and confirm no key value is
rendered. Keep untested rows explicit. Publication does not deploy QA or
`stack.ascdc.tw`.

## Upgrade and rollback

After publication, replace only the Server image reference with immutable
numeric tag `ghcr.io/pasturestack/server:v1.6.476` and its verified digest.
Keep the existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.475` image with the same
configuration and volumes; do not overwrite its tag or digest.
