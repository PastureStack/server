# PastureStack Server v1.6.377

Server v1.6.377 embeds Web Console `1.6.80` and adds a permission-scoped audit
investigation surface. Server `v1.6.358` remains a visual reference only: no
application code, dependency, runtime, security fix, or current feature is
reverted.

## Operator-visible result

- Audit logs can be bounded by an explicit start and end time and filtered by
  friendly environment and user names instead of raw IDs.
- Optional incident conditions cover interaction channel, event, description,
  resource, client IP, and authentication type. Environment choices remain
  restricted to projects visible to the signed-in account.
- Results use natural sorting and can be exported as XLSX, CSV, or JSON through
  the same permission and time-bound query path.
- The existing audit result table structure is unchanged. Only the filter and
  export controls are redesigned.
- New local accounts cannot retain a blank display name, and the reviewed
  API-store compatibility package no longer fails route initialization while
  creating a deferred request.

## Bound release inputs

- Web Console: `1.6.80`
- Web Console source: `517de3f091f89deb8a4f6b854de8f2818a8bf6d3`
- Web Console archive SHA-256: `f2354943787f7f2edff888658cb25ac4683428715c9eece97805e9f19a5a74df`
- Web Console validation run: `33247124611`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.80>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The release keeps Ember `7.2`, Bootstrap `5.3.8`, Go `1.27.0`, OpenSSL `3.5.8`,
zlib `1.3.2`, the current OpenVEX closure, and all existing runtime hardening.
The publish workflow verifies the exact Web Console artifact, source gates,
start/restart smoke tests, merged-rootfs vulnerability and secret scans, SBOM,
provenance, image readback, and immutable release creation before deployment.
