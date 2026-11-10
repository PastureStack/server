# Server v1.6.594

## Published artifact

Image: `ghcr.io/pasturestack/server:v1.6.594@sha256:4795d2a0ab9d91215ec98c713bdc752f0891289310547b4d1ee00062ffec58d4`.
Source: `7186ad16e6b8ffe1f2140f156fa1d2937344cfc4`.
Publisher [42796953358](https://github.com/PastureStack/server/actions/runs/42796953358)
passed normal image build, security, startup and restart checks. Independent
readback verified 35 public assets, 36 signed subjects and two OCI attestations.

## Acceptance boundary

Normal QA deployment and one Server restart preserve mounts, named volumes,
operator configuration and all three Host/Agent identities. The previous Server
is retained for rollback. Matching Registry business acceptance remains pending;
this release does not claim the entire WebMCP inventory has passed. No production
change or runtime patch is included.

## Verified component inputs

Packages immutable Engine v0.183.394 with Web Console 1.6.233, optional Bridge
0.2.35 and Compose 0.14.45. Web, Bridge, Agent and Compose bytes are retained.

Registry API Key rules now constrain the persisted StoragePool query and direct
authorization consistently. Existing parent StoragePool rules still apply to
the same Registry ID. Parent and subtype denials both win; Registry grants
cannot authorize ordinary pools. Live owner ceilings, Full/legacy behavior,
human confirmation, configuration CAS and at-most-once dispatch are preserved.

The component passed its required CI and immutable artifact qualification.
Component evidence does not establish deployed Server business acceptance.

The Engine builder verifies Canonical's exact rust-coreutils security backport
using installed ELF bytes and native Trivy OpenVEX. This build-only package is
not a Server runtime change. Existing unfixed runtime CVEs remain tracked;
HIGH/CRITICAL, fixable and unregistered findings continue to block publication.
