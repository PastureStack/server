# Server v1.6.537 candidate

Prepared source only; no Server image or release has been published.

This candidate targets Web Console `1.6.190` and Engine `v0.183.350` for
Stack/Service archive and restore. It retains the pinned Server460 build base,
the other component producers, maintained CLI `v0.6.18` defaults, authentication,
performance settings and the three-volume persistence contract.

## Behavior

`archived` is a server-persisted boolean; missing values mean false. Archive
requires fully stopped services and associated instances, including sidekicks;
an empty Stack is allowed. System/infrastructure and driver resources cannot be
archived. Archive/restore only updates the flag: it does not stop, start, remove
or recreate containers, mounts or data volumes. Back up retained data separately.
Parent and child archive flags remain independent. Restore does not clear an
independently archived child. Restore archived resources before starting them or
adding/moving children into them; ordinary stop/delete behavior is unchanged.
New-resource clones omit the archive flag.

The console switch next to sorting is a personal, per-environment visibility
preference, not a bulk archive command. Counts, archived badges, direct details,
cross-tab updates, keyboard access, RTL and reduced-motion behavior remain
explicit. The effective schema and update capability govern write controls;
older Engines without the field do not offer archive. Native v1/v2-beta writes
retain the original role and API Key `update` authorization, including live
owner RBAC and scope limits. Archive writes send only `archived`.

## Reviewed isolated candidate evidence

The following local acceptance receipts concern pre-release feature inputs,
not the final537 image or the future published190/350 artifact identities:

- `backend-tests.json`: 63 unique focused tests, zero failures/errors/skips.
- `frontend-tests.json`: 37 unique focused tests; 36 unaffected results are
  carried forward and the actual compiled RTL stylesheet case was rerun once.
- `isolated-test.json` and `isolated-adjacent.json`: 31 core native checks plus
  three adjacent fresh-default/system guards, not a whole-platform suite.
- `archive-auth-matrix-results.json`: 88 native archive/restore pairs across
  v1/v2-beta, five roles, two projects and six Key modes; all passed. Separate
  `archive-role-browser-results.json` covers five actual role views.
- `archive-browser-results.json`: seven browser interactions and 52 layout
  groups (13 locales, light/dark, desktop/narrow), including keyboard, preferences,
  direct details and cross-tab updates. The banner fixture is explicitly an
  injected HTTP422, not a claim that the same UI test caused a real backend refusal.
- `archive-audit-only-results.json`: six native appendix checks plus four UI
  checks distinguish ALLOW/SUCCEEDED/200, DENY/DENIED/403 and ALLOW/FAILED/422.
  The minting owner reads its personal Key audit. Earlier admin reads of a
  foreign personal Key correctly returned403 and are not counted as audit PASS.
- `archive-physical-results.json`: six bounded real-host checks cover first-host
  registration/default infrastructure, CNI DNS/egress/health, running-service
  refusal, stopped Service/Stack archive/restore with unchanged runtime/mount
  fingerprints and bind/named-volume data hashes, and native reactivation of the
  same instance. `archive-host-lease-restore.json` records restoration of the
  original host state; no original VM data or volumes were deleted.

These checks do not claim a full preserved-database upgrade, distributed
multi-node race test, unrelated OIDC/MFA rerun or final release-image validation.
Formal image health/restart, security scan/SBOM, anonymous asset readback and
publication remain separate gates. Do not turn these local receipt names into
published asset claims without attaching their reviewed immutable evidence.

## Component identities and remaining release gates

The recipe pins the following reviewed packager outputs, not previous189/349
identities. Official component publication/readback must complete before Server
assembly; the pins alone do not establish a published Server image.

| Input | Pinned value | Locations |
| --- | --- | --- |
| `web-console-1.6.190.tar.gz` SHA-256 | `b06612812113fb4b54cf0f2b4754af077406306fd72407e04b17f2ad9f4dc927` | Dockerfile/build defaults, source gate and packaging-test `WEB_SHA` |
| Web190 producer commit | `9ff823c2233e2041c2f00bb56a91d147a7feaa1d` | Dockerfile/build defaults, source gate and packaging-test `WEB_SOURCE` |
| Engine350 `cattle.jar` SHA-256 | `637ddaa42cd93c019b4d0813d7053b71dc42797a7f3ac2aa4b10fcc7e304cb31` | Dockerfile/build defaults, source gate and packaging-test `ENGINE_SHA` |
| Engine350 producer commit | `9c884710e5ea3d4136d80a870d9de9485674f3c3` | Dockerfile/build defaults, source gate and packaging-test `ENGINE_SOURCE` |

The files are `server/Dockerfile.web-compose-release`,
`server/build-api-explorer-patch-image.sh`,
`scripts/check-server-api-explorer-patch.sh` and
`scripts/test-current-server-packaging-contract.py`. The local350 `cattle.jar`
was independently read back at 87,906,638 bytes with the exact SHA-256 above.
Its `WEB-INF/lib/cattle-resources-0.183.350.jar` contains `schema/v1/readonly.ser`
(340,159 bytes, SHA-256 `7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233`)
and `schema/v1/restricted.ser` (355,023 bytes, SHA-256
`f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51`).
These actual reads confirm the retained frozen-schema pins for this artifact.
Server537 producer commit, manifest/config digests, workflow and publication
readback are also pending and must be recorded from the actual final outputs.

The existing coordinate predicates continue to reject placeholders. OpenVEX and
vendor tracking advance their release IDs only: the 69 VEX statements, 11
vendor-pending CVEs/22 package rows, severities, fix policy and 2026-10-20 review
deadline are unchanged. This metadata update is not a new scan or remediation;
the new final-image security gate must still verify the exact current findings.

## Install and rollback boundary

Operational examples use only `ghcr.io/pasturestack/server:v1.6.537`, never a
digest-qualified or SHA-only installation tag. Run them only after official
publication and readback. Preserve all three existing named volumes, runtime
overrides and a working rollback container; do not restore old policy/revocation
or database state merely to roll back code. See the [upgrade guide](../upgrades/README.md).
