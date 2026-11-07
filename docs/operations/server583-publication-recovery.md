# Server583 same-artifact publication recovery

## Original build with recovery signer v1

This fixed protocol completes Server `v1.6.583` from image
`sha256:e22ecd94bbc83c2d34f49aa7dde231301f42a26de9a89c929e8a11d886b6c78c`.
It does not build, pull, retag or repush the semantic image, scan again, or run
new product acceptance. OCI attestation referrers are appended to that exact
subject. The original publisher remains failed.

Original builder: `publish-current-server.yml` at source
`6e6befedc7cd97dc3685ef7f6010b1fa2506bd77`, tested tree
`aa6227d081ad14c6237e6af062357ce1c22d034b`, run `42381092651`, attempt1.
Artifact `13578150593` is exactly6,656,789 bytes with SHA-256
`e1a66835172702f891e52aa2df524b47516b599191b722af859287c0f8548a26`.
All original build/security/push steps and run-owned cleanup must pass; only the
provenance transparency-log HTTP500 is eligible. SBOM/release must be skipped.

The recovery workflow is a separate signed source and invocation. The SLSA
predicate retains the original builder/invocation/source and artifact dependency;
`RecoverySigner` explicitly records the real completion workflow/ref/source/run/
attempt. Its certificate must identify that exact recovery signer and invocation.
This protocol makes no SLSA level claim and never represents the recovery commit
as the image build source. SLSA distinguishes builder from signer and requires
specific trusted pairs. [SLSA provenance specification](https://slsa.dev/spec/v1.1/provenance#builder)

The pinned `actions/attest` action supports a custom predicate and a fixed OCI
subject digest. The original CycloneDX bytes receive a separate native SBOM
attestation. [Pinned action inputs](https://github.com/actions/attest/blob/1e69f48acb82d1966a394da916b4c1698aa569d6/action.yml)

Verification requires native signature and transparency verification, exact
signer workflow/digest, source digest/ref of the recovery workflow, certificate
run invocation, original builder, and exact predicate. `--source-digest` here is
the true recovery certificate source; original image source is checked separately
against the predicate and original run. [GitHub CLI verification policy](https://cli.github.com/manual/gh_attestation_verify)

The completion source may add only this document, the fixed workflow, script,
policy and focused tests. It cannot modify recipes, source gates or CodeQL.
Release publication is gated by fresh original-run/artifact/source checks, exact
public registry tag/manifest/config identity and both native attestations. The
release keeps the original source tag,35 exact assets,36 native cryptographic
subjects and35 anonymous-byte readbacks. Only notes/checksums and lossless gzip of
the original findings TSV are newly derived; no original report is rewritten.

A repeated failure stops. No existing release/tag is deleted or replaced. A
completed release is verified through the normal consumer with the explicit
recovery chain; it is never made eligible by treating the old run as successful.
