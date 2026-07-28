# PastureStack Server v1.6.304

PastureStack Server `v1.6.304` embeds the reviewed Web Console overflow
correction for adaptive data tables and the environment selector.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.16`, commit
  `9fbeeba81373337adb8c55465cbe45d12ee2e358`.
- Verifies the embedded Web Console artifact against SHA-256
  `63f410b7d5aad4214813fa3a3a6ecf3e0a8503ebab76197666211f6ceed7ff0b`
  before extraction.
- Suppresses horizontal scrollbars when a table exactly fits its available
  content area, including harmless sub-pixel layout rounding.
- Enables horizontal scrolling dynamically when intrinsic or manually resized
  column widths genuinely exceed the available area.
- Keeps semantic initial widths, compact selection and action columns,
  non-wrapping desktop cells, keyboard resizing, and the stacked mobile
  fallback.
- Removes the environment selector's fixed-width click overlay so the menu no
  longer has hidden horizontal overflow.
- Keeps all operational image coordinates on semantic version tags without
  image digests.

The Web Console passed the complete Chromium test suite, all source gates, and
two byte-identical production builds before publication. The packaged artifact
was also checked for unsafe paths, source maps, development locales, and private
workstation markers.

## Image

```text
ghcr.io/pasturestack/server:v1.6.304
```

## Rollback

Stop the `v1.6.304` container and restore the exact `v1.6.303` image with the
same server data volumes.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
