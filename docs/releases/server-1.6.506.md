# Server v1.6.506

## Scope

Package Web Console `1.6.169` to fix the shared unallocated-local-volume
classifier. The existing engine generates `externalId` from a local volume name;
that identifier does not establish host, workload or storage-pool allocation.
The previous classifier rejected the legitimate value and could hide a created
inactive volume. The corrected classifier preserves full scoped mount and
advertised pool-relationship proof, explicit classification and environment
schema ownership. Inactive volumes retain their native advertised remove action.

Engine remains `v0.183.332`. Authentication Service, token ownership, OIDC/MFA,
API authorization, persistence, host firewall selection and proxy configuration
are unchanged. No runtime patch or company deployment is included.

## Publication and verification

Web Console `1.6.169` is published from signed source
`5962f57fccb4062a65b5921646c06b4663713b9b`; official validation run
`37078265265` passed 791 tests with zero failures, skips or todo. The two builds
produced the identical archive SHA-256
`e2bcb97b0da810f2ff216f9738739235e3c6f29ef46f1d99b623cf9c9f7258e2`.

Server source is `3cfb920a428fc2af6af6a07a832d6882663f544d`; official publisher
[`37079727511`](https://github.com/PastureStack/server/actions/runs/37079727511)
completed the image build, start/restart, 34 MFA/API checks, TLS, single-runtime-layer,
SBOM and security gates. The numeric immutable image is
`ghcr.io/pasturestack/server:v1.6.506@sha256:f6860a1d0e96587b05afbf72d52c063921ff8473a976552c6d0a01d223a7a188`;
it does not replace `v1.6.505`.

The first publisher `37079232161` stopped at the source gate before building.
PR232 corrected the published-heading parser and stale packaging-test version
pins; it did not relax digest or security checks. That failed run remains failed.
QA8080 deployment completed: first start and one restart returned HTTP200/pong
after 11 and 9 attempts. Runtime configuration, environment overrides, mounts
and five database counts were preserved. The v1.6.505 recovery point remains;
Docker health is null, not healthy. Packaged browser lifecycle acceptance is
separate and pending.
Earlier HOLD receipts remain
HOLD; known creation is not retroactively a complete lifecycle PASS. The full
permission matrix remains INCOMPLETE.

## Upgrade and rollback

Use the published image by its immutable digest after official readback. Preserve
the current Compose environment overrides, named volumes, restart policy,
AppArmor, HTTPS origin, performance and firewall settings. No data migration is
required. Retain the previous `v1.6.505` image and deployment recovery point;
never remove persistent volumes when rolling back.

Security exceptions retain the existing exact vendor-pending review policy;
this release does not claim zero CVEs or relax severity thresholds.
