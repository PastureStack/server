# Node agent image builds

The compatibility base is `ghcr.io/pasturestack/node-agent-base:v0.3.10`.
It builds Python 3.14.9 from the official SHA-256-verified archive, retains
Docker CLI 29.9.3 rebuilt from its official source using Go 1.27.4 and OpenTelemetry 1.47.0 (CVE-2026-128085), and uses the fixed Ubuntu 26.04 snapshot
`20261023T000000Z`. Builder and runtime package inventories are compared;
only qualified backports and the pinned official glibc and Brotli revisions
may differ in the final runtime.
The Python compiler stage keeps its original libc. The runtime verifies the
patched OpenSSL, curl, libc, Brotli, PCRE2 and CA package versions.
PCRE2 retains the qualified maintenance-branch fixes, including the callout
correction absent from Ubuntu revision `10.46-1ubuntu0.1` (USN-8974-1).

The digest-pinned, build-only Ubuntu backport bundle updates only already
installed packages, preserving the existing coreutils provider and package set.
Its source/native-test qualification, package manifest and installation receipt
are retained under `/usr/share/pasturestack/security/ubuntu-backports/`.
The bundle and installer are read-only build mounts, not runtime dependencies.

The shared `tools/pip-security-overlay` helper builds the clearly identified
downstream wheel `pip 26.2.2+pasturestack.2` from pinned official inputs using
upstream vendoring machinery. It updates urllib3 to 2.8.0 and msgpack to 1.2.3. Unrelated vendored
sources and licenses are byte-preserved. Both live pip and the embedded
ensurepip wheel are updated, and a fresh venv runs the same streaming/TLS tests.
This repack is not an official PyPA pip release.

`release-inputs.env` pins the published mount-propagation 1.0.14 binary and
the `r` helper from its pinned immutable image input. The helper is
checked by SHA-256 before entering the build context. No running host or
existing image is patched in place.

The protected-main-only **Publish Node Agent Runtime** workflow builds once,
runs Python/ensurepip/pip/CA, TLS 1.2/1.3, rejected-certificate, registration
URL and credential-file checks inside the resulting image, and retains the
raw SBOM and vulnerability/secret reports with Trivy 0.76.2. Critical/High or vendor-fixed
findings fail the gate; vendor-unfixed Medium/Low findings remain recorded.
Publication then pushes that same image, refuses an existing version tag,
and verifies the anonymous digest readback and original image identity.

The node-agent v1.2.36 wrapper pins the published v0.3.10 base digest in its Dockerfile. Both `base` and `agent` components use the same
qualified runtime-package receipts, native OpenVEX guard, raw/effective scans,
runtime checks and publication gate. The wrapper binds the base producer run,
artifact checksum and OCI digest, then verifies its own package inventory and
final CycloneDX SBOM against that qualified stage.

For a new version, update the reviewed source version and pins before
dispatching the protected workflow with `component=base` or `component=agent`
and `publish=true`. Existing numeric version tags are rejected. Completed
workflow evidence records each published digest and source revision.
