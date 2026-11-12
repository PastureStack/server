# Server v1.6.598 candidate

## Verified component inputs

The Server runtime installs Ubuntu 26.04 Perl packages at `5.40.1-7ubuntu0.4`
from checksum-pinned Ubuntu security packages to address
[CVE-2026-82560](https://ubuntu.com/security/CVE-2026-82560).
The build also includes the CA package update from
[USN-9001-1](https://ubuntu.com/security/notices/USN-9001-1).
The console broker is built with Go 1.27.4.

New load balancers use `ghcr.io/pasturestack/load-balancer-service:v0.9.34`
with HAProxy 3.4.7, AWS-LC 5.14.0 and Lua 5.4. Existing services retain
their selected image until upgraded. The system healthcheck image is
selected through the infrastructure Catalog.

Web Console 1.6.236 and Engine v0.183.395 remain the bundled application versions.
