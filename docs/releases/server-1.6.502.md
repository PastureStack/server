# Server v1.6.502

The release's `published.txt` records the exact Server source and immutable
image digest. Attached startup/restart, MFA/API, TLS, layer and SBOM receipts
establish the publication gates; packaged QA is a separate acceptance result.
Verify the published digest before changing an existing deployment.

## Immutable publication

Official publisher
[37003831065](https://github.com/PastureStack/server/actions/runs/37003831065)
completed successfully for source `d89d585a3901b044039a685edd6140835bccb08c`.
The immutable linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.502@sha256:ee6d0141574280473cb27a638814ae924b3d5bfe344f1ee0e1741aae0f3efddb`.
Anonymous registry manifest/config and all 23 public release assets were read
back; the 22 checksummed attachments match `SHA256SUMS`. Startup/restart returned
HTTP 200/pong, 34 MFA/API checks passed, and TLS 1.2/1.3 and private-API no-store
checks passed. The final image retains one runtime layer and multi-stage builds.
Eight Medium package findings covering four CVEs remain vendor-pending, with
review due 2026-10-20. No Critical/High, available-fix, untracked or secret
finding was accepted; these results are not a zero-CVE claim.

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

The QA upgrade from immutable 501 and one restart both returned HTTP 200/pong.
Runtime configuration and the five guarded database table counts matched before,
after first start and after restart; named mounts, environment overrides,
AppArmor and restart policy were preserved. The stopped 501 container and
database backup remain available for rollback. Packaged native-browser acceptance
and the full permission/resource/locale matrix are still separate, incomplete gates.

No deployment to `stack.ascdc.tw` is authorized by this release. Component
tests do not establish packaged native-browser acceptance, all-language layout,
all-resource/role matrix acceptance or zero vulnerabilities. Existing
vendor-pending findings and historical HOLD receipts are not promoted or erased.
