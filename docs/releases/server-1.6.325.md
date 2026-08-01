# PastureStack Server v1.6.325

This release retains the complete `v1.6.324` database, authentication,
authorization, Catalog, Web Console, runtime, Orchestration Engine, and host
compatibility behavior while replacing only the embedded API Explorer.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.324`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.325`
- API Explorer: `1.1.15`
- API Explorer source: `1cae0d841981735798bf7b3e5d93ae79cefe8fe5`
- API Explorer artifact SHA-256:
  `3b061a7f4332f330c3fc1c9c85182fd2e0ad2507df069aea857123e6f0d9e334`

Operational image coordinates use semantic version tags. Artifact and image
hashes remain verification evidence and are not written into user-facing image
fields.

## API Explorer executable boundary

Bootstrap 3.4.1 is no longer an npm dependency and Bootstrap JavaScript is not
present in the API Explorer artifact. A small first-party compatibility layer
implements only request modals and filter dropdowns. Native `title` text
provides field help. Server assembly rejects Bootstrap button, tooltip,
popover, modal, dropdown, generic data APIs, and `data-loading-text` from the
built JavaScript.

The inherited layout still uses the exact reviewed Bootstrap 3.4.1 CSS and
font files as static assets. Their provenance, hashes, and license texts are
included. This release does not claim that the remaining CSS framework
lifecycle debt has been eliminated.

The exact API Explorer source passed two byte-identical builds on Windows and
Linux Node.js 24.18, complete npm audits with zero known vulnerabilities, and
browser checks for pointer and keyboard dropdown operation, focus restoration,
modal lifecycle, backdrop cleanup, and font delivery.

## Preserved behavior

The Orchestration Engine remains `0.183.273`, the Web Console remains
`1.6.56-pasturestack.36`, the Authentication Service remains `0.2.5`, and the
vSphere CLI bundle remains `0.55.1-pasturestack.1`. Image assembly compares
their critical executable hashes with `v1.6.324` and verifies that all Web
Console assets, translations, the index, and favicon are byte-identical.

No database schema, state volume, authentication policy, account record,
Catalog template, workload, or node-agent coordinate is changed by this patch.

## Release acceptance requirements

- The Server source gates and API Explorer patch gate must pass.
- Two no-cache image builds must produce the same image identifier.
- The image must contain API Explorer `1.1.15`, all required legal files, no
  source map, and no Bootstrap JavaScript.
- High and Critical image vulnerabilities and secret findings must be zero.
- The isolated candidate must use a copy of the formal data and preserve the
  stable API object counts, account business fingerprint, credentials, port,
  Docker socket, networking, volumes, and restart policy.
- Browser acceptance must cover the API Explorer static assets and first-party
  interaction layer plus the existing Traditional Chinese login and locale
  selector.
- Formal `8080` cutover must retain a stopped rollback container for
  `v1.6.324` and record the exact deployment state.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
