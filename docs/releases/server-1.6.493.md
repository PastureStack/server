# Server v1.6.493

This release packages Web Console `1.6.159` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`, with a narrow
official Ubuntu OpenSSL security-package refresh described below.
Web Console source commit `aab95cf41ebc45e4c51513d9589602ab990399c9`
includes merged [PR #135](https://github.com/PastureStack/web-console/pull/135)
and [PR #136](https://github.com/PastureStack/web-console/pull/136).
Official validation run `36686121660` passed with 723/723 tests and matching
deterministic production builds. Its published release asset is
`web-console-1.6.159.tar.gz`, containing `VERSION.txt=1.6.159`.
The official archive SHA-256 is `f014083480e10430701e3a08588cf617242188938d9f935fbaac42a3b5feeb90`.
Official publication workflow `36691257808` passed and published the immutable
numeric tag `v1.6.493` from signed Server source
`dc17c6f44e0624f0be324bfa0e682bb063674219`. The image is
`ghcr.io/pasturestack/server:v1.6.493@sha256:61067362a2d91b791c7e80cb2ec4a5a907bc03884774d2019dccf1bf0e29788f`.
It has one filesystem layer. All 22 files in its SHA-256 release manifest were
independently downloaded and verified. Official first start/restart, public
HTTPS origin, private API no-store, runtime TLS, MFA, host-api and artifact
security gates passed, with identity-bound SBOM and provenance published.

Isolated v1.6.492 QA caught an existing Registry credential GET returning
`secretValue: null` on both API versions. The old editor sent that masked value
back even on a username-only edit. The fixed browser editor omits blank,
missing and null passwords, sends only an explicitly entered nonempty
replacement, and preserves its literal whitespace through form validation.
It explains blank-keeps-existing behavior in English, Traditional Chinese and
Japanese. Fresh credential, parent-registry, selected-project and current
capability guards remain unchanged, as do missing-credential POST recovery,
Server authorization, OIDC/MFA, sessions and proxy behavior.

The first candidate publication run `36688080817` was correctly stopped before
push by the rootfs security gate. [Ubuntu USN-8847-1](https://ubuntu.com/security/notices/USN-8847-1)
provides fixed OpenSSL packages at `3.5.5-1ubuntu3.6`, including the High
`CVE-2026-84782`. The signed HTTPS Ubuntu snapshot `20260930T000000Z`
pins `openssl`, `libssl3t64` and `openssl-provider-legacy` at that exact version.
Installing all three replaces the previously source-built `3.5.8` CLI,
libraries, engines and legacy provider, rather than only changing package
metadata. Assembly and post-build gates verify the seven runtime files against
SHA-256 checksums extracted from the signed official packages,
matching CLI/library version, provider paths and curl/MariaDB linkage. The
existing curl `8.18.0-1ubuntu2.7` fix is retained in the same package stage.
This is not a new VEX exclusion or a vendor-pending exception; the existing
eight Medium vendor-pending findings and security thresholds are unchanged.
The replacement passed the normal artifact/runtime gates: zero untracked
findings, zero High/Critical findings, zero available-fix exceptions and zero
secret findings. Eight official vendor-pending Medium findings remain; this
is not a zero-CVE claim.

Focused headless Chrome QUnit tests passed 7/7, and localization source checks
passed. Same-major build/test patches for brace-expansion and Engine.IO passed
the unchanged High/Critical audit threshold and focused compatibility probes;
remaining Moderate findings are not declared fixed. The official archive is
published at the numeric `1.6.159` tag. Isolated 8080 deployment passed first
start and restart with unchanged account, credential, setting, membership and
host counts. The existing three volumes, AppArmor and runtime configuration
were retained, with the prior immutable v1.6.492 image preserved for rollback.

Scoped Registry QA `qa493reg2c11e8c4d611` passed: 24 six-role direct-ID GET
cells, eight no-access PUT/DELETE denials with unchanged state, eight readonly
405 cells classified as schema-method absence (not authorization PASS), and
two explicit password replacements through the two API versions. The native
owner editor passed Cancel with zero writes, one username-only Save with the
secret field omitted, same-page refresh and DB password preservation.
English, Traditional Chinese and Japanese controls/hints fit at 1440 and 390
pixels; that bounded check is not a claim of perfect site-wide layout.
Both exact run-owned Registry and Credential IDs reached terminal state after
four explicit cleanup operations. No external registry pull was attempted.
The member Service editor also passed native Cancel/Save/refresh/Delete,
with exact fixture cleanup verified separately. Four superadministrator
Secret PUT/DELETE gaps passed on both API versions without changing stored
secret ciphertext or unrelated resources. Remaining Stack/Receiver gaps
and broader UI/resource matrix acceptance are tracked separately.

Known Engine certificate lifecycle defects were reproduced during this QA:
name-only certificate PUT returns 422 because an omitted `cert` is parsed
as null, and the load-balancer delete guard omits alternate certificate IDs.
These require a subsequent Engine and Server release; neither is declared
fixed by this image. Do not remove a certificate used by a load balancer.
No full role/resource matrix completion or formal company-site deployment is
claimed. Keep the prior immutable image with its original volumes and runtime
settings for rollback. Vendor-pending findings remain registered unchanged;
they are not declared fixed by this release.
