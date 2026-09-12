# PastureStack Server v1.6.429

This release repairs the Host API package that a new Linux host downloads
during registration. The Server's existing `host-api-0.38.4.tar.gz` came from
the v1.6.278 release with only `SHA1SUMS` and `SHA1SUMSSUM`; the current host
installer requires `SHA256SUMS` and `SHA256SUMSSUM` and rejected that archive.

The build verifies the immutable original archive's SHA-256 digest and its
SHA-1 checksum chain, then adds a SHA-256 checksum chain and repackages it.
The `host-api` executable and `apply.sh` remain byte-for-byte identical to
the original package. The active local-artifact URL and compatibility symlink
continue to resolve to the repaired archive. This deliberately does not
replace the runtime with the separate, still-unreleased Host API migration
candidate.

The release gate extracts the archive from the finished Server image and
executes the same two SHA-256 checks as the uncached host installer. It also
checks the original SHA-1 chain, unchanged binary/script hashes, runtime
artifact URL, and symlink. The exact archive and check result are included in
the immutable Server release, with their SHA-256 values in `SHA256SUMS`.

All other runtime components and behavior remain at v1.6.428. The existing
initial-start, restart, merged-rootfs vulnerability/secret scan, SBOM, and
image attestation gates still apply. Existing vendor-pending findings remain
documented rather than being claimed fixed by this packaging change.

The inherited runtime still includes the curl fix for `CVE-2026-8932`, glibc
`2.43-2ubuntu2.4`, and GNU coreutils `uniq` commit
`d64e35a8a4c0e4608321433e0d84d917e4e36371`. Ubuntu still marks
`CVE-2026-18374` as needing evaluation for Resolute. The inherited OpenSSL
closure for `CVE-2026-75803` and removal of the unreachable `diff3` path for
`CVE-2026-53910` are unchanged; unmatched vulnerability at any severity remains a release blocker.
