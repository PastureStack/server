# Server v1.6.496

Candidate packaging only. No Server `v1.6.496` image, digest or deployment is
claimed. Packaged desktop acceptance and isolated runtime acceptance remain
pending. The currently published Server remains
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`;
public quick-start and compatibility instructions still use that release.

This candidate packages the officially published Web Console `1.6.162`:

- Numeric tag and artifact source commit:
  `46501e31071b3d74595aea91908876eec32b7fd6`.
- Artifact: `web-console-1.6.162.tar.gz` (2,975,702 bytes).
- Archive SHA-256:
  `9c5b34d2cdf7ad354e1dab199795b12e5de119e47dc342547d5cdc84c7911581`.

The Orchestration Engine remains `v0.183.327`, from source
`dce2f2473ffea1510fe10676a771eb1fe5d0b161` and artifact SHA-256
`c6d4c3003a19db19d1be73e69aa52358a0a4166bf726cbefe7e2ab9ed5664b56`.
All other platform component coordinates and runtime dependencies are unchanged.

## Narrow desktop changes

The Host **Add Container** entry follows the current project's loaded Container
schema POST capability. Missing, loading, stale or revoked project schemas do
not enable the entry. This is a client UI capability gate, not evidence of
backend POST or PUT authorization; schema GET success is not write permission.

The Secret desktop table's State, Name, Description and Created headings use
the existing generic translation keys. The existing field names, sort and
search behavior remain unchanged. This does not claim mobile acceptance or
all-language acceptance, nor does it relabel historical English screenshots as
Chinese-language evidence.

No authentication, session, OIDC, MFA, API status, database, VM, permission
policy or vulnerability disposition changes are included. Existing historical
HOLD receipts remain HOLD. The broader resource/role matrix remains INCOMPLETE;
no full-site acceptance or company-site deployment is claimed.

## Required packaging evidence

The local source gate is not an artifact scan, image build, first start,
restart or native packaged-browser acceptance. A new immutable Server artifact,
its official digest/readback, merged-rootfs security gate and isolated runtime
checks are still required before publication or deployment claims. The VEX and
vendor-pending release identities are advanced for this candidate without
changing their vulnerability statements or findings. This is not a zero-CVE
claim.

For a later isolated upgrade, preserve the current environment variables,
named volumes, restart policy, AppArmor configuration and HTTPS origin. Retain
the published `v1.6.495` image above with those same settings as the rollback
image. No stored-data migration is included.
