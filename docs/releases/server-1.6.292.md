# PastureStack Server v1.6.292

PastureStack Server `v1.6.292` publishes the reviewed Taiwan Traditional
Chinese Catalog experience without changing compatibility control-plane APIs.

## Runtime change

- Embeds Web Console release `v1.6.56-pasturestack.6`, built from commit
  `13cb100f31e8b23cefd9b5a27d2fb0fb9afac3c6`.
- Pins Catalog Templates release `v0.3.0-rc20` at commit
  `1015b95f04424b9f8044304e4dadf331fa25d8cc`.
- Selects localized Catalog documentation and installation-question labels
  when the active interface language is Taiwan Traditional Chinese.
- Retains English content as the fallback for templates that do not yet
  provide localized content.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Validation covers all 198 browser tests, both localization completeness gates,
the Catalog image-coordinate audit, the Catalog Service integration suite, the
production Server image, and the live Catalog page.

## Image

```text
ghcr.io/pasturestack/server:v1.6.292
```

## Rollback

Stop the `v1.6.292` container and restore the exact stopped `v1.6.291`
container with the same server data volume. Restore the Catalog pin to
`1015b95f04424b9f8044304e4dadf331fa25d8cc` only when retaining the new
localized template revision; otherwise restore the `v1.6.291` Catalog pin.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
