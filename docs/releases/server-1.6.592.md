# Server v1.6.592

Published image: `ghcr.io/pasturestack/server:v1.6.592@sha256:27a7f80e8a8114c3a28e730d2fdf6fd948f69dc85c0c9d62b3831ed0a6bf6c84`.

Source commit: `e439c01628f3a29a5f552ce60f35b79576a471d4`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

Retains the published, qualified Compose0.14.45 archive and binary, Engine
0.183.391, Web Console1.6.233 and optional Bridge0.2.35. Compose producer
`e10eee523467ef2aa75a8bbdf290c2f5c505fbdc` now labels the actual packaged
binary. The build rejects a version, producer, archive or executable hash that
does not match the existing original-artifact review. It cannot merely update
the version while leaving the preceding producer metadata.

This supersedes the immutable Server591 metadata mismatch; 591 was rejected
before deployment. No Compose rebuild, dependency update, authorization or
runtime option change is needed. The bounded Stack rollback/finish observation,
original-event keepalive and single terminal-error owner remain from Compose45.

Matching 8080 deployment and affected native rollback/finish, data preservation,
refresh and restart acceptance are separate and remain pending. Preserve the
current qualified container/image and all persistent volumes for rollback.
