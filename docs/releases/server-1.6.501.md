# Server v1.6.501

Candidate packaging; no immutable Server digest or QA browser PASS is claimed
before the official publisher and packaged verification complete.

## Bounded correction

Web Console `1.6.165` source `00bcd9fdc92afead708dffb4a2b3b01f4ebaeaa0`
fixes indistinguishable clipped rollback-container names on Host cards.
The shared `.container-subpod` name area wraps, while IP/action children
retain their own space. Global clipping, Host titles, actual names/IDs,
stack-prefix display, API/schema and authorization are unchanged.
No migration or runtime patch is required.

The signed numeric Web release reuses the exact archive from official
[validation 36979009940](https://github.com/PastureStack/web-console/actions/runs/36979009940):
`web-console-1.6.165.tar.gz`, 2,976,219 bytes, SHA-256
`5baaa4879fe5548cc8b66cd1c7a2005edf586d4b5f12b6dbb3796b6692e41959`.
Actual CI passed 767/767 cases with zero failures/skips/todos and produced two
identical production archives. Four new real compiled-CSS cases cover
light/dark, LTR/RTL, narrow viewports, long/Traditional Chinese names and child
rows. Focused local execution passed 744 assertions; the adjacent empty-pod
case passed 88. The first incorrect test-fixture button failure is retained,
not overwritten or fixed by weakening assertions.

## Preserved components and contracts

Engine remains `v0.183.331`, source
`515a5d37a1194f827bc3ffde34db729905ecb2b1`, exact WAR SHA-256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`.
No new Engine build or backend behavior change. Existing role/schema denials,
OIDC/TOTP/Passkey, generation/mutex/session-bound logout, Compose environment
overrides, named volumes, public origin, restart policy, AppArmor and nftables
remain unchanged. Runtime base `v1.6.460` and all other component pins stay fixed.
The eight exact Medium vendor-pending package findings remain unchanged, with
review deadline `2026-10-20`; this is not a zero-CVE claim or expanded exception.
OpenVEX statements and security thresholds are unchanged.

## Verification boundaries and upgrade

Official Server packaging, final-image checks/SBOM/security readback,
QA8080 first start/restart, six exact Docker/instance name bindings and actual
native initial/reload readable-name/menu/WebSocket evidence are still pending.
The historical Server500 technical PASS plus visual HOLD remain unchanged.
Full resource/role, all-page/all-locale and company-site acceptance are separate
and INCOMPLETE. Do not deploy a candidate or use old green receipts as proof.

Once published, upgrade by changing only the immutable Server image reference
in the existing deployment. Preserve the current data/settings and stopped
Server500 for rollback; no database migration is introduced. Restoring 500 also
restores its clipped-name layout. Do not delete or manually rename retained
rollback containers to make the list look clean. The current published 500
image remains the README quick-start reference until 501 publication completes.
