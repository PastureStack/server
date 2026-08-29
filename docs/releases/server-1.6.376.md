# PastureStack Server v1.6.376

Server v1.6.376 embeds Web Console `1.6.79` and restores the authenticated
application layout to the visual contract shipped by Server `v1.6.358`.
Server `v1.6.358` is a visual reference only: current application code,
dependencies, security fixes, MFA, audit-log filtering, and Bootstrap 5.3.8
JavaScript remain in place.

## Operator-visible result

- The authenticated header, navigation, page shell, cards, forms, and footer
  again follow the established PastureStack proportions and typography.
- Stack, host, container, Catalog, add-stack, account, and audit-log routes use
  the restored shared layout without changing their current functionality.
- The audit-log filter builder remains available, including time range,
  environment, user, action, resource, response status, and text operators.
  Its existing result table is unchanged.
- Login, language selection, dropdowns, collapse state, MFA/security icons, and
  loading overlays retain the current fixes and runtime behavior.

## Bound release inputs

- Web Console: `1.6.79`
- Web Console source: `43f1f1f30025f65db8acfa0d0a2b527da148ecd8`
- Web Console archive SHA-256: `ff2ff9d9e48a699ccf7bec003886880c062a916ace2492006372ce35de29f19d`
- Web Console validation run: `33240286671`
- Web Console release: <https://github.com/PastureStack/web-console/releases/tag/1.6.79>
- Docker Engine support: `>=v29.4.1 <=v29.7.2`, including `v29.6.2`

The Server build retains the reviewed GNU coreutils fix commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`, OpenSSL `3.5.8`, zlib `1.3.2`,
Go `1.27.0`, the existing OpenVEX closure, and all current runtime hardening.

The publish workflow verifies the exact Web Console artifact, runs source and
image gates, start/restart smoke tests, merged-rootfs vulnerability and secret
scans, SBOM and provenance generation, public-image readback, and immutable
release creation before the image is eligible for production deployment.
