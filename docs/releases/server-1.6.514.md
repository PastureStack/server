# Server v1.6.514

Published immutable Server artifact; QA deployment/readback and the scoped catalog
migration have passed. Native UI acceptance remains separate and in progress.
No complete functional-matrix PASS is claimed.

## Repair

Catalog Service `0.20.12` excludes root Git metadata from catalog traversal and validates
numeric/semantic revision directories before reading files or allocating templates.
This prevents empty `.git` entries from appearing as application templates.
Metadata-only README/icon entries are omitted unless a valid template definition exists.
Root template READMEs are distinguished from version READMEs by their directory, rather
than incorrectly treating `README.md` as a revision directory.

An unchanged source commit no longer bypasses an empty or unnamed cached index. The existing
transaction rebuilds only the selected catalog (name plus environment), preserving normal
template configuration, revision/version metadata, compose bytes and labels.

Web Console `1.6.176` repairs the 21 native-select bindings that passed a `mut` value
through the legacy action helper rather than invoking its setter after the Ember upgrade.
Project member-role edits must update the model and persist through save/readback.
Equivalent balancer, machine, schema and setting fields use the same invokable binding;
the helper itself, capabilities, identity metadata and session protection are unchanged.

## Components and verification

- Catalog Service `0.20.12`, source `d708579092eae0fd03b2750ac594ff0396cf563b`:
  [main CI37177694304](https://github.com/PastureStack/catalog-service/actions/runs/37177694304)
  passed 39 integration cases twice, Go race/vet/fmt and reproducible archive checks.
  Archive SHA256 `34b76c121270c603501664f7146d41916c7f45da983e326861ed4c5b9614372d`;
  binary SHA256 `3deb43f9760d7cbb07f818dd108ab35abf9efc6908d5d7fcaf5c44a185f2fba9`;
  SQLite binary SHA256 `8805af3c0b5968a02f994d65de715c525b73637aa2dc398a0648feeeaf2fd397`;
  source LICENSE SHA256 `0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594`.
  [Publication37178033799](https://github.com/PastureStack/catalog-service/actions/runs/37178033799)
  succeeded; anonymous public readback verified two asset bytes, immutable coordinates,
  both binaries and the source LICENSE against main CI. Publication receipt SHA256:
  `552ba8ab75e5379e462a44b03dc94d21b32e75476bd768db3d11cfee25d666de`.
  Catalog Service is published; this is not Server514 publication or QA acceptance.
- Web Console `1.6.176`: immutable release, signed source
  `a1bbf172aad8443bfbb1859760d62669d6705189`, archive SHA256
  `071ce0b7091b323e0d84fe91269684f59fcf2e29000bd8ff94428e8dd03ece52`.
  Formal CI `37175725533`: 824/824, zero fail/skip/todo; two archives are byte-identical.
  Three native-render regressions and the preceding 29 targeted regressions passed.
  The previously published Web175 image-error and session fixes are retained.
- Engine `v0.183.333`, source `0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
  `8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328` (unchanged).
- Reuse the pinned Server460 base and four build stages; the official publisher retains
  the single-runtime-layer/config comparison. No runtime patch is used.
- [Official publisher37179046649](https://github.com/PastureStack/server/actions/runs/37179046649)
  and independent public readback verified this Server artifact, not QA deployment.
  Source: `076aa43c6b978dfe65cd0fb3a05efc97ec5d02dd`.
  Image: `ghcr.io/pasturestack/server:v1.6.514@sha256:45712644bc11325df927d10bdbab47421168cc3c512eb5f2a51d85020671a71f`.
  Artifact config digest: `sha256:e34715538f3e1b3effd555f3a308a162074092d1a4764badb1bae383d2339838` (distinct from the manifest digest).
  Actual runtime/security/publication results are in the independent receipt SHA256
  `59340dd9c4b365df3e08633d71be66b56640e7d9cc673a79670c78c7739b2d70`, local evidence
  `.release-evidence/server-v514-published-readonly/readback/server514-release-37179046649/readback-receipt.json`; no run counts are borrowed from Server513.
- QA125/8080 runs514/Web176 after actual immutable deployment and independent readback.
  First-start11/restart9 probes returned HTTP200/pong; runtime contract and five core-table
  count differences were0. Existing environment variables, named volumes and AppArmor were
  preserved;512 remains stopped as a rollback container. No Docker Healthcheck is defined.
  Deployment receipt SHA256: `3195d1d1e2cf1985bfc1caab0b18cdc81bb65564829764c585d17174250fe1c8`.
- Two real post-deployment SELECT snapshots agreed. The catalog migration removed12 blank
  Git stubs and2 source-proven README-only entries, preserving valid origin, template keys,
  versions, compose contents and labels across the eight tables. No SQL writes or manual
  runtime repair were used. Migration summary SHA256:
  `e979b384a70826b3a8ea44ee60c0166aff665520cab25a78cded6ae49a0cd8c7`.
  This accepts the scoped index migration only, not native create/upgrade/delete.
- QA125/8080 native form checks passed for Traditional Chinese and English:
  eight VM/container fresh/cache cases, two INIT toggle/restore cases and three
  data-preservation checks. Required-image errors were visible, and the INIT
  checkbox did not overlap the adjacent input. No resource was created and no
  guest VM was started. This is not all-locale, GPU or VM-runtime acceptance.
  Actual result SHA256: `786b08d0205ba48272b67cad5494e5e9728368a019faa0bc2ebf3cd2d2a63f16`.
- Native UI, resource/role/locale/layout and VM runtime remain scoped or OPEN;
  full matrix INCOMPLETE. Artifact and migration tests do not establish full UI or permission acceptance.

## Current isolated native acceptance scopes

These are separate QA scopes on Server514/Web176/Engine333/Catalog Service 0.20.12,
not production-site acceptance or promotion of earlier HOLDs. Local QA workspace
evidence is not a public release asset; receipt hashes identify the observed results.

| Scope | Actual current result | Evidence / remaining work |
| --- | --- | --- |
| Existing Network fixture service edit and cleanup | Scoped PASS: 4 native writes/6 full guards; cleanup verified | Result SHA256 `f6d0070c20795fdeab0c795fdf0d7b04404a4543b25c52d4b64492ce091d887e`; does not accept an untested networking implementation |
| Container role-specific denials | Readonly child: 6 expected denials/9 guards observed; target-environment no-access: independent scoped PASS with 6 expected denials/9 guards and 0 allowed resource writes | No-access result SHA256 `179e99a39a96adb22c66c88eccc3cb9f0c89a212e27c7de8cee7eb367001e733`. The earlier readonly parent remains HOLD; the role runs are separate, and denial checks do not establish access to protected resource contents |
| Owner container lifecycle | INCOMPLETE: the original start/stop run remains HOLD. Separate runs verified start/restart 202 and actual log output/termination (2 writes/4 guards), start 202 and actual terminal output/termination (1 write/3 guards), then native DELETE 200 with the confirmation modal closed and source finalizer completed (1 write/1 entry guard). Independent read-only cleanup found all seven owned rows terminal: six purged and one removed, count 7 | Delete result SHA256 `41611ab1f2d62c36cb76150bac2a015db24fe642e3e5c32ff8ea4697e5e88e54`; cleanup-only result `690e3bcf1410009c8c3d03883e5850181dace29af21eedf6c14e71026edf5aa8`. No removed-phase guard or final browser receipt is claimed. Eight foreign raw-row differences, three historical FK gaps, unproved owned unknown fields and no fresh API14 readback prevent full-guard acceptance. Historical HOLDs remain unchanged; completed writes/streams are not replayed |
| Existing Catalog B-upgrade remainder | Scoped non-original PASS: 4 resource writes/5 transports/7 full guards; B upgrade 202, finish 202, reload and owned cleanup verified | Result SHA256 `e113ef1b6c1ce2941b9843a8014e55dee31b8a000ee48750c7d5dfdeecfed716`; historical create/A/activation HOLDs are not retroactively PASS |
| Existing Project native lifecycle and independent owned DB cleanup | Native deactivate/activate/remove finalizers and list reloads observed in separate stages; both original runs remain HOLD, each with 2 validated writes/5 guards. Independent owned DB terminal cleanup confirmed with 0 auth/0 writes/0 current guards | Cleanup-only result SHA256 `a5ff35f857ae2cdad7cd75bb77c26082ed61993978d17388b7432e280482a53c`; this is not full-guard or complete historical-preservation acceptance: 8 missing historical foreign rows and 4 default-network non-lifecycle protection gaps remain |

The complete matrix remains INCOMPLETE. These results do not accept VM boot,
hardware, every locale or the production site. Historical records and release
coordinates are unchanged.

## Upgrade and rollback

Back up the existing persistent data before replacing only the image reference with the
published immutable `v1.6.514` reference. Preserve environment variables, named volumes,
restart policy, AppArmor, HTTPS origin, OIDC/MFA and the selected firewall backend.

Startup refresh may replace database surrogate rows in affected catalog indexes, even with
the same Git source commit. Catalog database IDs, including API template IDs, may remap
within the transaction. Preserve and verify catalog origin, template keys, versions,
content and labels independently of surrogate IDs.
Verify normal templates, exact versions/files/labels and native create/upgrade/remove
after startup; do not manually delete unknown rows or clear all catalogs to pass a test.
Keep the previous image and pre-upgrade data backup. Rebuilt indexes remain valid for
the prior reader; if a data regression is detected, restore the verified backup during
controlled downtime. Never delete named volumes as an upgrade or cleanup step.

Unfixed vendor Medium/Low findings remain recorded under the existing policy and review
deadline `2026-10-20` (51 VEX statements and eight vendor Medium package findings across
four CVEs remain the existing exact policy). This policy is not the actual Server514 scan:
its recorded findings and gate results come only from the independent receipt above.
This release does not claim zero CVEs or authorize changes to a company deployment.
