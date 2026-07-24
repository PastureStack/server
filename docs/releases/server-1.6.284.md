# PastureStack Server v1.6.284

PastureStack Server `v1.6.284` publishes the reviewed Amazon ECR Credential
Sync Catalog card without changing the compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc12` at commit
  `1a24b6759f02b800a0a8ad149bb4d4d8afb58722`.
- Exposes 11 reviewed infrastructure templates and one project template.
- Adds `PastureStack Amazon ECR Credential Sync`, backed by
  `ghcr.io/pasturestack/ecr-credential-sync:v3.1.0`.
- Keeps the bounded empty-Catalog bootstrap recovery introduced in
  `v1.6.283`.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain internal evidence only.

The ECR service supports the current environment or an explicitly scoped
compatible environment. Its image runs as an unprivileged user and does not
require privileged mode, host networking, a Docker socket, or host filesystem
access beyond an optional read-only shared AWS profile directory.

## Image

```text
ghcr.io/pasturestack/server:v1.6.284
```

## Rollback

Stop the `v1.6.284` container and restore the exact stopped `v1.6.283`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc11` without changing existing application stacks.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
