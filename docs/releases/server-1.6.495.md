# Server v1.6.495

Published Server artifact verified. This patch
packages Web Console `1.6.161` for the existing Certificate editor. The
Orchestration Engine remains `v0.183.327`; all other platform component coordinates,
runtime configuration, security policy and storage contracts remain unchanged.

The immutable published image is
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`,
from signed source `512d4b2377e34ce04a33266af19b62ed45949eda`.
[Publication run `36744673716`](https://github.com/PastureStack/server/actions/runs/36744673716)
completed successfully. Independent readback verified all 22 checksummed
assets, the checksum manifest, public tag/digest identity and component source
and archive hashes. The final image has one filesystem layer. Candidate and
isolated `8080` first start/restart returned `HTTP 200` / `pong`; the isolated
runtime contract and all five tracked database counts were unchanged.
The unchanged merged-rootfs security gate reports 52 raw findings and the exact
eight Medium vendor-pending package findings across four CVEs after VEX, with
zero untracked, Critical/High, fixed-available or secret findings. The next
vendor review is `2026-10-20`; this is not a zero-CVE claim.

The first candidate was blocked before publication by the unchanged security
gate: Ubuntu had published fixes for `CVE-2026-73193` and `CVE-2026-73194`.
The package stage now installs official `libdbi-perl`
`1.647-1ubuntu0.26.04.3` from the signed `20260930T000000Z` Ubuntu snapshot.
Both the Perl module and its native DBI library are SHA-256 checked against the
downloaded package and loaded in the final image. This is an official package
update, not a runtime patch or a vulnerability exception. Findings without an
official fix remain tracked separately; fixed-available findings still block
publication. See [Ubuntu CVE-2026-73193](https://ubuntu.com/security/CVE-2026-73193)
and [Ubuntu CVE-2026-73194](https://ubuntu.com/security/CVE-2026-73194).

A subsequent candidate stopped before publication because a filename search
also matched the package's `Bundle/DBI.pm` index. The manifest now identifies
the two actual Perl 5.40 runtime files explicitly; a real-package check and
missing-native-library negative check passed before rebuilding. The final
image retains exact-version, complete-package SHA-256 and module-load gates.

## Reproduced defect and narrow fix

On isolated `8080`, the native owner editor in `v1.6.494` stopped before Save:
the API intentionally did not return the private key, but the console applied
the create-schema required-key check to an existing certificate. The observed
failure was `KEY_REQUIRED`; no resource write was dispatched by that attempt.

The editor may omit the masked key only for an existing, matching Certificate
whose certificate and chain are unchanged. It submits only `name` and
`description` for that metadata update. Creating a certificate or replacing
certificate material retains full validation; nonempty replacement keys keep
their validation, including rejection of encrypted keys. The shared validator
does not globally exempt write-only or required fields.

No authentication, session, OIDC, MFA, permission, API status, database,
HAProxy or firewall changes are included. The existing load-balancer reference
guard and localized certificate-in-use error remain in place.

## Required evidence and acceptance boundary

The Web Console numeric tag is `1.6.161`, with source
`2ad068d62b5afd3cd213cde8addc5ebbef738130` and deterministic archive SHA-256
`fa3ec0bf5173fa75a53dd621b87e1f587b20d9ecc6e5cb42a703ac4f5f7e97e7`.
[Official validation run 36738408143](https://github.com/PastureStack/web-console/actions/runs/36738408143)
passed 738/738 tests and produced two byte-identical archives. Focused native
editor tests passed 25/25; locale gates reported zero missing, orphan or invalid
ICU keys. Publication used the new immutable Server tag and digest above;
`v1.6.494` was not overwritten.

Scoped owner/member browser checks on isolated `8080` passed Cancel, metadata
Save, refresh and the in-use delete explanation using the actual editor, with
stored certificate/key material preserved. Four exact-owned fixture deletes
completed with API/DB terminal readback and unrelated-row protection.
Earlier HOLD receipts remain HOLD: current scoped cleanup does not resolve
their historical foreign-baseline uncertainty. The broader resource/role matrix
remains INCOMPLETE. No company-site deployment is authorized.

For an isolated upgrade, preserve the current environment variables, named
volumes, restart policy, AppArmor configuration and HTTPS origin. Retain
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`
as the rollback image with those same settings. It retains the known native
Certificate metadata validation defect. This patch does not change stored data.
