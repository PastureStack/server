# Server v1.6.548

Published from producer `62dddd5269e2f4b9b8925e424f55359146c786ae` via
[publisher 40018625225](https://github.com/PastureStack/server/actions/runs/40018625225).
All 26 immutable release assets and their SHA-256 checksums passed anonymous
readback. Image provenance and SBOM attestations were independently verified
against the same source, workflow and published digest.

Published image identity:
`ghcr.io/pasturestack/server:v1.6.548@sha256:a20b7f32d53152a7be11b28ff0c081679e42161e3142718424a3bcabfab115be`.
The distinct OCI config is
`sha256:58c9ac3c9d9002a0a02aac683caf5d7544d239930b55da5fd41ac18c5b7201b7`.
This linux/amd64 image has one runtime layer. Installation commands use the
numeric `ghcr.io/pasturestack/server:v1.6.548` tag; the full identity above is
for verification and traceability. Publication is not real-host acceptance.

## Verified component inputs

- Catalog v0.3.16 source `070e08d8f85ffc2779a0f97eb4e356c857812d34`
  adds Network Services revision 13 while retaining previous revisions.
- Network Plugin Manager v0.8.25 source
  `461182e1fcd09527509359f5c551704303689c04`, published manifest
  `sha256:9a66894138dc6dded756c5e4b80e6d235698d911031641f6c45763ad9b32d94e`.
- Metadata Service v0.10.6 source
  `3db2e1cd53530a04282f5c2448426334ea4d92a8`, published manifest
  `sha256:88267d800365d354f06519014a3e4f7ce967d05d4805e5a705944980e30449ff`.

The unchanged Engine v0.183.354, Web Console 1.6.194, Host API 0.38.8,
Node Agent 0.13.33 and other v1.6.547 components retain their exact inputs.
Component publication is separate from the environment acceptance below.

## Scope

This patch carries the Catalog update for Network Plugin Manager v0.8.25 and
Metadata Service v0.10.6.
It fixes CNI provider handoff during a managed infrastructure upgrade: a stopped
driver must not remain selected after a replacement driver starts. Driver
selection still uses authorized local infrastructure metadata and preserves
the host's existing firewall backend.

Metadata Service preserves the engine's opaque data-version token instead of
parsing it as an integer. Revision-and-hash tokens must not collapse to `0`:
otherwise version watchers cannot discover changed network endpoints. The
explicit version used for merged external metadata retains its existing
behavior. This patch does not change authentication, application data,
resource permissions, or the other component versions.

The previous v1.6.547 Network Services upgrade passed, but its subsequent IPsec
upgrade exposed the separate provider-event/retry defect. That failed attempt
and its normal Stack rollback are retained as QA evidence, not counted as a
successful upgrade.

## Security evidence

The complete runtime gate retains 51 raw findings. After exact existing VEX
dispositions, 29 officially unfixed LOW/MEDIUM package occurrences across 18
CVEs remain tracked. HIGH/CRITICAL, fixed-available, untracked findings and
detected secrets are zero. These exact dispositions are not a claim of zero
vulnerabilities or a substitute for deployment acceptance.

## Upgrade, rollback and acceptance

The exact published image passed a controlled first start and health check.
Operator environment variables, HostConfig, volumes and AppArmor were
preserved, with the v1.6.547 rollback container and verified database backup
retained.

Normal platform upgrades completed for all eight selected infrastructure
stacks, eleven services and fourteen image launches, with no unfinished
selected Stack or Service processes. The CNI wrapper selects the running v0.14.40
provider. Bidirectional traffic between the new overlay endpoints, internal
DNS, strict TLS, IPsec security associations and new health-check endpoints
passed. Metadata passed coherent dated/latest reads and two real change-token
notifications. All three original Hosts and Agents, application settings,
data, mounts and both reviewed image database settings were preserved.

Chrome 155.0.8059.41 passed OIDC/TOTP login, seven authenticated JSON API reads
(HTTP 200), refresh, three active Hosts and Agents, and the same browser cookie
across a real Server restart. A new WebSocket received a post-restart frame;
the passive browser checks issued no DELETE requests.

Two controlled same-version Server restarts returned healthy with configuration
preserved. The first restart is retained separately; a test-harness stdin
handoff issue required the second restart to complete the same-session browser
proof. Five transient WebSocket handshake 502 responses occurred during
controlled downtime. Normal before/after browser, API and request-failure
checks were clean; this is not a claim that every log entry was error-free.
The original workload primary, sidekick, volume and data marker were unchanged
after restart. This is scoped acceptance, not a complete feature matrix or a
production deployment.

Managers older than v0.8.24 retain their destructive Metadata/DNS reaper. Merely
recreating the Server does not upgrade existing infrastructure services.
Follow the [normal Catalog upgrade procedure](../upgrades/README.md), verify
the replacement providers and Metadata watch behavior, and finish or roll back
through platform actions rather than deleting dependency containers manually.
Preserve custom Catalog/agent overrides and matching database/volume backups;
after a data migration, selecting an older image alone may not be a safe rollback.

Do not infer deployment acceptance from component or Server publication.
Upgrade through the normal platform actions and retain a verified rollback
point until the affected services and workload data have been checked.
