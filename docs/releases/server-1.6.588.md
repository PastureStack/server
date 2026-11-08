# Server v1.6.588

The immutable image is
`ghcr.io/pasturestack/server:v1.6.588@sha256:98ed72f3d2ed8ea5fb8bb35fba26e30c1f131c42df5ebf3819b92689856918cd`.
Normal publisher `42510664488` passed its source, build, final-image security,
startup and restart checks. All 35 anonymous assets, 36 release-attestation
subjects and both OCI attestations passed. Source revision
`82b40a1e4b861eddf9f8a0830105f611f8e2805a` has the same tested tree as PR482
producer `7b08078944f1dd619d5baffaff261cf289bc97ce`.
At publication qualification, QA deployment and affected native/UI acceptance
remained pending; these are separate from image and component qualification.

## Verified component inputs

Engine `v0.183.390` passed twelve anonymous asset checks and thirteen native
release-attestation subjects. Its exact original JAR and frozen role/schema
identities are bound to the signed producer
`c5899bca4c15c7c853d668d021024eeba62fc8f9`. This component qualification does
not by itself establish a native workflow result.

Web Console `1.6.231` / optional Bridge `0.2.33`, immutable release 438433509,
passed thirteen anonymous asset checks and fourteen native release-attestation
subjects. The original archive, runtime SBOM and lock are bound to producer
`33e7e1f0584c7f8723faad7f5d3b3d994880b06a`. The Bridge remains a separate,
optional fixed-profile client rather than an additional Server image input.

Compose `v0.14.44` remains the same published artifact as Server587, with twenty
anonymous assets and twenty-one cryptographic subjects verified. Host API
`0.38.9`, Node Agent `0.13.35`, bootstrap Agent `1.2.34`, Catalog `0.20.17` and
all other component coordinates remain unchanged.

## Affected source behavior and acceptance boundary

Service startup command and entry-point changes reuse the existing typed
preview, human approval, apply and outcome workflow. Native account/API Key
limits and full configuration comparison remain authoritative.

Ordinary Compose Stacks with no Catalog identity do not request Catalog
metadata. Genuine Catalog upgrade lookups remain on the existing queue; an
upgraded Stack retains its finish action. This does not add Registry removal.

Existing operator configuration, networking/storage defaults, all four
independent default-off settings, twelve tools, official dependency pins and
security gates remain unchanged. Retain the preceding Server image and its
matching data backup as the immediate rollback. Deployment-specific workflows
and complete frontend coverage require their own acceptance evidence.
