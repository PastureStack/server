# Server v1.6.503

This is a candidate until its official publisher and immutable release readback
complete. The release's `published.txt` must identify the exact Server source
and image digest; component tests are not packaged browser acceptance.

## Shared schema lookup

Web Console `1.6.167` aligns synchronous schema lookup with the ID normalization
already used when schemas enter the API store. Mixed-case resource types such
as `registryCredential` otherwise miss a correctly cached permission schema.
Only IDs looked up in the normalized `schema` group are normalized. Ordinary
resource IDs remain opaque and case-sensitive. Actual store regression tests
must cover inherited Resource schema lookup, readonly/member methods, missing
schemas and separate project stores; no fallback permissions are introduced.

Server build inputs pin Web167 source
`dff35fc4bce340e21cac7204146a7bcb20a7b60b` and archive SHA-256
`e8e714fc06282de75a3570aac1d4d4d04a3c9478d982d0d5aaeae14efa8ebbaf`.
Exact-source component validation 37012345421 passed 772/772 tests with zero
failures, skips or todo cases and byte-identical production archives. Four new
Store/schema regressions and the local Chrome 4-test/43-assertion run passed.
The component's immutable public readback is required before Server publication;
these results are not packaged browser or complete matrix acceptance.
Engine `v0.183.331` and its exact WAR, API/schema, backend authorization,
authentication/session ownership, OIDC/MFA, runtime overrides, nftables settings,
security thresholds and multi-stage/single-runtime-layer contracts are unchanged.
No database migration or runtime patch is required.

## Acceptance and recovery boundaries

Registry111/credential6880 QA on Server502 stopped before resource writes at the
missing credential-model schema. Its original HOLD remains unchanged. A new
503 forward-only case must use the same exact owned IDs, normal-CSRF v1/v2-beta
denials, actual UI capability checks and thirteen-catalog badge checks before
normal advertised cleanup. It must not replay fixture creation or relabel the
old case as a passing complete lifecycle. The full permission/resource/locale
matrix remains INCOMPLETE.

After verified publication and successful packaged QA, change only the Compose
image to the new tag and verified digest. Preserve environment variables, named
volumes, restart policy, AppArmor, HTTPS origin, OIDC/MFA, performance parameters
and firewall mode. Keep the previous immutable Server502 image/container and
database/volume backups. Roll back code using that image with the same data and
configuration; do not delete volumes or run SQL repair statements.

No deployment to `stack.ascdc.tw` is authorized. Existing vendor-pending CVEs
remain documented under the unchanged gate; no zero-vulnerability or complete
matrix claim is made by publication.
