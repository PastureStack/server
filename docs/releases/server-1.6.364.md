# PastureStack Server v1.6.364

Server v1.6.364 hardens the Ubuntu 26.04 runtime without changing the
application, database schema, public control-plane API, or bundled PastureStack
service versions.

The image installs Ubuntu's fixed OpenSSL and libssl packages at or above
`3.5.5-1ubuntu3.4`, removes the set-user-ID bit from the `mount` and `umount`
helpers, and verifies that the runtime filesystem table has no active mount
entries. Ordinary non-privileged operation is unchanged; privileged mount
operations now require root.

The image also disables SSH client X11 forwarding, trusted X11 forwarding, and
GSSAPI authentication through a system configuration drop-in. The server image
does not run an SSH daemon, and normal public-key SSH client use remains
available when explicitly invoked.

The release workflow built the committed revision once, started it with fresh
data volumes, verified HTTP 200 / `pong`, restarted it and verified `pong`
again, then scanned the exported final root filesystem. The release gate found
zero Critical vulnerabilities, zero High vulnerabilities, and zero embedded
secrets. It publishes the exact image, CycloneDX SBOM, provenance and SBOM
attestations, checksums, and merged-rootfs scan evidence.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
