# PastureStack Server v1.6.428

This release fixes MFA policy saving and closes related live authorization
schema gaps without changing account identity, database structure, container
configuration, or unrelated UI layout.

## Operator-visible changes

- `PUT /v2-beta/mfaSettings/global` is an administrator-only update, not a
  collection create. All 37 declared policy and status fields are preserved.
- Advanced lockout, federated-MFA, passkey-counter and security-email settings
  survive save and reload. Local administrator recovery status remains read-only.
- Both regular users and administrators can complete their own security
  confirmation. Inputs and read-only outputs have explicit authorization.
- The browser recognizes structured MFA errors inside transport wrappers and
  opens confirmation before retrying a sensitive save. Cancel never resubmits.
- Unexpected API errors keep localized text plus bounded HTTP/code diagnostics;
  raw server responses are not shown.

## Security and compatibility

Global policy remains administrator-only. The fix does not enable collection
creation/deletion, bypass MFA, or remove account-holder checks. Confirmation
tickets remain account-bound, expiring, and single-use. SMTP passwords are
preserved when omitted or blank, cleared only explicitly, and never returned
by settings reads. The frozen `/v1` MFA contract and the `/v1` and `/v2-beta`
hardware/runtime/SHM/GPU contracts are retained.

The official publication pipeline now exercises the real MFA API on its
fresh, disposable Server database: authenticated admin save/readback, complete
field permissions, SMTP semantics, step-up/replay, passkey registration start,
regular-user denial and self-confirmation, and hardware-schema compatibility.
`scripts/test-mfa-policy-api.py` must never be run against an existing system:
it creates test accounts and modifies the disposable database.

## Release inputs

- Orchestration Engine `0.183.298`.
- Web Console `1.6.116`.
- Other component versions, pinned base, and runtime compatibility stay unchanged.
  Exact revisions and artifact SHA-256 values are pinned in the release Dockerfile
  and build script; publication binds the resulting image to its source revision.

## Remaining vendor advisories

The seven previously recorded Ubuntu Medium advisories (21 package occurrences)
remain vendor-pending in `server/security/vendor-pending.json`. They are not
claimed fixed or hidden. The release gate still rejects Critical/High,
vendor-fixed, unclassified, changed or expired findings and detected secrets.
See the release's SBOM, raw scan, OpenVEX and vendor-pending evidence for the
actual artifact result.

The inherited base retains curl and libcurl `8.18.0-1ubuntu2.5` for
`CVE-2026-8932`, glibc `2.43-2ubuntu2.4`, and GNU coreutils `uniq` upstream
commit `d64e35a8a4c0e4608321433e0d84d917e4e36371`. Ubuntu still marks
`CVE-2026-18374` as needing evaluation for Resolute. The OpenSSL closure for
`CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910` are inherited unchanged; unmatched vulnerability at any severity remains a release blocker.
