# Server v1.6.594 candidate

## Candidate boundary

This source candidate is not a published Server image or deployment result.
The normal Server workflow must build, scan and verify startup/restart before
publication. Matching Registry removal and retained-data acceptance on the QA
server remain pending. No runtime patch or production change is included.

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
