# PastureStack Server v1.6.286

PastureStack Server `v1.6.286` publishes the reviewed Amazon EBS and Amazon
EFS storage cards and updates the NFS storage driver without changing the
compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc14` at commit
  `faa122271462c52cc6c6c7a461d9e649e232e9fa`.
- Exposes 14 reviewed infrastructure templates and one project template.
- Adds `PastureStack Amazon EBS Storage`, backed by
  `ghcr.io/pasturestack/ebs-storage-driver:v0.10.0`.
- Adds `PastureStack Amazon EFS Storage`, backed by
  `ghcr.io/pasturestack/efs-storage-driver:v0.10.0`.
- Updates `PastureStack NFS Storage` to
  `ghcr.io/pasturestack/nfs-storage-driver:v0.10.0`.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain outside the user interface.

The AWS storage drivers use existing cloud resources by default. Provisioning
or deleting cloud resources requires an explicit opt-in. EBS requests
encryption for newly provisioned volumes. EFS provisioning additionally
requires operator-supplied subnet and security-group identifiers and never
creates unrestricted NFS ingress. Live AWS lifecycle validation remains a
release-candidate gate.

## Image

```text
ghcr.io/pasturestack/server:v1.6.286
```

## Rollback

Stop the `v1.6.286` container and restore the exact stopped `v1.6.285`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc13` without changing existing application stacks.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
