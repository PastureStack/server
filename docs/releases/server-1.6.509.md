# Server v1.6.509

Candidate only; no image digest has been published or accepted yet.

## Scope

This patch packages Orchestration Engine `v0.183.333`. A shared response wrapper
previously treated every POST as creation. Consequently a POST lifecycle action
could expose a create-only field again. Creation is now classified by the actual
request dispatcher: POST with no action. All three wrapper construction paths
use that same predicate; method-only legacy constructors fail closed.

The first API Key create response still delivers the generated material. Later
GET, PUT, DELETE and POST action responses redact only fields already marked
create-only by their authoritative schema. No ordinary readable field is
redacted merely because its name contains "secret". Frozen v1 schemas remain
byte-for-byte unchanged. A non-null later secretValue was observed; this does
not establish plaintext disclosure, since the stored credential is a verifier.

Web Console remains `1.6.171`. Role authorization, databases, authentication,
OIDC/TOTP/Passkey, node agents, Catalog, firewall backends and deployment settings
are unchanged. No migration or runtime patch is required.

## Verification status

- Local targeted Engine tests: 19 passed, including 14 new regression cases.
- Fresh independent production-path review: no concrete bypass or regression.
- Engine security CI `37104364692` and CodeQL `37104364689`: passed at exact
  source `0d94f7d879d314235e582a7f4062914a27b82709`; 273 suites / 1,164 tests,
  zero errors, failures or skips; all 62 required named cases verified.
- Engine `v0.183.333`: signed immutable tag, six CI-derived assets, portable
  SHA256 and three anonymous content readbacks passed. WAR SHA256:
  `8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
  Exact WAR isolated JDK25/H2 startup exited 0 without platform data or network.
  Four existing CodeQL Medium findings remain; this is not a zero-risk claim.
- Local Server current-packaging contract: 8 tests passed.
- Server source/build/start/restart/image security/publication: pending.
- QA 8080 account/project API Key lifecycle and fresh isolated Host: pending.
- Full permission, individual-resource-ID, locale and layout matrix: incomplete.

Historical HOLD and PASS evidence is immutable and is not promoted to this
candidate. These notes will be reconciled with actual source, test totals,
component hashes, immutable image digest and QA results before handoff.

## Upgrade and rollback

Do not deploy this candidate before its immutable image is released and verified.
After publication, change only the image reference in the existing Compose file;
retain environment variables, named volumes, restart policy, AppArmor, HTTPS
origin, OIDC and performance settings. Keep the existing image and recovery
backup for rollback. This work does not deploy or modify the production site.
