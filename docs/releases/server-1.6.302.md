# PastureStack Server v1.6.302

PastureStack Server `v1.6.302` embeds the reviewed Web Console workspace
layout, session-identification, and log-stream corrections.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.14`, commit
  `35d9d298353becce389c5d8bc9dd07c2545ee7fa`.
- Verifies the embedded Web Console artifact against SHA-256
  `7c870a323823de33e2226214e591a698b0df039122dada44b0b305da4c06dabe`.
- Pins Catalog Templates release `v0.3.0-rc22`, commit
  `c3a8e9876a74dbf98ce16ae504b947c5d80582c1`, so Metadata Healthcheck
  installs from the semantic image tag `v0.3.16`.
- Builds and tests the Console Broker with Go `1.26.5`.
- Keeps terminal and log status bars in the flex layout so they no longer
  cover content or the final rows of vertical and horizontal scrollbars.
- Adds themed log scrollbars and a localized line-wrapping preference.
  Unwrapped logs retain a horizontal scrollbar.
- Lets dock icons and the session-count badge magnify above the dock without
  being clipped while retaining horizontal scrolling for larger session sets.
- Identifies each window by environment, stack, and container, and repeats
  that context in the session-list subtitle.
- Replaces the ambiguous stop glyph with a power symbol beside Close and
  requires a localized Yes/No confirmation before a running command is ended.
- Keeps all operational image coordinates on semantic version tags without
  image digests.

The Web Console passed 215 Chromium tests, complete message-key parity across
all 13 selectable locales, and two byte-identical production builds before
publication.

## Image

```text
ghcr.io/pasturestack/server:v1.6.302
```

## Rollback

Stop the `v1.6.302` container and restore the exact stopped `v1.6.301`
container with the same server data volumes.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
