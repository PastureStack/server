# Server v1.6.502

The release's `published.txt` records the exact Server source and immutable
image digest. Attached startup/restart, MFA/API, TLS, layer and SBOM receipts
establish the publication gates; packaged QA is a separate acceptance result.
Verify the published digest before changing an existing deployment.

## Shared inactive-state display

This patch packages immutable Web Console `1.6.166`, source
`b63fa15f6726cb78659ae43258dfc802b30d6d04`. Its archive SHA-256 is
`9205fbaec6e80f31846212f0949c3eac0fae083f80c6c46a3122d64c4d9da6c6`.
The shared badge gains the omitted `Inactive` display-label branch and thirteen
translations. Exact-source official validation
[36998466706](https://github.com/PastureStack/web-console/actions/runs/36998466706)
passed 768/768 actual tests, zero failures/skips/todo, and two byte-identical
production archives. Eight state/date rendering cases include switching the
actual supported catalogs. The existing artifact is reused, not rebuilt.

Runtime changes are limited to Dockerfile/build-script component pins and
product/release identity metadata. Publication assertions now check the same
502/166 coordinates; focused regression tests reject stale component pins while
retaining historical publication checks. The existing vendor-pending and OpenVEX policy content is
retained with the new release identifier; no threshold or finding is waived. Engine
`v0.183.331` and its exact WAR, authentication/proxies, API/schema, authorization,
state/health semantics, icons/colors, deployment configuration and security
thresholds remain unchanged. Maintainable multi-stage compilation and the
existing exact-rootfs single-runtime-layer gate are retained. No runtime patch,
database migration or production HAProxy/OIDC change is required.

## Deployment and recovery boundary

After immutable publication and successful packaged QA, operators may change
only the Compose image to the new tag plus its verified digest. Preserve
existing environment variables, external named volumes, restart policy,
AppArmor, HTTPS origin, OIDC/MFA, performance settings and nftables mode.
Retain the prior image and normal database/volume backups. A code rollback
uses the previous immutable Server image with the same existing configuration;
do not delete data volumes or run SQL repair statements.

No deployment to `stack.ascdc.tw` is authorized by this release. Component
tests do not establish packaged native-browser acceptance, all-language layout,
all-resource/role matrix acceptance or zero vulnerabilities. Existing
vendor-pending findings and historical HOLD receipts are not promoted or erased.
