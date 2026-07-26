# PastureStack Server v1.6.287

PastureStack Server `v1.6.287` publishes the reviewed Network Diagnostics card
without changing the compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc15` at commit
  `18cc041a293a2760fab23e31cc832be1d2084a27`.
- Exposes 15 reviewed infrastructure templates and one project template.
- Adds `PastureStack Network Diagnostics`, backed by
  `ghcr.io/pasturestack/network-diagnostics-agent:v0.2.0` and
  `ghcr.io/pasturestack/network-diagnostics-service:v0.2.0`.
- Uses a single diagnostics service and one globally scheduled agent per
  active host. The default published service port is `8091`.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain outside the user interface.

The agent collects only bounded aggregate host-network data, uses a
token-derived pseudonymous host identifier, and mounts its three host inputs
read-only. Neither image requests privileged mode, host namespaces,
capabilities, a container-engine socket, or writable host storage.

## Image

```text
ghcr.io/pasturestack/server:v1.6.287
```

## Rollback

Stop the `v1.6.287` container and restore the exact stopped `v1.6.286`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc14` without changing existing application stacks.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
