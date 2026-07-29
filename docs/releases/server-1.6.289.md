# PastureStack Server v1.6.289

PastureStack Server `v1.6.289` publishes the reviewed Secret Volume card
without changing the compatibility control-plane APIs.

## Runtime change

- Pins Catalog Templates release `v0.3.0-rc17` at commit
  `3de2103927bbd7c61604428bb951af90288c20ce`.
- Exposes 17 reviewed infrastructure templates and one project template.
- Adds `PastureStack Secret Volume`, backed by
  `ghcr.io/pasturestack/secrets-flexvolume-plugin:v0.1.0`.
- Registers one host-local `pasturestack-secret-volume` driver on every
  eligible host with the compatible secret-volume capability.
- Keeps operational Catalog and Compose image references on semantic version
  tags; release-verification digests remain outside the user interface.

The driver retrieves only the encrypted records authorized by an opaque
control-plane token, verifies their signatures, decrypts them with the host
identity key, and exposes read-only files through an isolated memory-backed
volume. The container drops all capabilities before adding only `SYS_ADMIN`
for the isolated mount. It does not request privileged mode, host networking,
a host PID namespace, or a container-engine socket.

## Image

```text
ghcr.io/pasturestack/server:v1.6.289
```

## Rollback

Stop the `v1.6.289` container and restore the exact stopped `v1.6.288`
container. Do not delete the server database volume. The Catalog pin can then
return to `v0.3.0-rc16` without changing existing application stacks. Remove
the Secret Volume stack and release all mounted secret volumes first if the
older Catalog should no longer present or maintain the driver.

## Attribution

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.

This release preserves the upstream history, license, notices, and third-party
attribution. PastureStack claims authorship only for its own changes.
