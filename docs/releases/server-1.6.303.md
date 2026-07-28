# PastureStack Server v1.6.303

PastureStack Server `v1.6.303` embeds the reviewed Web Console table-layout
and navigation-overflow corrections.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.15`, commit
  `bd90dbc664c39190dc3b91b48671ac82d85afb59`.
- Verifies the embedded Web Console artifact against SHA-256
  `eda95611b29fc314d9bf30d1606ca1818ca18b7183b8d3705aef12767d029028`
  before extraction.
- Assigns semantic initial widths to selection, action, state, address, host,
  port, date, name, image, command, and identifier columns.
- Fixes bulk-selection columns at `48px` instead of allowing long adjacent
  content to expand them.
- Distributes spare width only to useful data columns while retaining manual,
  keyboard, and double-click column resizing.
- Keeps the final resize handle inside the table boundary so a fitting table
  does not create a meaningless horizontal scrollbar.
- Prevents navigation dropdowns from creating horizontal scrollbars while
  retaining vertical scrolling for long menus.
- Keeps horizontal scrolling only when the table's meaningful minimum widths
  genuinely exceed the available viewport.
- Keeps all operational image coordinates on semantic version tags without
  image digests.

The Web Console passed 217 Chromium tests, complete message-key parity across
all 13 selectable locales, and two byte-identical production builds before
publication.

## Image

```text
ghcr.io/pasturestack/server:v1.6.303
```

## Rollback

Stop the `v1.6.303` container and restore the exact stopped `v1.6.302`
container with the same server data volumes.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
