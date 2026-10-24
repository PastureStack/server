The installer is a Go 1.27.3 standard-library-only Linux amd64 binary. Build it
with `CGO_ENABLED=0 GOTOOLCHAIN=local GOOS=linux GOARCH=amd64`, run `go test ./...`,
and build with `go build -trimpath -ldflags='-s -w'`. The publisher places the same
binary at `/bundle/install-existing-backports` and `/out/install-existing-backports`.
It is a build tool, not a runtime dependency.

In a disposable Ubuntu 26.04 amd64 Docker build, mount the immutable bundle's
`/out` read-only at `/opt/pasturestack/ubuntu-security-backports`, then execute
`/opt/pasturestack/ubuntu-security-backports/install-existing-backports --install-in-docker-build`. Use a build mount
or remove the copied binary and bundle in that same `RUN`. The final runtime
needs only its existing dpkg utilities; Python, readelf, nm and a Go toolchain
are not added. `--verify-installed` performs the installed checks without an
installation. No root/manifest/path override is accepted.

Manifest v1 fixes Ubuntu 26.04 amd64, bundle 0.1.0, six families and twelve
runtime packages: PCRE2's two libraries; libc6, libc-bin and
libc-gconv-modules-extra; rust-coreutils; jq and libjq1; p11-kit,
p11-kit-modules and libp11-kit0; and libxrender1. Archives, complete non-directory
payload receipts, source provenance and qualification are SHA256-bound. The
installer independently reads each selected archive's control and tar stream,
checks every file/link and ELF identity, and preserves existing SONAME, library
dependencies and exported symbols before installation. The sole additive
dependency accepted is the amd64 system loader for a verified
`__tls_get_addr@GLIBC_2.3` import: every original dependency must remain, no other
loader import may be added, and the installed loader must provide that exact
symbol version. Unknown dependencies or missing provider symbols fail before
installation. This platform TLS rule does not special-case a product or package.
The publisher qualifies native owning
test evidence; consumer installation and product acceptance remain separate.

Only packages already installed in the consumer are selected. The package set
must remain identical; no Rust package or provider is added to a GNU-only image.
Exact-version dependencies from installed companion packages (including dev
packages) reject an upgrade if a matching companion is absent from the bundle.
The dependency dry run and actual batch installation use fixed dpkg options,
without apt, force options or dependency overrides. Original provider package
metadata, provider command paths, alternatives, diversions, statoverrides and
host configuration are compared before/after. Only the generated ld.so.cache
is excluded from the host-configuration snapshot.

Before installation, dpkg checksum differences or missing runtime files fail.
The sole permitted pre-existing difference is a missing selected-package
documentation file proven excluded by the consumer's current dpkg path rules.
Every such path is enumerated in the JSON receipt. Exact one-shot
`--path-include=/full/path` options restore selected documentation without
editing dpkg configuration. Other excluded runtime payload paths fail. After
installation, every payload file's SHA256/type/mode/uid/gid or literal symlink
target, every ELF receipt, package metadata, dpkg audit and full `dpkg --verify`
must match. No post-install difference is ignored.

Tests use temporary rootfs/bundle fixtures and a fake dpkg adapter. They never
install a package, change the host, run apt, or invoke libc-maintainer scripts.

`consumer-fixture.Dockerfile` adds a separate prepublication acceptance gate on
the pinned Ubuntu 26.04 image and signed 2026-10-23 archive snapshot. Run it in
the CI runner twice with `PROVIDER=gnu` and `PROVIDER=uutils`, context this folder,
additional build context `qualified=<qualified context containing out/>`, target
`evidence`, and local output per provider. The GNU fixture has eleven selected
packages and no Rust; the uutils fixture has all twelve. Both consume the same
read-only qualified bundle bytes, restore deliberately path-excluded docs,
perform actual install/verify, preserve package set and provider, and exercise
the installed glibc loader/cache, jq, id, p11-kit, PCRE grep and NSS getent.
A separate test-only C probe uses the official jq release headers and
`dlopen(..., RTLD_NOW)` without linking libjq or libm into the executable. Four
threads each execute 128 runtime sorts using independent jq states, starting at
a barrier. The compiler, headers and probe remain outside product images.
`result.json` and the console/install/verify receipts are exported. These are
isolated consumer fixtures. GNU baseline construction follows Ubuntu's documented
provider transition, including its required `--allow-remove-essential` option;
this is confined to test setup, before the backport installer runs. The installer
does not invoke apt or switch providers. These fixtures do not replace acceptance
in each actual product rootfs.
