# Server v1.6.555

Published image: `ghcr.io/pasturestack/server:v1.6.555@sha256:59b2335d31c705184a155d21d89ee3be99b71b841d2b674b5d6c4ba656c730cc`.

Source commit: `db04a4710c4d7019913610afbdd912245dc488d1`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

- Web Console `1.6.197`: producer `4c18b92c926bdadc66d9da5cb1e1cedb5d5677f3`,
  archive SHA256 `f45b4c1357199bed491f5a708d6103996f7f03313b6045d3e81f6bb7464fd7ad`.
- Engine `v0.183.355`: producer `9ea138d1db1718cf65157c9564c379e62bafe9a0`,
  `cattle.jar` SHA256 `a7f651f84a9fe6deef2c9f66f50c13c70e450e25f9dfa6fb59129b2681f9f54f`.
- Secret Delivery API `v0.3.4`: producer `705589989f542669b7e60e1fdab8ae2694ed5d5d`,
  archive SHA256 `941bed664e04f21d84754cd9e06e1d69cec1583ed6dbdadda13567f778605010`.
- Machine Driver Bundle `v0.16.6`: producer `d5bade2722a788f54fe7f3a25af6245336a1e841`,
  archive SHA256 `82747659c1c9c866ea0d4b5c8909e36f72445f97f13cdc7324c40f403e28a83d`.

## Fresh browser-session actor restoration

Server554 could resume an authenticated fresh-cookie session while its Web
Console account identity remained unset. The human upgrade-plan inbox was
therefore blocked even though authentication was enabled. Web Console 1.6.197
restores the authenticated actor used by that view. Existing roles, dedicated
API Key policy/revision checks and separate human confirmation remain intact.

The browser artifact retains the enabled capability ceiling with tools initially
off. The standalone stdio bridge is unchanged. Engine, other component binaries,
volume lifecycle behavior and all existing security decisions are unchanged.
Server555 receives its own image and release; Server554 artifacts are not replaced.

## Acceptance boundary

The Web producer completed its focused session-restoration tests and required
release checks. Server555 has passed its source, image, startup/restart and
runtime security gates. The final seven-tool UI flow and a random marker read
back across upgrade and restart remain separate 8080 acceptance work.
The earlier Server554 publication passed, but its blocked human-inbox flow
does not establish complete runtime acceptance or mounted-data preservation.
The 78 panel layout cases and other unaffected producer evidence are retained;
this correction does not claim completion of the full permission matrix.

## Publication validation and remaining limits

[Publisher 40868492262](https://github.com/PastureStack/server/actions/runs/40868492262)
passed the original source, final-image, startup/restart and security checks.
All 35 public assets passed anonymous byte/checksum readback. Native provenance
and CycloneDX attestations bind the exact source and digest above.

The raw runtime report retains 52 findings; the effective report retains ten
Medium package occurrences across nine officially unfixed CVEs, with review due
November 5, 2026. Untracked, High/Critical, available-fix and secret counts are
zero under the existing policy. Browser runtime coverage remains incomplete;
this is not a claim that every browser component has been fully scanned.

Scoped 8080 deployment and the complete seven-tool flow, including random-marker
persistence across upgrade and restart, remain pending. Publication does not
establish those deployment-specific results.

## Activation, upgrade and rollback

Follow the [AI collaboration guide](../ai-collaboration.md). Preserve existing
environment values, HTTPS origin, ports, AppArmor, restart policy and all three
named volumes. Do not use `docker compose down -v`. Upgrade plans still require
separate authenticated human confirmation; a dedicated bridge Key cannot approve
its own plan. Keep the previous image and a matching database/volume backup.
The [API Key rollback requirements](../upgrades/api-key-policy-rollback.md) still apply.
