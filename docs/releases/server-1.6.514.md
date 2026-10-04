# Server v1.6.514

Candidate; not yet published or deployed. No complete functional-matrix PASS is claimed.

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
- Server image tag/digest, official runtime/security readback and real catalog migration
  results are pending. Component tests are not native UI or permission-matrix acceptance.

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
four CVEs remain the existing exact policy). The Server514 runtime scan is still pending.
This release does not claim zero CVEs or authorize changes to a company deployment.
