# Server583 same-artifact publication recovery

## Recovery v1

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

The recovery workflow is a separate signed source and invocation. It emits the
custom predicate type `https://github.com/PastureStack/server#recovery-v1`,
a short identifier in this repository namespace defined by this document, rather
than submitting the
statement as standard SLSA provenance. GitHub rejects unsupported SLSA build types
and checks standard provenance against the signing certificate during storage.
[Official build-type limitation](https://github.com/actions/attest/issues/195),
[official persistence verification](https://github.com/actions/attest-build-provenance/issues/539).

The custom statement retains the entire original build identity, failed-run
status, successful security/build/push steps, cleanup and exact original evidence.
A nested original-build SLSA-shaped record uses the documented GitHub workflow/v1
format but is explicitly reconstructed from official records, with no original
signature. `originalNativeSlsaAvailable` and `originalSignatureAvailable` are
false. This is not a claim that original native SLSA provenance passed.
[Official generator source](https://github.com/actions/toolkit/blob/main/packages/attest/src/provenance.ts)

`RecoverySigner` records the real completion workflow/ref/source/run/attempt.
The native certificate must identify that exact signer and invocation. Both
certificate and full custom predicate must pass; standard SLSA cannot substitute
for this custom statement. Metadata exposes the custom predicate type and model,
and explicitly retains the absence of original native SLSA. No SLSA level or
recovery-build claim is made for the original image.

The pinned `actions/attest` Custom mode supports a custom predicate type and a fixed OCI
subject digest. The original CycloneDX bytes receive a separate native SBOM
attestation. [Pinned action inputs](https://github.com/actions/attest/blob/1e69f48acb82d1966a394da916b4c1698aa569d6/action.yml)

Verification requires native signature and transparency verification, exact
signer workflow/digest, source digest/ref of the recovery workflow, certificate
run invocation, original builder, and exact predicate. `--source-digest` here is
the true recovery certificate source; original image source is checked separately
against the reconstructed claim and original run. The custom type is always
passed explicitly to the CLI; it never relies on the standard SLSA default. [GitHub CLI verification policy](https://cli.github.com/manual/gh_attestation_verify)

Verification loads both native bundles from the fixed digest's OCI registry with
`--bundle-from-oci`. The GitHub attestations API was reproduced returning HTTP422
`predicate_type invalid predicate type provided` for this exact custom type;
the same subject without that API filter returned its attestations. This changes
the official bundle retrieval source, not the custom predicate, CLI version,
cryptographic verification or identity policy. Explicit repo, signer, source/ref,
predicate type, transparency witness and full payload checks all remain required.
[Official OCI bundle loading mode](https://cli.github.com/manual/gh_attestation_verify)

OCI bundle verification alone cannot detect a later repository rename/name reuse.
The separate live GitHub checks of the original job/artifact/source and actual
completion run/source remain mandatory; registry bundles do not replace that
current official identity chain.

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
