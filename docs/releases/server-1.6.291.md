# PastureStack Server v1.6.291

PastureStack Server `v1.6.291` pins the production-accepted Vault Volume
Catalog release without changing compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc19` at commit
  `4205e1d3b4fec7691c9e5531375f5268c80924da`.
- Uses
  `ghcr.io/pasturestack/vault-secrets-bridge:v0.1.1` and
  `ghcr.io/pasturestack/secrets-flexvolume-plugin:v0.2.0`.
- Mounts the renewable Vault issuing token from an existing read-only platform
  Secret instead of placing it in Compose environment values or a command
  line.
- Runs the bridge as non-root with no Linux capabilities and deploys the global
  driver without privileged mode, host networking, a host PID namespace, or a
  container-engine socket.
- Keeps Catalog, Compose, API, and user-interface image references on semantic
  version tags without image digests.

Production acceptance covered active-host RSA-PSS authentication, policy
allowlisting, nonce replay protection, real Vault response wrapping and unwrap,
read-only `0400` token materialization, driver restart continuity, final
accessor revocation, and exact cleanup.

## Image

```text
ghcr.io/pasturestack/server:v1.6.291
```

## Rollback

Stop the `v1.6.291` container and restore the exact stopped `v1.6.290`
container with the same server data volume. Release active Vault Volume
workloads before rolling back the Catalog definition.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
