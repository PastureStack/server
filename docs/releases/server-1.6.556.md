# Server v1.6.556

This release packages Web Console 1.6.199 and Engine 0.183.356 for opt-in AI
resource discovery and typed, human-reviewed workload changes. The matching
stdio source bridge is 0.2.1. Other bundled components retain their existing
pinned versions. It does not complete every frontend WebMCP workflow.

## Behavior

Five tools extend the existing seven: capability discovery, typed resource
search, safe details, resource-change preview and approved application.
Basic Stack/Service/Container creates are stopped. Metadata editing, lifecycle
and scaling use the existing domain managers and live role/Key authorization.
Advanced form fields and other resource workflows remain explicitly pending.

Keys cannot approve or cancel their own plans. A human reviews exact changes,
then the original bound Key can apply one durable operation. Uncertain dispatch
does not replay. Completion observes child services, the deployment owner's
desired/global/sidekick units and retired-instance cleanup. Global Services reject manual counts; Stack changes preflight all affected children before dispatch. Human inboxes allow
unused approved plans to be cancelled before submission.

New controls and errors use all 13 console locales. Dedicated bridge metadata
reads project only allowlisted fields, retaining live permission and revision
checks. Credential values, raw logs and full configuration payloads are excluded.
Ordinary Full/legacy Keys and ordinary UI/API workflows keep their current paths.

## Enabling and qualification

The new `api.ai.resource.change.enabled` property defaults to false, separately
from the existing bridge and upgrade-plan flags. Preserve existing JVM options,
Compose environment, named volumes, restart policy, AppArmor and HTTPS origin.
See [AI collaboration](../ai-collaboration.md) for the supported flow.

Required component CI, CodeQL, artifact/SBOM verification, Server checks and
8080 browser/lifecycle acceptance are separate results. Exact immutable image
digest, producer identities and executed acceptance are recorded with release
assets and the Excel evidence, not inferred from source-level tests. Existing
unaffected PASS evidence is retained; pending workflows are not promoted.

## Upgrade and rollback

Back up the database and persistent volumes and retain the prior Server image.
Liquibase adds the private resource-change plan table. Preserve it and existing
Key-policy and upgrade-plan records on code rollback; do not delete a migration
or replace named volumes. Stop new AI clients, let accepted work settle, cancel
unused plans and revoke dedicated bridge Keys before a downgrade. Follow the
[API Key rollback safety guide](../upgrades/api-key-policy-rollback.md).

Use normal image/Compose deployment. Do not carry a previous image's
version-owned environment defaults or a static-bundle runtime patch into the
new image. Genuine operator overrides and persistent data must be preserved.
