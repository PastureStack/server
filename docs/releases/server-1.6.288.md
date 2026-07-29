# PastureStack Server v1.6.288

PastureStack Server `v1.6.288` publishes the reviewed Network Policy Manager
card without changing the compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc16` at commit
  `b3f412fb07af983553ec9c1b61f6db00de3d9742`.
- Exposes 16 reviewed infrastructure templates and one project template.
- Adds `PastureStack Network Policy Manager`, backed by
  `ghcr.io/pasturestack/network-policy-manager:v0.3.1`.
- Schedules one agent per active host with host networking and only
  `NET_ADMIN`; every other capability is dropped.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain outside the user interface.

The agent owns only `table inet pasturestack_policy`, atomically applies
Metadata-defined policy, preserves last-known-good rules during bounded
failures, and removes only that table during a graceful Catalog removal. It
does not request privileged mode, host PID, a container-engine socket, host
filesystem mounts, API credentials, or secret input.

## Image

```text
ghcr.io/pasturestack/server:v1.6.288
```

## Rollback

Stop the `v1.6.288` container and restore the exact stopped `v1.6.287`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc15` without changing existing application stacks. Remove
the Network Policy Manager stack first if the older Catalog should no longer
present or maintain it.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
