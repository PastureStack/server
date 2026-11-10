# Server v1.6.595 candidate

## Candidate boundary

Server build and publication remain pending. Matching QA deployment and the
complete Registry removal workflow are separate acceptance steps. No production
change or runtime patch is included. Preserve the published594 rollback.

## Verified component inputs

Packages immutable Web Console 1.6.234 and optional Bridge 0.2.36 with retained
Engine v0.183.394 and Compose 0.14.45. Agent and other runtime components retain
their published bytes; no dependency update or new CVE remediation is claimed.

A scoped Registry removal could succeed natively but lose its final active
navigation witness. The Bridge now observes only its already-issued, context-bound
Registry removal receipt through the original native authorization path. The
current actor, Key identity/revision, live role ceiling and removed target are
still checked. Other queries and mutations retain their navigation checks.
No second apply, client approval tool, generic scope grant or backend relaxation
is introduced. Browser session handling remains unchanged.

Original Web CI, static provenance/SBOM, required CodeQL and the packaged Bridge
SDK handshake passed before component publication. These checks do not establish
deployed business acceptance or complete frontend coverage. Existing runtime CVEs
remain tracked under the unchanged fixable/HIGH/CRITICAL publication gates.
