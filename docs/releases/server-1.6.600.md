# Server v1.6.600

Published image: `ghcr.io/pasturestack/server:v1.6.600@sha256:6ecd5535eeb9bb1eb9cf83ee36c2511243f1af120ab5aa96388ae19666f144a8`.

Source commit: `afe29fa15f1501cf0e2f2858c7160005366b98da`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

Web Console 1.6.238 resolves Amazon EC2's AWS SDK v3 from a lazy browser
asset when the EC2 wizard signs in. The existing same-origin API proxy
and the previous Cloud driver configuration still apply.

The restart, host enrollment, and existing stack upgrade contracts remain
those of Server v1.6.599. This candidate retains the OpenTelemetry Go 1.47.0
component pins, official Ubuntu Brotli and qualified PCRE2 inputs, and
Trivy 0.76.2 publication checks from v1.6.599.

See the [upgrade guide](../upgrades/README.md) for volume preservation
and rollback.
