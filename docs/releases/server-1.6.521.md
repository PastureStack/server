# Server v1.6.521

Packages Engine `v0.183.337` and unchanged Web Console `1.6.181`.

## API Key audit identity

Rejected Key edits after request validation could be recorded under an internal
numeric Key ID, while the Key audit screen queried the public ID. The events
were stored but omitted from that query. Engine now consistently formats the
authoritative Key identity. The audit reader also recognizes historical numeric
IDs, but only as exact aliases of the Engine-authorized Key. Other resource IDs,
unknown ownership and inaccessible environments are not treated as aliases.
Stored events are not rewritten. Safe list/detail projections return public
Key IDs consistently, including pagination and outcome filters.

## Verification boundary

Focused tests cover new events, historical list/detail queries, both Key types,
pagination, filters, cross-Key and cross-environment exclusions, secret-field
projection, and unchanged MFA confirmation. Full DTO and database-row checks on
rejected policy edits are part of runtime acceptance. These checks are not a
claim that every unrelated resource/role combination has been exercised.

## Upgrade and rollback

Use `ghcr.io/pasturestack/server:v1.6.521`. Preserve existing environment variables,
volumes, networking, restart policy and security options. No database migration
or proxy/authentication configuration change is required.

`v1.6.520` is the compatible rollback version; it restores the numeric-ID audit
query defect. Follow the [API Key rollback guidance](../upgrades/api-key-policy-rollback.md)
before considering an older, policy-unaware release.
