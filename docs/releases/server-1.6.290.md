# PastureStack Server v1.6.290

PastureStack Server `v1.6.290` pins the production-accepted Secret Volume
Catalog release without changing compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc18` at commit
  `bb38a5dacb1235e0aec88083aeaa0553a94710f7`.
- Uses
  `ghcr.io/pasturestack/secrets-flexvolume-plugin:v0.1.1`.
- Restores the compatibility agent role required for authorized encrypted
  secret retrieval.
- Grants only `SYS_ADMIN`, `CHOWN`, and `FOWNER` after dropping all Linux
  capabilities. The driver remains non-privileged and does not use host
  networking, a host PID namespace, or a container-engine socket.
- Uses the narrowly scoped AppArmor exception required for the isolated
  `tmpfs` mount while retaining a read-only root filesystem and
  `no-new-privileges`.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Production acceptance covered authenticated encrypted retrieval, non-root
materialization with mode `0400`, content verification, write rejection,
workload restart continuity, driver stability, and complete workload, secret,
volume, and mount cleanup.

## Image

```text
ghcr.io/pasturestack/server:v1.6.290
```

## Rollback

Stop the `v1.6.290` container and restore the exact stopped `v1.6.289`
container with the same server data volume. Release all active Secret Volume
workloads before rolling back the driver Catalog definition.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
