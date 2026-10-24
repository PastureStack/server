# Server v1.6.550

**Standalone attachment correction:** The manual completion script mistakenly
replaced `host-api-0.38.8.tar.gz` with an empty gzip stream. Do not use that
attachment. The Server image contains the correct archive, and the
[original Host API producer release](https://github.com/PastureStack/host-api/releases/tag/v0.38.8)
is unchanged. Matching upload checksums did not detect the substitution. The
original immutable bytes remain available as failure evidence; 551 adds a
producer-identity recheck after report conversion and publishes a fresh release.

Published image:
`ghcr.io/pasturestack/server:v1.6.550@sha256:03542028c3ce4be11d7ff87f96beddf5179c67caf9f0d28ad57043acf3cf52c5`.
Producer: `54deb98ee33ffab78437070d61179b602844182e`.

## Verified component inputs

Rebuild only `libpcre2-8-0` and `libpcre2-posix3` from Ubuntu `10.46-1build1`
with the twelve official `release/pcre2-10.46` backports through
`947809f11e9c9744aa0974b4b630a1ae461733dd`. Sources and patches are SHA-256 pinned.
The first-party version `10.46-1build1+pasturestack.1` is not a Canonical release.
Original packaging, ABI, JIT, POSIX interfaces and hardening remain unchanged.

Fixed: CVE-2026-103111, CVE-2026-86145, CVE-2026-89156, CVE-2026-89157,
CVE-2026-89158, CVE-2026-89160, CVE-2026-89161 and CVE-2026-89162.
See the [official backport list](https://github.com/PCRE2Project/pcre2/blob/pcre2-10.49/SUPPORT-LIFECYCLE.md).
Ubuntu lacking an updated package does not mean upstream has no accepted fix.
Web Console `1.6.195`, its original runtime SBOM, Engine `v0.183.354` and all
other component inputs remain unchanged. No database migration is introduced.

## Verification and remaining risk

Original native `pcre2_jit_test`, `RunTest` and `RunGrepTest` passed. Fourteen
builder contracts, five verifier guards, owning assembly checks, exact package
integrity, both library hashes and five actual consumers passed. C / C.utf8
regex controls cover ASCII, UTF-8, CRLF and the non-JIT path. The package-owned
README is retained during installation; integrity differences are not ignored.

The formal producer passed source, rootfs equivalence, startup/restart and fresh
security checks before pushing and signing the same one-layer image. The scan
retains 51 raw occurrences, 38 exact VEX dispositions and 13 pending LOW/MEDIUM
occurrences across 10 CVEs; HIGH/CRITICAL, available distro fixes, unregistered
findings and secrets are zero. Raw evidence remains available. Other artifacts,
build-host SDKs and the browser's six unsupported snapshots remain separately
tracked; this is not a zero-risk or complete-coverage claim.

The scoped 8080 deployment passed first start, one restart, exact package/hash/
linkage checks, grep/Git controls, two read-only MariaDB regex controls and three
active Host/Agent states. HostConfig, operator environment, all three data
volumes, socket bind and AppArmor were preserved. The verified consistent DB
backup and 549 rollback container/image remain. Unchanged UI, role and
identity-flow PASS evidence was carried forward; no full feature matrix or
cross-host network rerun is claimed. The production site, HAProxy and firewall
were not changed.

## Publication completion

[Run 40116218929](https://github.com/PastureStack/server/actions/runs/40116218929)
remains failed because the final renderer required a missing candidate-note
heading. Its tested, signed image was not rebuilt or overwritten. Original CI
bytes completed image publication and both attestations were verified. The
34 assets passed upload-to-download checksum readback, which did not establish
that the Host API attachment still matched its producer; see the correction above. The
[completion receipt](https://github.com/PastureStack/server/releases/download/v1.6.550/publication-recovery.json)
records the original archive and note-only correction. A permanent pre-build
test now validates the actual current note as well as fixtures.

## Upgrade and rollback

Use the numeric `v1.6.550` tag after verifying backups and image identity. Preserve
all existing Compose settings, named volumes, restart policy and security options.
Retain 549 until scoped acceptance succeeds. Do not patch a running container or
overwrite a release tag. Restore matching backups when an upgrade requires it;
this PCRE2-only update does not migrate the database.
