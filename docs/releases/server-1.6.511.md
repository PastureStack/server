# Server v1.6.511

Published Server artifact and anonymous public GHCR readback verified.
QA125/8080 upgrade and independent read-only checks passed. One fresh-key native
run is independently derived scoped verified with its original parent HOLD
retained; remaining native acceptance is pending.

## Scope

This release packages Web Console `1.6.173` for native Project Template
card names. Template choices read the existing model `name`; the previous
`localizedName` property is not implemented on ProjectTemplate. This changes
the native display source, not template payloads, role authorization or schema.

Orchestration Engine stays official `v0.183.333`, source
`0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
`8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
Reuse the digest-pinned Server460 base and existing single-runtime-layer
flattening/config comparison gates. Other component/package pins, security
policy, OIDC/MFA, production environment and persistent volumes are unchanged.
No migration or runtime patch is required.

## Verified immutable release coordinates

- Web173 published source: `c8b8bb2659fdad3539cf6a72866c94a77ec516b6`.
- Web173 published tree: `f590310e157edea79de81fcf333e8b39dbc5677e`.
- [Official Web CI37115288389](https://github.com/PastureStack/web-console/actions/runs/37115288389):
  812/812 tests passed; failures, skips and todo are zero. Two production
  archive builds are byte-identical.
- [Published Web Console](https://github.com/PastureStack/web-console/releases/tag/1.6.173):
  `web-console-1.6.173.tar.gz` under signed numeric tag `1.6.173`.
  CI archive SHA256: `a566684e6e0831630a15cb7212989c0e9fe707ed07965156c2b664b9cdb5ba27`.
  Immutable publication, SSH tag signature and anonymous public byte readback
  were verified; public archive bytes match this CI SHA256.
- Independent Web publication receipt SHA256:
  `e106fff8243adfc024525d25366adc0970fff38fd90ceb5c03115ea5d3ba0432`.
- Published Server source: `e995f8f35bc6335effaceb6c973f7915c68df2ab`.
- [Official publisher37116124788](https://github.com/PastureStack/server/actions/runs/37116124788)
  passed the source, build, flatten, start/restart, security, publication and
  attestation gates for this exact source.
- [Immutable Server release](https://github.com/PastureStack/server/releases/tag/v1.6.511):
  `ghcr.io/pasturestack/server:v1.6.511@sha256:bce474ce4403398044a7c24aafe6c8314bac38b44731540c5ffaa2dfc40699cd`.
  Public numeric-tag and immutable manifest bytes, config, source/version labels,
  all 23 assets and 22 SHA256 entries match. The final image has one runtime layer.
- Independent official-release/public-GHCR readback receipt SHA256:
  `a7f9788225beae90db9eddb97c6752d7f240f50828701967cd1b6ae0c38216d6`.
  This receipt does not perform QA deployment or browser lifecycle acceptance.
- The official isolated image returned HTTP200/pong after 13 first-start and
  9 restart probes. All 34 MFA/policy/API checks, TLS1.2/1.3 HTTP200, private
  `no-store` cache checks and rejection of an untrusted TLS certificate passed.
  These are this version's artifact checks, not copied Server510 counts or
  proof of Docker healthy or QA8080 deployment.

The actual merged-rootfs scan has 52 raw findings, 51 VEX statements and
8 Medium package findings covering 4 vendor-pending CVEs, with review due
`2026-10-20`. Critical/High, available-fix, untracked and secret findings are
zero. This is not a zero-CVE result. The severity, available-fix, vendor-pending
and VEX exact-set gates remain unchanged; no exception is widened.

## Remaining native acceptance and historical evidence

The QA125/8080 upgrade of this exact immutable image passed. First-start11 and
restart10 probes returned HTTP200/pong; independent read-only verification
confirmed unchanged binds, environment, `unless-stopped`, `docker-default`,
8080 binding and runtime contract. DB counts remained account529/credential4198/
setting38/project_member14/host3 before upgrade, after first start and after restart.
The image has no Healthcheck, so Docker healthy is not claimed. The deployment
receipt SHA256 is `219f932105d15b5e7762661654aa920fa14284dcf87781121f5098e3d940e686`.
The stopped exact Server509 rollback container and database backup are retained;
this is not company-site deployment or native resource acceptance.

The version-bound native read-only proof for existing Template117 passed with
three Full17/14 guards, zero resource writes and a source-bound same-ID empty
stacks/services proof; it is not a native-create finalizer.
Process native list/link/detail and same-ID direct GET passed for one current ID:
two API roots × six roles, 12/12 cells and zero resource writes. Other IDs and
write methods remain untested.
Fresh Project API Key `1c6998`, run `qa511freshProjectef9ce0d4273c`, is independently
verified as `DERIVED_SCOPED_KEY511_VERIFIED_NOT_ORIGINAL_PASS`. Its actual child
completed four native create/edit/deactivate/delete writes, 13 Full16/14 plus generic guards,
four native barriers and 18 first-delivery boolean checks, including the visible
modal/private clone and copy-component parameters with a redacted canonical Store.
Copy clicks and the OS clipboard were not tested. Six cookie-free issued-key
Basic GETs before deactivate/delete covered both API roots: owned read200,
wrong-secret401 and foreign
project2515 read404. These are not post-revocation Basic-denial tests.
The read-only verifier closed all 36 source-snapshot files, immutable component
blobs and terminal predicates using only `resourceId := exact generatedKeyId`
in memory. It made no network/auth/SQL calls or new resource writes and did not
repeat live runtime checks. The original
parent remains HOLD because the child recorded `generatedKeyId=1c6998` but
`resourceId=null`; no original receipt was rewritten and no write was replayed.
Local QA workspace evidence, not public assets, under
`.qa-evidence/v511-apikey-native-closure/qa511freshProjectef9ce0d4273c/`:

- `derived-root-verification.json` SHA256:
  `25107f33f9dddb8e3532dff59d3d3eef40d6c7a85963bb0ed7e1c14a7fa5149b`.
- `result.json` (original parent HOLD) SHA256:
  `7519e0708770efab189daf4c18f2d03d9919bef1a20d27be409da1e57247ce2d`.
- `browser/browser.json` (original child receipt) SHA256:
  `b919ae9969bcd2ad9819a422b0fd8ec3c02b4e68ffbdd4b9abfd184fbdef8687`.

Exact native Project and owner/member Host outcomes remain independently
pending; a template, fixture or key scoped result is not Host PASS.
The full permission/resource/locale/layout matrix remains INCOMPLETE.
Historical scoped results and HOLD receipts remain version-bound and immutable;
a later component fix does not promote or replay them.

Quick start now pins the verified public Server511 image. Keep the prior
Server510 immutable image
`ghcr.io/pasturestack/server:v1.6.510@sha256:82e4ee7fa51dae3fb6b1f339ee794d17b593f6feae2fd313ef5354ccaaf2d89f`
and its release records as the nearest release rollback reference. Preserve
the same Compose environment, named volumes and runtime policy.
Publication does not deploy or modify the company site or existing environments.
