# Server v1.6.501

Published immutable Server. Packaged QA browser acceptance is separate.

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

Official publisher 36980705366 completed successfully at exact source
`ea97b199801c277efc178430b4aa6a0d4f67d25b`. The public image is
`ghcr.io/pasturestack/server:v1.6.501@sha256:0a671e2695eecc74d79ef666267a40e81172205f0f8b1d0b12a7dbbed446becd`.
All 23 release assets / 22 SHA-256 entries and public registry/SBOM identities
matched. Final runtime is one layer, compared against the maintainable
multi-stage source build. Candidate startup/restart returned HTTP200/pong;
34 MFA/API checks passed, TLS1.2/1.3 worked and untrusted TLS was rejected.
Final-image raw findings are 52, with eight Medium package findings / four
CVEs vendor-pending. Critical/High, fixed-available, untracked and secret
findings are zero; no exception or security threshold was relaxed.

QA first start and one restart both returned HTTP200/pong (ten attempts each).
Runtime settings and database counts were unchanged; the container is running
and does not declare a Docker HEALTHCHECK, so its health field is null.
Fresh read-only COUNT proof matched six unique full Docker IDs to six instance
records. Native initial/reload both confirmed their complete names and absence
of nine removed records. Fresh Authentik and platform MFA were completed.
One native action-menu open/close cycle used two trigger clicks and no menu-item
clicks. Range/glyph containment and actual screenshot review both confirmed all
five rollback suffixes remain readable without overlapping IP/action areas.
Resource writes, retries, page/console/loading errors and unexpected document
loads were zero. Three WebSockets connected and one actual server message was
observed after reload; this is not a long-duration or reconnect assertion.
The historical Server500 technical PASS plus visual HOLD remain unchanged.
Full resource/role, all-page/all-locale and company-site acceptance are separate
and INCOMPLETE. Do not use old green receipts as proof of packaged acceptance.

Upgrade by changing only the immutable Server image reference
in the existing deployment. Preserve the current data/settings and stopped
Server500 for rollback; no database migration is introduced. Restoring 500 also
restores its clipped-name layout. Do not delete or manually rename retained
rollback containers to make the list look clean. The README quick-start now
uses the published 501 immutable image; existing installations must retain
their own environment settings and restart policy rather than replace them
with a fresh-install example.
