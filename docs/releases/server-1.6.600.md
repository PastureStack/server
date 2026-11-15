# Server v1.6.600 candidate

The Server workflow must qualify the image before publication.

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
