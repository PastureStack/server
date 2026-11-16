# Server v1.6.602

Published image: `ghcr.io/pasturestack/server:v1.6.602@sha256:4c3ebf550e12e1778d7b0eee71dfa9b2104153966fb76ff3a304abb139098d62`.

Source commit: `33edd8deaac3fe5236c5206f7aaaca883a14c3e7`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

This release rebuilds the Ubuntu 26.04 rsync package at
`3.4.1+ds1-7ubuntu0.3+pasturestack.1` with the
[upstream bounds-check fix for CVE-2026-70457](https://github.com/RsyncProject/rsync/commit/defd7110ac9bd60529b3d39cfd5cafe8cc5716de).
The build verifies signed Ubuntu source indexes, pinned source checksums,
package identity, and ordinary local transfer compatibility.

The rsync 3.5.2 CVE-2026-119741 change remains tracked pending a compatible
Ubuntu package or separately qualified backport. OpenSSL updates remain
tracked for the supported distribution packages.

See the [upgrade guide](../upgrades/README.md) for volume preservation and rollback.
