# Node agent image builds

The compatibility base targets `ghcr.io/pasturestack/node-agent-base:v0.3.6`.
It builds Python 3.14.9 from the official SHA-256-verified archive, retains
Docker CLI 29.7.2, and uses the fixed Ubuntu 26.04 snapshot
`20261023T000000Z`. Builder and runtime package inventories are compared;
the runtime verifies the patched OpenSSL, curl, libc and CA package versions.

The shared `tools/pip-security-overlay` helper builds the clearly identified
downstream wheel `pip 26.2.2+pasturestack.1` from pinned official inputs using
upstream vendoring machinery. Only urllib3 changes to 2.8.0; unrelated vendored
sources and licenses are byte-preserved. Both live pip and the embedded
ensurepip wheel are updated, and a fresh venv runs the same streaming/TLS tests.
This repack is not an official PyPA pip release.

`release-inputs.env` pins the published mount-propagation 1.0.12 binary and
the existing `r` helper from the previous immutable base. The helper is
checked by SHA-256 before entering the build context. No running host or
existing image is patched in place.

The protected-main-only **Publish Node Agent Runtime** workflow builds once,
runs Python/ensurepip/pip/CA, TLS 1.2/1.3, rejected-certificate, registration
URL and credential-file checks inside the resulting image, and retains the
raw SBOM and vulnerability/secret reports. Critical/High or vendor-fixed
findings fail the gate; vendor-unfixed Medium/Low findings remain recorded.
Publication then pushes that same image, refuses an existing version tag,
and verifies the anonymous digest readback and original image identity.

After the workflow is reviewed and merged, publish the base with:

```sh
gh workflow run publish-node-agent.yml --ref main -f component=base -f publish=true
```

The agent `v1.2.32` stage is enabled only after its Dockerfile pins the new
base digest. It runs the same image checks and publication gate with
`component=agent`. Image digests and proof of publication come from the
completed workflow evidence, not from this source description.
