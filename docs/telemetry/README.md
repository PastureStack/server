# Telemetry

PastureStack does not operate a hosted telemetry collection endpoint. Server
installs the reviewed `PastureStack/usage-telemetry-agent` executable and keeps
the established launcher setting disabled by default.

External publishing has two independent opt-in gates: the compatible
`telemetry.opt` setting must be `in`, and an operator must explicitly configure
`PASTURESTACK_USAGE_TELEMETRY_TARGET_URL`. The inherited `TELEMETRY_TO_URL`
variable is ignored, so an old configuration cannot silently contact a retired
service. Without the new target, only the loopback aggregate endpoint is active.

The agent returns counts and fixed categories. It excludes resource names, host
names, addresses, raw image coordinates, catalog identifiers, credentials, and
secret values. The existing installation identifier is omitted unless separately
enabled, is then represented only by a full SHA-256 digest, and is never created
or written by the agent. See the agent archive's `PRIVACY.md` before enabling a
destination.
