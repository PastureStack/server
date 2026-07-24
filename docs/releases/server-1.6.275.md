# PastureStack Server v1.6.275

PastureStack Server `v1.6.275` is a focused load-balancer compatibility and supply-chain release.

## Changes

- Uses `ghcr.io/pasturestack/load-balancer-service:v0.9.25` pinned to its immutable public digest.
- Accepts the role-specific control-plane credentials when they are available and the generic compatibility credential pair emitted by the preserved digest-pinned orchestration path.
- Uses an Ubuntu 26.04 AppArmor-compatible rsyslog configuration path so logging initialization cannot block HAProxy from applying a load-balancer configuration.
- Builds the load-balancer controller with Go `1.26.5`, which removes the high-severity standard-library finding present in Go `1.26.4`.
- Keeps Node Agent `v1.2.31`, Orchestration Engine `v0.183.269`, Web Console `1.6.56`, API Explorer `1.1.14`, and Catalog commit `91f5910a44cb181051be2adc4c14f0e6ec7842ef`.

The server image is an immutable metadata-only hotfix layer on top of the exact public `v1.6.274` image digest. No upstream history, authorship, license text, or copyright notice is removed.

## Run

```sh
docker run -d \
  --name pasturestack-server \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/pasturestack/server:v1.6.275
```

Existing installations must run `scripts/migrate-approved-runtime-coordinates.sh` during the documented backup-and-upgrade procedure so persisted Agent and load-balancer image settings match this release.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.
