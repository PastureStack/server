# Server 1.6.274

PastureStack Server `v1.6.274` is a compatibility hotfix release for persisted Runtime coordinates and Linux node-agent upgrades.

## Changes

- Pins both Agent settings to public Node Agent `v1.2.31` at digest `sha256:89a1703d236fb2ba34d568faef1cf0a41f91a2a5a7e6b8052415ba5a12f2d0e1`.
- Accepts valueless environment names preserved by older Docker releases when the replacement Agent imports the existing container configuration.
- Preserves, migrates, verifies, and restores both Catalog `commit` and `pinned_commit` values.
- Waits for Catalog synchronization before declaring a persisted-coordinate migration successful.

All other assembled component versions and the pinned Catalog source commit remain unchanged from `v1.6.273`.

## Upgrade validation

The release requires:

- anonymous image pulls from GHCR;
- an existing Linux Agent upgrade with valueless proxy and scheduler variables;
- both Linux hosts reconnecting with the exact Node Agent digest;
- all system services returning to `active` and `healthy`;
- cross-host IPsec connectivity recovering after reboot;
- a checksum-protected persisted-coordinate rollback bundle.

Windows hosts remain unsupported.
