# Server v1.6.493 candidate

This candidate packages Web Console `1.6.159` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`, with a narrow
official Ubuntu OpenSSL security-package refresh described below.
Web Console source commit `aab95cf41ebc45e4c51513d9589602ab990399c9`
includes merged [PR #135](https://github.com/PastureStack/web-console/pull/135)
and [PR #136](https://github.com/PastureStack/web-console/pull/136).
Official validation run `36686121660` passed with 723/723 tests and matching
deterministic production builds. Its published release asset is
`web-console-1.6.159.tar.gz`, containing `VERSION.txt=1.6.159`.
The official archive SHA-256 is `f014083480e10430701e3a08588cf617242188938d9f935fbaac42a3b5feeb90`.
No `v1.6.493` image or packaged browser acceptance is established yet.

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
The replacement candidate still requires the normal artifact/runtime gates.

Focused headless Chrome QUnit tests passed 7/7, and localization source checks
passed. Same-major build/test patches for brace-expansion and Engine.IO passed
the unchanged High/Critical audit threshold and focused compatibility probes;
remaining Moderate findings are not declared fixed. The official archive is
published at the numeric `1.6.159` tag; the immutable Server image,
first start/restart, isolated
browser cancel/save/refresh, DB password preservation, dual-root exact-ID
authorization and disposable fixture cleanup are separate pending gates.
No full role/resource matrix completion or formal company-site deployment is
claimed. Keep the prior immutable image with its original volumes and runtime
settings for rollback. Vendor-pending findings remain registered unchanged;
they are not declared fixed by this release.
