# Server v1.6.585

[Server v1.6.585](https://github.com/PastureStack/server/releases/tag/v1.6.585) is formally published
as immutable Release `437988708` with 35 assets. The original
[publisher run](https://github.com/PastureStack/server/actions/runs/42438828513)
completed its source, security, startup, restart and publication checks.

Published image identity: `ghcr.io/pasturestack/server:v1.6.585@sha256:2f78f6ab0a4bf3de111ccaaf9ccd09ff304ac9ce0239efd063b67a2c798d4c6f`.
Source commit: `661e919b4f85f304b04a45e845fbe3fcad970cd4`.

Independent anonymous-asset and OCI verification remain pending. Deployment,
actual network effects and affected role/UI business acceptance also remain
pending; publication and component CI do not establish full frontend coverage.

## Verified component inputs

Includes Engine v0.183.387, Web Console 1.6.227 and optional Bridge 0.2.29.
Host API 0.38.9, Go Node Agent 0.13.35 and bootstrap Agent 1.2.34 are unchanged.

WebMCP can reset a Host's custom name to its existing hostname, update one
existing Container public-port binding, and change an existing Container link
target. Changes require human confirmation and retain account, API Key,
resource identity and concurrent-change checks. These edits apply to the
current Container; they do not rewrite its parent Service's launch configuration.

Removing a Driver Service now uses the native deactivate/remove sequence when
its Network or Storage driver is still activating. Existing native Port clients
remain compatible when they omit the optional concurrency-check header.

Component CI passed: Engine 4,273 tests with no failures or errors (one inherited
skip); Web Console 326 focused cases and 1,144 browser cases; Bridge SDK handshake.
These component results are separate from the pending deployment and affected
business-workflow acceptance described above.

Use the numeric image tag `ghcr.io/pasturestack/server:v1.6.585` for upgrades.
Preserve existing configuration and named volumes, and retain the
previous image and a current database backup for rollback.
