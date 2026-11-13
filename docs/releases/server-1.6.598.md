# Server v1.6.598 candidate

## Verified component inputs

The Server runtime installs Ubuntu 26.04 Perl packages at `5.40.1-7ubuntu0.4`
from checksum-pinned Ubuntu security packages to address
[CVE-2026-82560](https://ubuntu.com/security/CVE-2026-82560).
The build also includes the CA package update from
[USN-9001-1](https://ubuntu.com/security/notices/USN-9001-1).
The Server runtime uses official Ubuntu glibc `2.43-2ubuntu2.7`. The
build verifies each archive's SHA-256, package metadata and installed files.
[Ubuntu USN-9065-1](https://ubuntu.com/security/notices/USN-9065-1)

The console broker and 16 packaged binaries use Go 1.27.4.
[Go GO-2026-6859](https://pkg.go.dev/vuln/GO-2026-6859)

| Component | Version |
| --- | --- |
| Authentication Service | v0.4.47 |
| Catalog Service | v0.20.18 |
| Compose Executor | v0.14.46 |
| Machine Driver Bundle | v0.16.7 |
| vSphere CLI Bundle | v0.55.5 |
| Host Provisioner | v0.39.11 |
| Secret Delivery API | v0.3.5 |
| Usage Telemetry Agent | v0.4.5 |
| Webhook Automation Service | v0.10.6 |
| WebSocket Proxy | v0.23.19 |
| Host API | v0.38.10 |
| Node Agent | v0.13.36 |
| Per-Host Subnet Windows CNI | v0.2.6 |

New load balancers use `ghcr.io/pasturestack/load-balancer-service:v0.9.34`
with HAProxy 3.4.7, AWS-LC 5.14.0 and Lua 5.4. Existing services retain
their selected image until upgraded. The bundled Catalog selects
Metadata Healthcheck `v0.3.21` with Ubuntu glibc `2.43-2ubuntu2.7` and
HAProxy `3.2.25-0ubuntu0.26.04.2`. Catalog revisions 4 and 5 remain available for rollback.
Network Services revision 16 and Network Policy Manager revision 6 carry
updated Ubuntu inputs, as do Secret Volume revision 5 and Vault Volume revision 6.

Web Console 1.6.236 and Engine v0.183.395 remain the bundled application versions.
