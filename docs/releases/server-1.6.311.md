# PastureStack Server v1.6.311

This release integrates the finalized operator-selected storage workflow and
keeps host storage tables usable when the item count grows. It does not change
the Server API, persisted data model, Catalog coordinates, or Docker host
support policy.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.310`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.311`
- Web Console: `1.6.56-pasturestack.22`
- Web Console source:
  `f325adbebc64bfd2cd428ab23a8c7cbd3808c016`
- Reviewed Web Console artifact SHA-256:
  `c00c48cb99eb0dbcb944992b98620bfd0e99c92a798b200530f7abf20c36363d`
- Newest supported Docker Engine remains `29.6.2`.

Operational coordinates use semantic version tags. The artifact hash above is
release-verification evidence and is not used as a container image coordinate
in the Catalog, API, Compose, or Web Console.

## Storage table behavior

- Page-size choices are 10, 25, 50, and All. Traditional Chinese displays All
  as `全部`.
- The initial page size is 25, and the current-page indicator stays on one
  line.
- The state filter provides all, active, detached, and selectable-for-removal
  views and combines with text search.
- Operators explicitly select items. Select all is limited to eligible rows on
  the current filtered page.
- The zero-selection state is rendered explicitly as `0`; it is never treated
  as an empty translation value.
- Only detached items with no direct instance attachment, no active mount, and
  an advertised API remove action can be selected.
- Active, mounted, attached, removed, and API-unremovable rows show disabled
  checkboxes.
- The confirmation dialog lists only the selected items, warns that removal is
  irreversible, and reports progress plus individual failures.
- Removal uses the public resource API with at most four concurrent requests.
- All 13 selectable locales include the workflow, including Traditional Chinese
  for Taiwan.

## Validation

- Web Console GitHub Actions run `30271390511` passes 231 Chromium/Ember tests,
  Node 24 source gates, localization checks, and two byte-identical production
  builds.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- The Server source contains 47 gates, including selection eligibility, state
  filtering, current-page selection, the 10/25/50/All page-size choices,
  explicit zero rendering, localization, tag-only runtime coordinates, and
  retained Docker/Catalog policies.
- The release image must pass two identical candidate builds,
  embedded-artifact inspection, isolated startup, controlled restart, anonymous
  pull, and formal upgrade checks before deployment.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
