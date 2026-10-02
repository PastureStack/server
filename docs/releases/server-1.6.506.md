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

The new numeric immutable tag must not replace `v1.6.505`. Image publication,
start/restart checks and packaged browser lifecycle acceptance are pending.
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
