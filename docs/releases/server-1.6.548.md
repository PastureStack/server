# Server v1.6.548 candidate

This is a source candidate. No Server v1.6.548 image has been published or
accepted on the QA deployment yet. Use the published release documented in
the README until this candidate passes the required release checks.

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

## Required acceptance

- Confirm the published Network Plugin Manager source, image digest and required
  checks, and the corresponding Metadata Service identity, before pinning the
  new Catalog commit.
- Complete Network Services and IPsec upgrades on the QA hosts through normal
  platform actions. Verify provider selection, final service health, DNS,
  container egress, cross-host traffic, version-watch updates and unchanged
  workload data. Verify replacement endpoint discovery and health reporting
  on both hosts, not only steady-state traffic to old containers.
- Verify OIDC/TOTP, API access and a newly opened WebSocket before and after one
  controlled restart of the QA Server.
- Retain existing Compose settings, volumes, AppArmor and the previous Server
  rollback container. Company production is outside this change.

Do not infer deployment acceptance from component or Server publication.
Upgrade through the normal platform actions and retain a verified rollback
point until the affected services and workload data have been checked.
