# Server v1.6.484

This candidate packages Web Console `1.6.150` on the existing Server
`v1.6.460` runtime base with Orchestration Engine `v0.183.326`. The Web Console
release tag `1.6.150` resolves to merged source commit
`584a548dc30f8d59bcc3f1c9aba17e7b26eff4ef`. Its published archive
`web-console-1.6.150.tar.gz` has SHA-256
`9f9de0ab54ef9ad8b4bb1dd7f08e6d4c5c1aa1373e02f231fdad5e27916695b1`
and contains `VERSION.txt=1.6.150`. Validation run `36392620778` passed source
tests and byte-identical production builds from the merged commit. The source
change limits Certificate and RegistryCredential edit requests to editable
fields; isolated browser/API write acceptance remains a separate gate.

Only the Web Console archive and Server identity change from `v1.6.483`; the
runtime base, package pins, and Engine remain unchanged. The prior reviewed
OpenVEX and vendor-pending finding sets are carried forward with a new document
identity, not treated as proof of a new scan. The release workflow must build
the exact candidate, flatten its final rootfs, scan it with pinned Trivy, and
prove the remaining findings equal the tracker. Any new or changed finding
blocks publication until reviewed; no severity threshold is relaxed.

Run `bash -n` on the changed scripts and
`bash scripts/check-server-api-explorer-patch.sh` (or the aggregate
`bash scripts/check-server-source-gates.sh`). The image build and merged-rootfs
security gate remain separate later validation steps; a source gate alone does
not prove their results.

This source note alone is not proof of image publication or isolated browser
acceptance; verify the immutable release tag, digest, and workflow evidence.
Preserve the current Compose environment,
volumes, restart policy, AppArmor configuration, HTTPS origin, OIDC settings,
and nftables architecture during later validation.
