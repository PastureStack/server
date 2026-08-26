# PastureStack Server v1.6.359

Server v1.6.359 updates the embedded API Explorer and replaces the vulnerable
Go 1.26.5 runtime executables inherited from v1.6.358. It does not change the
orchestration engine, Web Console, databases, or control-plane API contract.

## UI dependency update

- API Explorer: `1.1.17`
- API Explorer source: `94e617e0f8950ea80bdb46aaf181f463bae2cea9`
- API Explorer artifact SHA-256:
  `6dc1bfd64f520444efe370bb8141fa3bcc36fa0008617e508375b781ecf30fc3`
- Bootstrap CSS: `5.3.8`
- Bootstrap Icons: `1.13.1`
- Bootstrap JavaScript: not included

This removes the retired Bootstrap 3.4.1 stylesheet and Glyphicons from the
server image. The small first-party modal and dropdown compatibility layer is
retained and covered by the API Explorer security tests.

## Runtime security refresh

The image consumes checksum-pinned Go 1.27.0 releases for Authentication
Service `0.4.36`, Catalog Service `0.20.10`, Compose Executor `0.14.34`, Host
Provisioner `0.39.6`, Secret Delivery API `0.3.1`, Usage Telemetry Agent
`0.4.1`, Webhook Automation Service `0.10.1`, WebSocket Proxy `0.23.13`, and
vSphere CLI Bundle `0.55.1-pasturestack.2`. The in-tree Console Broker is also
rebuilt with the exact Go 1.27.0 builder. Ubuntu 26.04 packages are upgraded to
the newest versions available at image-build time, and their installed
versions are recorded in the final SBOM and Trivy report.

The v1.6.358 base image is digest-pinned. Assembly verifies every replacement
archive and executable digest, the API Explorer release checksum, safe archive
members, required license files, exact source
revision, Bootstrap 5 marker, icon font, and absence of Bootstrap 3 CSS before
replacing `/usr/share/cattle/war/api-ui`.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
