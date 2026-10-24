# Official source security candidates

These are first-party rebuild tools, not Canonical packages or a statement that
any running product is fixed. Each module retains the original Ubuntu packaging,
pins official inputs by SHA-256, and requires its owning tests and extracted
package/ABI checks before exporting evidence. No helper installs runtime packages.

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
