# PastureStack Server v1.6.312

This release clarifies the host storage workflow by removing a duplicate
state-filter choice. It does not change the Server API, persisted data model,
Catalog coordinates, Docker host support policy, or storage-removal
eligibility rules.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.311`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.312`
- Web Console: `1.6.56-pasturestack.23`
- Web Console source:
  `638343547c53feb95a51af0ce3973ac4fd3f3987`
- Reviewed Web Console artifact SHA-256:
  `19d7a2a332ccb52e168fcc31c9f4fc3fc5377442923b2074bd6cb1275e018478`
- Newest supported Docker Engine remains `29.6.2`.

Operational coordinates use semantic version tags. The artifact hash above is
release-verification evidence and is not used as a container image coordinate
in the Catalog, API, Compose, or Web Console.

## Storage table behavior

- The state filter now contains only All, Active, and Detached. The retired
  selectable-for-removal choice duplicated the Detached view and no longer
  appears in any of the 13 supported locales.
- Checkbox availability remains the source of truth for removal eligibility.
  A row can be selected only when it is detached, has no direct instance
  attachment, has no active mount, has not already been removed, and the API
  advertises a remove action.
- Active or otherwise ineligible rows remain visible with disabled checkboxes.
- Search, natural sorting, current-page selection, and 10, 25, 50, and All page
  sizes remain unchanged.
- Removal still requires an explicit operator selection and confirmation.

## Validation

- Web Console GitHub Actions run `30277987710` passes 231 Chromium/Ember tests,
  Node 24 source gates, 13-locale parity checks, and two byte-identical
  production builds.
- Anonymous GitHub Release download reproduces the reviewed artifact hash.
- The integration build rejects the retired filter key or label, requires all
  three supported state filters, and preserves the existing storage
  eligibility, pagination, localization, Docker, and Catalog gates.
- The release image must pass two identical candidate builds,
  embedded-artifact inspection, isolated startup, controlled restart,
  anonymous pull, and formal upgrade checks before deployment.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
