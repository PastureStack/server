# Server v1.6.592 candidate

Prepared source only; no Server image or release has been published.

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
