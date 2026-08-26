# PastureStack Server v1.6.359

Server v1.6.359 updates the embedded API Explorer without changing the
orchestration engine, Web Console, authentication service, databases, or
control-plane API behavior from v1.6.358.

## UI dependency update

- API Explorer: `1.1.17`
- API Explorer source: `94e617e0f8950ea80bdb46aaf181f463bae2cea9`
- API Explorer artifact SHA-256:
  `6dc1bfd64f520444efe370bb8141fa3bcc36fa0008617e508375b781ecf30fc3`
- Bootstrap CSS: `5.3.8`
- Bootstrap Icons: `1.13.1`
- Bootstrap JavaScript: not included

This removes the retired Bootstrap 3.4.1 stylesheet and Glyphicons from the
server image. The small first-party modal and dropdown compatibility layer is
retained and covered by the API Explorer security tests.

The v1.6.358 base image is digest-pinned. Assembly verifies the API Explorer
release checksum, safe archive members, required license files, exact source
revision, Bootstrap 5 marker, icon font, and absence of Bootstrap 3 CSS before
replacing `/usr/share/cattle/war/api-ui`.

PastureStack is an independent community effort and is not affiliated with or
endorsed by Rancher Labs or SUSE. Existing licenses and upstream attribution
remain applicable.
