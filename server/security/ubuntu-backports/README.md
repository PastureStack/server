# Official source security backports

These are first-party rebuild tools, not Canonical packages or a statement that
any running product is fixed. Each module retains the original Ubuntu packaging,
pins official inputs by SHA-256, and requires its owning tests and extracted
package/ABI checks before exporting evidence. Native build helpers export packages;
the separate build-only bundle installs only qualified, already-present packages
into disposable consumer image builds.

`ubuntu-backport-native.yml` builds disposable Ubuntu26 amd64 candidates without
host mounts, publishing credentials or deployment rights. Initial pull requests
run native validation; after changes, explicitly dispatch only affected modules.
Do not rerun an unchanged module that already has valid native PASS evidence.
Its module source, lock, compiler/dependency inputs and expected artifact identity
must still match. Changes to shared behavior require revalidating its consumers.

Select `glibc`, `rust-coreutils`, `jq`, `p11-kit` or `libxrender` in the
workflow. Source helpers run as a non-root user; Rust credential regression
subprocesses alone receive privileges inside that temporary container. A failed
helper retains logs and a failing result; exported files alone are not a PASS.

Before a product consumes a candidate, require the exact native result,
provenance, source lock, package hashes, ABI and affected runtime smoke. Any
remaining CVE or unknown architecture/reachability condition stays tracked.
Never overwrite a released package/image tag or patch a running container.

The attempted tar CVE-2026-18477 backport was rejected: its original cyclic-rename
regression loses three restored files on the Ubuntu baseline. Source application
alone was insufficient. Neither it nor the incomplete CVE-2026-18508 backport is
offered here; a complete compatible official fix is still required.

## Shared consumer inputs

`bundle/` binds the successful native job, source commit, source lock, package
bytes, licensing and regression evidence for each family. The separately
versioned `ubuntu-security-backports` OCI package is a build input, not a service,
runtime base image or Catalog entry. Consumers pin its immutable digest and
mount it only in their final runtime build stage, after their existing Ubuntu
security updates. Their compiler/build stages retain their original packages.

The static Go installer selects only packages already installed in that rootfs.
It checks archive and payload hashes, dependencies, ABI, package integrity and
provider/configuration preservation before accepting an installation. It must
not add an absent Rust, development or other runtime package, change a coreutils
provider, invoke apt, use force flags or patch a running container. Legitimate
Ubuntu image documentation exclusions are recorded and restored only for the
selected package paths; runtime exclusions or integrity differences fail.

Publishing requires real disposable consumer installs with both GNU and uutils
providers, in addition to the installer unit tests. A bundle PASS is still not a
product PASS: every consumer must retain its normal source/release gates, exact
final-rootfs SBOM, raw scan, scoped VEX and affected runtime smoke. See
`bundle/installer/README.md` for the fixed mount and command contract.
