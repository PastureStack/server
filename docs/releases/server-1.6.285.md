# PastureStack Server v1.6.285

PastureStack Server `v1.6.285` publishes the reviewed Amazon Route 53 DNS Sync
Catalog card without changing the compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc13` at commit
  `9b5115c068d2e6dbfa1cc8ffebb01eaf0e90f171`.
- Exposes 12 reviewed infrastructure templates and one project template.
- Adds `PastureStack Route 53 DNS Sync`, backed by
  `ghcr.io/pasturestack/external-dns-sync:v0.8.0`.
- Keeps the bounded empty-Catalog bootstrap recovery introduced in
  `v1.6.283`.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain internal evidence only.

The Route 53 service supports EC2 IAM roles or explicitly provided AWS
credentials, limits retry settings, runs as an unprivileged user, and does not
require privileged mode, host networking, a Docker socket, or broad host
filesystem access. An optional platform CA file can be mounted read-only.

## Image

```text
ghcr.io/pasturestack/server:v1.6.285
```

## Rollback

Stop the `v1.6.285` container and restore the exact stopped `v1.6.284`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc12` without changing existing application stacks.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
