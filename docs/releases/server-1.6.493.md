# Server v1.6.493 candidate

This candidate packages Web Console `1.6.159` on the unchanged Server
`v1.6.460` runtime base and Orchestration Engine `v0.183.326`.
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
they are not declared fixed by this UI-only release.
