# Server v1.6.499

Officially published as [Server v1.6.499](https://github.com/PastureStack/server/releases/tag/v1.6.499)
from Server source `0a656e617c51059b92fb37a9b0571f142e8463aa` by successful
[publisher run `36969193015`](https://github.com/PastureStack/server/actions/runs/36969193015).
The immutable image is
`ghcr.io/pasturestack/server:v1.6.499@sha256:8552137dd4e40bf20dee5524cabf09540ed7431328e584ca1e488065e6fec394`.
Independent public readback verified 22 checksummed files plus their manifest,
tag/immutable manifest byte identity, version/source labels, SBOM identity,
official component assets and a single filesystem layer.

Official isolated first start/restart returned `HTTP 200` / `pong` (12 and eight
attempts). All 34 MFA policy/API checks and TLS 1.2/1.3 checks passed, with
untrusted certificates rejected. The unchanged merged-rootfs security gate
reports 52 raw findings and eight exact Medium vendor-pending package findings
(four unique CVEs), with zero untracked, Critical/High, fixed-available or secret
findings. This is not a zero-CVE claim. QA499 first start/restart returned
`HTTP 200` / `pong` (nine attempts each). Environment overrides, three named
volumes, `docker-default` AppArmor and `unless-stopped` restart policy remained
unchanged, with zero runtime-contract and tracked five-table count differences.
Docker health is `null`, not Docker `healthy`; counts do not establish whole
database equality. The stopped 498 rollback is retained.

Targeted imported-name acceptance did not pass. Read-only inspection found
three stopped rollback containers with normal inactive host mappings, while
Engine330's shared selection/CAS condition incorrectly requires an active
mapping. They therefore retain the original `pasturestack-server` name. This
requires a new immutable Engine/Server release accepting running/active or
stopped/inactive pairs while preserving all other guards. No SQL update,
container deletion, runtime patch or company-site change was used. The browser
HOLD remains HOLD and is not promoted by deployment success.

This release consumes Orchestration Engine `v0.183.330` from exact CI source
`3f7320a8063a5471618be5b8be6a168f49559847`. Its exact CI WAR SHA-256 is
`c01cbbfd63625fc09f39c5494775919aad6db22c92050b217b28b940b57e1de3`.
The normal CI build executed 268 suites / 1,141 tests with zero failures, errors
or skips, including 19 native-name cases and six retained GenericObject cases.
Packaged module version 330 and frozen role schemas passed the CI checks.
These are component CI results, not Server publication or QA browser proof.

The change synchronizes the name of an eligible standalone imported native
container to its freshly inspected Docker name. The host/agent/resource-account
binding, unique nonremoved host mapping, full Docker ID, physical service-index
and stack exclusions, locked fresh inspection and compare-and-swap protect the
update boundary. Managed-service logical names and unrelated instance fields
are preserved. Stale inspection or a changed compare-and-swap boundary does not
authorize an update; a notification failure after an applied update is not
reported as if the update never committed.

Web Console `1.6.164` remains source
`c3c0779d930d4d0367ec0517166ca21f6b3dc6d4`, archive SHA-256
`734898ac6ed2fe8774e5bb947988da9720a3a65aa0bb7ec09a89420adc0acc20`.
Webhook Automation Service `0.10.3`, the immutable `v1.6.460` runtime base,
Compose, three named volumes, AppArmor, nftables, OIDC, MFA and session ownership
remain unchanged. No migration or runtime patch is required.
No database-schema or stored-data-format migration is required.
The Engine329 low-role GenericObject protection remains enforced: assembly
retains exact readonly frozen-schema SHA-256
`7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233`
and restricted SHA-256
`f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51`.

The first 499 [publisher run `36968445931`](https://github.com/PastureStack/server/actions/runs/36968445931)
failed because the source gate incorrectly required historical 497 install
examples in the current 498 Quick start. That failed evidence is retained.
The follow-up checks latest-published numeric install identity without relaxing
digest, runtime or security gates.

For rollback, preserve the retained 498 container and original volumes/settings.
The official component/release, isolated Server and QA deployment gates above
passed; targeted imported-name acceptance failed as described above. Browser
acceptance must compare fresh full-ID Docker proof with each native Host1 model
and visible name, including one real reload and safe visual crops. Existing
498/497 receipts and HOLDs are retained without promotion to 499 PASS. This
publication does not establish all-resource/all-role, full-page/all-locale or
company-site acceptance. Only the VEX document identity and vendor tracker
release are relabeled to 499. Findings, package versions, explanations,
timestamps, review dates and all security thresholds are unchanged; no zero-CVE
claim is made.
