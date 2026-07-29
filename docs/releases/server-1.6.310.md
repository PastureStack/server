# PastureStack Server v1.6.310

This release integrates operator-selected storage bulk removal and paginated
host storage tables without changing the Server API, persisted data model,
Catalog coordinates, or Docker host support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.309`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.310`
- Web Console: `1.6.56-pasturestack.21`
- Web Console source:
  `b6df4b4f410819025da21049b87e76c2159fd83f`
- Reviewed Web Console artifact SHA-256:
  `765a531eb8e9a68a6f861f34509d7060a8e05fe036bccb75366d06678fa627bd`
- Newest supported Docker Engine remains `29.6.2`.

Operational coordinates use semantic version tags. The artifact hash above is
release-verification evidence and is not used as a container image coordinate
in the Catalog, API, Compose, or Web Console.

## Storage table behavior

- Operators explicitly select the storage items to remove. Item names never
  imply removal intent.
- Only detached items with no direct instance attachment, no active mount, and
  an advertised API remove action can be selected.
- Active, mounted, attached, removed, and API-unremovable rows show disabled
  checkboxes.
- Filters for all, active, detached, and removable items combine with text
  search.
- Page sizes are 10, 25, 50, and All. Select all is limited to selectable rows
  on the current filtered page.
- The confirmation dialog lists only the selected items, warns that removal is
  irreversible, and reports progress plus individual failures.
- Removal uses the public resource API with at most four concurrent requests.
- All 13 selectable locales include the workflow, including Traditional Chinese
  for Taiwan.

## Validation

- Web Console GitHub Actions run `30269441605` passes 231 Chromium/Ember tests,
  Node 24 source gates, localization checks, and two byte-identical production
  builds.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- The Server source contains 47 passing gates, including checks for selection
  eligibility, state filtering, current-page selection, the All page-size
  option, localization, tag-only runtime coordinates, and retained
  Docker/Catalog policies.
- The release image must pass two identical candidate builds,
  embedded-artifact inspection, isolated startup, controlled restart, anonymous
  pull, and formal upgrade checks before deployment.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
