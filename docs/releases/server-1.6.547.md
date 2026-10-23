# Server v1.6.547 candidate

Not published. This patch will retain the v1.6.546 security updates and consume
the newly validated Catalog. Publication and deployment evidence are separate.

## Verified component inputs

- Catalog v0.3.15 source `1d375422e25f83f72840067df97d90b4a5c4f16e`
  adds network-services revision 12 while retaining every older revision.
- Network Plugin Manager v0.8.24 source
  `f34bbca219ddd84b94f4b3f833e04d67b9c8ce03`; verified image manifest
  `sha256:c588d1ad06b1d756a16fd7f16230803c6dee69809ab4367034706325d0080738`.
  Its published source, binary and runtime-image security checks passed.

The unchanged Engine v0.183.354, Web Console 1.6.194, Host API 0.38.8,
Node Agent 0.13.33, authentication service 0.4.46 and other v1.6.546 inputs
retain their exact published bytes and security dispositions. This patch does
not change OIDC, MFA, API Key authorization or the host's firewall backend.

Network Plugin Manager v0.8.24 removes a destructive lifecycle path that
mistook legitimate overlapping Metadata/DNS containers for duplicates. Those
containers belong to the Server orchestration lifecycle, not the network
plugin. The manager now waits for Metadata recovery with bounded requests and
backoff, supports cancellation, and stays unready until both networking
reconcilers succeed. Other local orphan handling is preserved.

The isolated v1.6.546 Catalog upgrade exposed this issue and was rolled back
through the official Stack action. Agent updates and workload data were kept.
That recovery is not acceptance of the new plugin; it must pass a new real
Catalog upgrade, data-preservation, refresh and Server-restart check.

## Upgrade and rollback

Preserve the existing three named volumes, all operator environment variables,
restart policy, AppArmor profile, HTTPS origin and authentication configuration.
Retain the previously accepted Server image and database backup; never use
`docker compose down -v`. Keep existing custom Catalog and agent overrides.

Older Network Plugin Manager releases still contain their original destructive
reaper. Do not assume that a successful Stack API response proves Metadata,
DNS or host-port health. Verify all replacement instances and the actual
network path before completing the upgrade. Existing installations require
the validated migration sequence in the final deployment evidence.

Officially unfixed LOW/MEDIUM CVEs remain tracked with their exact packages and
review dates. HIGH/CRITICAL, available fixes, unregistered findings and secrets
still block publication. This patch does not claim zero vulnerabilities or
Windows-host acceptance.
