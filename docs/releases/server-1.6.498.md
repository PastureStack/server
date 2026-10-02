# Server v1.6.498

Officially published as [Server v1.6.498](https://github.com/PastureStack/server/releases/tag/v1.6.498)
from Server source
`ea58d92167eef31b76c7616f41df4d515530c359` by successful
[publisher run `36954622994`](https://github.com/PastureStack/server/actions/runs/36954622994).
The immutable image is
`ghcr.io/pasturestack/server:v1.6.498@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7`.
Independent public readback verified 22 checksummed files plus their manifest,
tag/immutable manifest byte identity, version/source labels, SBOM identity,
official component assets and a single filesystem layer.

Official isolated first start/restart returned `HTTP 200` / `pong` (10 and six
attempts). All 34 MFA policy/API checks and TLS 1.2/1.3 checks passed, with
untrusted certificates rejected. The unchanged merged-rootfs security gate
reports 52 raw findings and eight exact Medium vendor-pending package findings
(four unique CVEs) after VEX, with zero untracked, Critical/High, fixed-available
or secret findings. This is not a zero-CVE claim. Publisher smoke uses a
separate disposable database and does not establish backend-write authorization
or company-site deployment.

The QA `8080` upgrade passed first start/restart `HTTP 200` / `pong` (11 and 10
attempts). Runtime-contract and tracked five-table DB-count differences were
zero. This is count preservation, not whole-database row equality.
The three original named data volumes, environment overrides, `docker-default`
AppArmor and `unless-stopped` restart policy were preserved. Docker health is
`null`; no Docker `healthy` result is claimed. The previous immutable 497
rollback container remains retained and stopped. Limited Receiver
role/API/header/message gates passed in scoped QA; the broader matrix remains
INCOMPLETE. Secret and other 498 resources, all-resource, full-page and
all-locale acceptance are not established.

The Receiver regression used one fresh owner-created inert fixture. All 21
role reads matched their expected status and actor/context boundary: six member
reads returned 200 with privileged capability access retained; six restricted
and six readonly reads returned 200 with safe typed configuration and hidden
URLs, while v1/v2-beta GenericObject exact and complete-list reads omitted
key/resourceData entirely. Three no-access exact reads returned 403; actor
identity was established separately rather than inventing absent response
headers. Member Add was visible, restricted/readonly Add was hidden, and
direct-create denial messages were visible in Traditional Chinese. The
no-access UI displayed its 404-style unavailable message, distinct from the
backend's 403 authorization response. Six safe crops were visually reviewed;
this was not a full-page or all-locale review.

Each of the five roles completed separate Authentik and platform MFA. The
normal owner POST/DELETE and cleanup passed with 30 bounded full-15-table
guards and four ordered authentication transitions. Browser checks dispatched
no resource writes, and no endpoint execution, console loading errors or
page errors were recorded. These finite gates do not establish all Receiver
mutation cases or the complete role/resource matrix.

This patch consumes Orchestration Engine v0.183.329 to close GenericObject
capability reads by readonly/restricted roles. It uses the existing role-schema
boundary, including the actual frozen v1 schemas; it does not special-case a
plugin or change stored Receiver configuration. Owner/member/service clients
retain storage access. Low-role opaque GenericObject consumers must use the
authorized typed plugin API, which retains safe configuration and hides URLs.

Web Console 1.6.164 and Webhook Automation Service 0.10.3 stay unchanged. The
runtime base, Compose, three named volumes, AppArmor, nftables, OIDC, MFA,
session ownership, database schema and stored data remain unchanged.
The official Web Console archive SHA-256 is
`734898ac6ed2fe8774e5bb947988da9720a3a65aa0bb7ec09a89420adc0acc20`, from
source `c3c0779d930d4d0367ec0517166ca21f6b3dc6d4`.

Engine v0.183.329 is officially published from CI source
`14e3f0919a33282ff3026c364182f715f5dda634`; its exact WAR SHA-256 is
`9f8e5736898b6d9c51cb96d5f7cdbe8e3831a29ce296909108f5f2d5a68f7ec4`.
The normal build executed 266 suites / 1,123 tests with zero failures, errors
or skips, including four response/overlay cases plus two actual frozen-v1
cases. Build/security and CodeQL gates passed, and the exact CI WAR completed
isolated JDK 25.0.3 / H2 startup with no platform data or network.
The producer verifies only the intended two fields
change in GenericObject and inherited Register snapshots; unrelated contracts
remain identical. Server assembly checks exact WAR and both low-role frozen
schema hashes. The limited Receiver proof above is packaged QA evidence;
unrelated Server role/browser proof remains a separate gate.

The first Server publisher [run `36953191960`](https://github.com/PastureStack/server/actions/runs/36953191960)
failed its security gate after official fixes became available for
[CVE-2026-42772](https://ubuntu.com/security/CVE-2026-42772) and
[CVE-2026-54873](https://ubuntu.com/security/CVE-2026-54873): two Low CVEs across
three OpenSSL packages, or six package findings. That failed run is retained.
This release selects official Ubuntu 26.04 package
`3.5.5-1ubuntu3.7` from the signed HTTPS `20261002T000000Z` snapshot. The existing
whole-package install, SHA-256 checks and exact runtime versions remain required.
Only those two CVEs leave vendor-pending; the other four CVEs / eight Medium
package findings and their `2026-10-20` review date are unchanged. No VEX or
fixed-available/security threshold is relaxed. The successful publisher and
independent public readback establish publication only; the scoped QA proofs
above remain separate evidence.

The QA497 reproduction used the restricted role in a scoped environment to read
an owner-created inert Receiver through v1 GenericObject. No execution endpoint
was called. The historical HOLD remains HOLD, and its fixture was normally
deleted by the verified original owner. No claim of all-role/all-resource,
all-language/full-layout or company-site acceptance is made.

No migration or runtime patch is required. Preserve the v1.6.497 image and
original configuration/volumes for rollback, but note that rolling back restores
the low-role capability exposure. Remaining pending vendor findings and security
thresholds are retained; this release does not claim zero findings of every
severity.
