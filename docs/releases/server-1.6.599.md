# Server v1.6.599 candidate

The Server workflow must qualify the image before publication.

## Verified component inputs

Docker Machine v0.16.8 and the Docker CLI in Agent v1.2.36 use
OpenTelemetry Go 1.47.0 for
[CVE-2026-128085](https://github.com/open-telemetry/opentelemetry-go/security/advisories/GHSA-q7gw-24fr-5p69).
The Docker CLI command and registration interfaces remain compatible.

Web Console 1.6.237 uses the AWS SDK for JavaScript v3 for the EC2 host
driver. The browser continues to use the existing same-origin API proxy.

The affected system images adopt the official Ubuntu 26.04 Brotli package
`1.2.0-3ubuntu0.1` from [USN-8956-1](https://ubuntu.com/security/notices/USN-8956-1).
The pinned [Catalog revision](https://github.com/PastureStack/catalog-templates/commit/6e7b935b6f08e711e1884ef8369cd9dcd110901f)
updates the Healthcheck, IPsec/VXLAN networking, and Resource Scheduler
templates. Existing services retain their selected image until upgraded.
PCRE2 retains the qualified `10.46-1build1+pasturestack.1` backport. The
[Ubuntu revision](https://ubuntu.com/security/notices/USN-8974-1) does not
contain all of the current JIT and callout fixes.

The Server and Agent release workflows use Trivy 0.76.2. They preserve
the raw scan, package-scoped VEX, and mandatory release gates.

Expat's removed runtime library remains absent from the Server. Rsync
stays on the Ubuntu 26.04 package pending Canonical updates for
[CVE-2026-70457](https://ubuntu.com/security/CVE-2026-70457) and
[CVE-2026-119741](https://ubuntu.com/security/CVE-2026-119741).
The existing OpenSSL ABI 3 package remains in use pending vendor updates.
See the [OpenSSL release timeline](https://openssl-library.org/news/timeline/).

See the [upgrade guide](../upgrades/README.md) for volume preservation
and rollback.
