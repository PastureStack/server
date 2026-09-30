# Server v1.6.495

Preparation only; this image is not yet published or accepted. This patch
packages Web Console `1.6.161` for the existing Certificate editor. The
Orchestration Engine remains `v0.183.327`; all other component coordinates,
runtime configuration, security policy and storage contracts remain unchanged.

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
ICU keys. Publication must use a new immutable
Server tag and digest; `v1.6.494` must not be overwritten.

The failed native browser receipt remains a failure. Fresh owner and member
browser checks must verify Cancel, metadata Save, refresh, unchanged stored
certificate/key material and the in-use delete explanation. Component tests,
image publication and startup do not establish browser acceptance or completion
of the broader resource/role matrix. No company-site deployment is authorized.

For an isolated upgrade, preserve the current environment variables, named
volumes, restart policy, AppArmor configuration and HTTPS origin. Retain
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`
as the rollback image with those same settings. It retains the known native
Certificate metadata validation defect. This patch does not change stored data.
