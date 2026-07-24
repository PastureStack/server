# PastureStack Server v1.6.295

PastureStack Server `v1.6.295` completes provenance and localization for the
reviewed upstream first-party Catalog subset.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.8`, built from commit
  `864a73e73b77ef0c060d1b9bbed872478d379538`.
- Pins Catalog Templates at commit
  `8806a61a58c41edbaab22b440b5e2fdbbd16d0b7`.
- Keeps the Catalog limited to 22 reviewed infrastructure entries selected
  from the preserved upstream first-party catalog plus the native project
  template; general third-party application templates remain excluded.
- Marks every infrastructure card as an upstream first-party template and
  separates historical origin from current PastureStack community maintenance.
- Provides Taiwan Traditional Chinese detail content for all 22 entries and
  localized labels and descriptions for all 171 configuration questions.
- Publishes each localized entry under a new immutable Catalog version so an
  existing installation cannot reuse stale English detail content cached under
  an earlier version identifier.
- Preserves the complete 13-locale Web Console message contract.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Validation covers the immutable Catalog source, all enabled templates, image
coordinates, provenance labels, localized README selection, localized
configuration questions, the complete Web Console test suite, two reproducible
Web Console builds, the production Server image, and live VM browser checks.

## Image

```text
ghcr.io/pasturestack/server:v1.6.295
```

## Rollback

Stop the `v1.6.295` container and restore the exact stopped `v1.6.293`
container with the same server data volume. Retain both the prior image and
stopped container until live acceptance is complete.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes. Historical
upstream status is recorded as provenance and is not a claim of current vendor
certification, endorsement, or support.
