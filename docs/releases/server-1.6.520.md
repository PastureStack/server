# Server v1.6.520

Packages Orchestration Engine `v0.183.336` and the unchanged Web Console
`1.6.181`. This patch fixes audit classification for successful WebSocket
upgrades. An HTTP `101` response now records `SUCCEEDED` for the response phase;
it does not claim that the stream or a later operation completed successfully.
Explicit `DENY`, preview suppression, failed/cancelled operations, and ordinary
HTTP failure classifications remain intact. The change neither grants access
nor weakens revocation, expiry, MFA or the Key owner's live permissions.

## Verification scope

The Engine's focused audit suite covers 30 tests, including HTTP `101`, `100`,
`200`, `202`, denied requests, previews, and explicit operation outcomes.
The defect was reproduced through a real Key-authenticated subscription: the
connection opened and received server pings, then the server closed it after
the Key was revoked, while the successful handshake had been mislabelled as a
failure. Publication and deployment evidence must confirm the corrected audit
classification on the packaged image; source tests alone are not that evidence.

This patch does not change the console, authentication service, proxy, catalog,
node packages, database schema, or deployment settings. Existing pagination and
membership-revocation evidence remains scoped to the resources and roles it
actually covered; it is not a claim of whole-matrix acceptance.

## Upgrade and rollback

Use `ghcr.io/pasturestack/server:v1.6.520` after its immutable release is
published. Preserve the existing environment variables, volumes, network,
restart policy and security options. No database migration is introduced.
The compatible prior release `v1.6.519` is the rollback target; rolling back
restores the known HTTP `101` audit-classification defect. Do not roll back to
a policy-unaware release: follow the [API Key recovery guidance](../upgrades/api-key-policy-rollback.md).
