# PastureStack Server v1.6.309

This release integrates guarded bulk cleanup for explicit test storage debris
without changing the Server API, persisted data model, Catalog coordinates, or
Docker host support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.308`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.309`
- Web Console: `1.6.56-pasturestack.20`
- Web Console source:
  `78bbd9a497b93db71bf7cf0425c2f98b6f3df5dd`
- Reviewed Web Console artifact SHA-256:
  `e08c054ad151fa4a2b6a48e32861a9a9fd20535483d8db08753d066802641c47`
- Newest supported Docker Engine remains `29.6.2`.

Operational coordinates use semantic version tags. The artifact hash above is
release-verification evidence and is not used as a container image coordinate
in the Catalog, API, Compose, or Web Console.

## Storage cleanup behavior

- The host storage page provides one guarded bulk cleanup action.
- Eligibility requires the detached state, no direct instance attachment, no
  active mount, an advertised API remove action, and an explicit delimited test
  marker in the item name.
- Names marked for backup, restore, rollback, production, or current use remain
  protected.
- Ambiguous detached items remain protected instead of being guessed safe.
- The confirmation dialog shows candidate names and the number of excluded
  detached items before removal starts.
- Removal uses the public resource API with at most four concurrent requests
  and reports progress plus per-item failures.
- All 13 selectable locales include the workflow, including Traditional Chinese
  for Taiwan.

## Validation

- The Web Console validation workflow passes Node 24 source gates, all Chromium
  tests, localization checks, and two byte-identical production builds.
- The Server source contains 47 passing gates, including explicit checks for the
  cleanup workflow, translations, base-image continuity, tag-only runtime
  coordinates, and retained Docker/Catalog policies.
- The release image must pass a clean build, embedded-artifact inspection,
  startup, restart, anonymous pull, and formal upgrade checks before deployment.
