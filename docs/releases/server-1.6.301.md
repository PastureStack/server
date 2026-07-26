# PastureStack Server v1.6.301

PastureStack Server `v1.6.301` embeds a corrected Web Console artifact for the
persistent browser console workspace.

## Runtime changes

- Embeds Web Console release `v1.6.56-pasturestack.13`, commit
  `6ab945d4b4c78d73d6412f47dd28dd10fa4f55ce`.
- Verifies the embedded Web Console artifact against SHA-256
  `fbdeb285bed9e38e6ddfce0f4561d3bc7107de0b70934144b51eef249d69fd0d`.
- Retains the browser-tab client identity across a reload so terminal replay
  and controller ownership do not briefly attach as a second client.
- Detects a copied browser-tab identity before attachment and rotates it,
  keeping cross-tab controller handoff explicit.
- Retains movable, resizable, minimizable, maximizable, persistent, and
  cross-tab terminal and log windows.
- Retains one input controller per terminal with explicit handoff and output
  replay after refresh, tab closure, or reconnection.
- Removes one or more repeated `PastureStack` name prefixes from Catalog card
  titles; the independent brand badge remains the single card-level brand
  marker.
- Keeps all operational image coordinates on semantic version tags without
  image digests.

The Web Console passed 213 Chromium tests and two byte-identical production
builds under Node.js 24 before publication. Its GitHub Release and asset
attestations were also verified before this Server image was built.

## Image

```text
ghcr.io/pasturestack/server:v1.6.301
```

## Rollback

Stop the `v1.6.301` container and restore the exact stopped `v1.6.300`
container with the same server data volumes. Retain the stopped `v1.6.299`
container as the preceding rollback layer until live acceptance is complete.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, licenses, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
