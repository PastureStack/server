# PastureStack Server v1.6.297

PastureStack Server `v1.6.297` makes the Catalog card presentation concise
while retaining explicit project branding and historical provenance.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.10`, built from commit
  `840da39d9d6f3ca35a56c7574ebcb49783d7c3e6`.
- Displays `PastureStack` once in the first-party card badge; the software name
  does not repeat the brand prefix.
- Keeps the detailed upstream first-party origin statement localized and
  separate from the current PastureStack maintenance identity.
- Pins Catalog Templates at commit
  `a44fbf3649165347a4b780159bf5daa92812a53a`.
- Removes the repeated brand prefix from every English and Taiwan Traditional
  Chinese Catalog card name while preserving descriptive software names.
- Keeps the Catalog limited to 22 reviewed infrastructure entries selected
  from the preserved upstream first-party catalog plus the native project
  template; general third-party application templates remain excluded.
- Retains all 171 localized configuration questions and the complete 13-locale
  Web Console message contract.
- Uses `相關容器` for the Taiwan Traditional Chinese Sidekicks label.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Validation covers the immutable Catalog source, all enabled templates, card-name
invariants, localized names, image coordinates, the complete Web Console test
suite, two reproducible Web Console builds, the production Server image, and
live VM browser checks.

## Image

```text
ghcr.io/pasturestack/server:v1.6.297
```

## Rollback

Stop the `v1.6.297` container and restore the exact stopped `v1.6.296`
container with the same server data volumes. Retain both the prior image and
stopped container until live acceptance is complete.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes. Historical
upstream status is recorded as provenance and is not a claim of current vendor
certification, endorsement, or support.
