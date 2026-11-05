# Server v1.6.573

Packages Orchestration Engine v0.183.373, Web Console 1.6.214 with Bridge
0.2.16, and Compose CLI v0.14.43 from their original qualified releases.

Catalog stack creation now uses the same typed service representation and
stable new-Stack binding for preview and delegated execution. A newly assigned
Stack ID no longer changes the approved service hash. Ordinary Compose
commands retain their existing behavior; approval still rejects a changed
business payload.

Bound Bridge profiles discover the current Key policy revision before reading
their exact saved environment. Startup and explicit profile preparation retain
the saved endpoint, environment ID and UUID, including after a rename. Discovery
does not select a different environment or fall back to a display name.

Resource details include the same freshly authorized parent Stack reference as
resource search, allowing tools to distinguish services with the same name.

WebMCP adds bounded, read-only process diagnostics through the existing
resource query tools. Native role and API Key permissions remain authoritative.
Results include registered process names and safe state/time summaries;
truncated results do not establish completeness. Raw payloads, exceptions,
process replay and arbitrary HTTP access are not exposed to AI tools.

Existing feature opt-ins, networking defaults, official APT pins and archive
verification remain in place. This release does not require changing Compose
environment variables, named volumes or restart policy. Preserve the previous
Server image and data when upgrading; rollback must reuse the original mounts.

Component CI and signed release evidence accompany the component assets.
The Server image digest, security findings and scoped runtime acceptance are
reported separately with the published image and acceptance workbook. Component
test success does not mean every frontend workflow has completed acceptance.
