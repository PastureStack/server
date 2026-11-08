# Server v1.6.585 candidate

This candidate is not yet published. Use the current release in the README
until the new image is available.

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
Server image, deployment, actual network effects and affected role/UI acceptance
remain pending. Publication alone does not establish full frontend coverage.

Upgrade by changing the image tag to `ghcr.io/pasturestack/server:v1.6.585` after
publication. Preserve existing configuration and named volumes, and retain the
previous image and a current database backup for rollback.
