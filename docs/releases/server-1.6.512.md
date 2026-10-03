# Server v1.6.512

Server512 is published. Its immutable image, official publisher, SBOM/security,
isolated start/restart and anonymous public artifact readback were verified.
The full functional/permission/browser matrix remains incomplete.

## Scope

This release packages Web Console `1.6.174` VM boot-image form safeguards:
fresh VM forms do not use ordinary-container defaults or Ubuntu/Alpine quick picks.
Custom images, initialValue and VM last-used remain available; ordinary-container
defaults and existing required/willSave validation are unchanged.
VM-specific help describes the compatible boot-image `-m`, `-smp` and `/image`
contract and asks users to confirm the image's virtualization requirements,
such as KVM (`/dev/kvm`); it does not introduce a new Engine capability gate.
VM and container required-image messages use existing i18n fallback.
No VM runtime, image allowlist, schema or authorization change is included.

Orchestration Engine stays official `v0.183.333`, source
`0d94f7d879d314235e582a7f4062914a27b82709`, WAR SHA256
`8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`.
Reuse Server460 base
`ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403`,
the four existing build stages and single-runtime-layer flatten/config comparison.
Other component/package pins, OIDC/MFA, environment, persistent volumes,
AppArmor and runtime policy are unchanged.
No migration or runtime patch is required.

## Published components and immutable Server image

- Web174 published signed source: `d24b7f4e164f058e3ef9057347caa2080e2b5407`.
- Published/tested tree: `c408e8b018d99db2ca228203880f4e72663ab1b7`.
- [Official Web CI37152802665](https://github.com/PastureStack/web-console/actions/runs/37152802665):
  817/817 passed; failures, skips and todo are zero.
- [Published numeric tag `1.6.174`](https://github.com/PastureStack/web-console/releases/tag/1.6.174):
  signed immutable tag; formal asset `web-console-1.6.174.tar.gz`.
- Archive: 2982022 bytes; SHA256
  `6408775898f412e4b27092eeddd9cdc2028ad7b27835f489139c2d0cf62c6776`.
  Anonymous public original archive bytes match the exact CI artifact.
  Signed source/tag, same tested tree and immutable publication were verified.
- Server512 source: `c533ac7753d222abb515848effc27d007bd700b6`.
- [Official publisher37153784888](https://github.com/PastureStack/server/actions/runs/37153784888):
  successful first run, including build, flatten, start/restart, security and publication.
- [Immutable release `v1.6.512`](https://github.com/PastureStack/server/releases/tag/v1.6.512):
  23 assets and 22 SHA-256 checks verified by public readback.
- Image: `ghcr.io/pasturestack/server:v1.6.512@sha256:805078de83c0320c751dff90304bd841b8e64bec720079198258d22fa41d0145`.
- Config digest: `sha256:92f363f07a9425096dfba9746e13d2cbbd49ccbaba309950358e1b633583a4c5`.
  Tag and immutable manifest/config bytes, version/revision labels and SBOM identity match.
- Four build stages and one final runtime layer are retained.
- Isolated first start and restart: HTTP200/pong after 12 and 8 probes respectively.
  34 MFA/API checks, TLS1.2/TLS1.3, private no-store and rejection of an untrusted
  TLS certificate passed against this artifact.

Existing source, builder and Docker exact-coordinate/hash gates remain unchanged;
verified artifact checks do not establish full UI/permission/VM lifecycle acceptance.
Historical Server511 evidence is not promoted to Server512 functional acceptance.

## Security and acceptance boundaries

The existing 51 OpenVEX statements, vendor-pending exact-set/severity/fix policy
and `2026-10-20` review deadline are retained without widening exceptions.
Server512's own merged-rootfs scan has 52 raw findings, 51 OpenVEX statements,
8 vendor-pending Medium package findings covering 4 CVEs, and zero Critical/High,
available-fix, untracked or secret findings. This is not a zero-CVE claim.

The current Quick Start pins512. Keep the published
[Server511 release](server-1.6.511.md), its digest and historical scoped/HOLD
receipts unchanged for audit and rollback.
The full permission/resource/locale/layout matrix remains INCOMPLETE;
a published artifact does not promote historical QA evidence.
Publication does not deploy or modify the company site or existing environments.

## Upgrade and rollback

Back up the database and persistent volumes before changing only the image
reference in the existing Compose file. Preserve environment overrides, named
volumes, restart policy, AppArmor and HTTPS origin. No data migration or runtime
patch is required for this Web-only package change. Verify `/ping`, the displayed
Web version and the relevant UI after first start and a restart.

To roll back, restore the previously pinned Server511 image in the same Compose
configuration. Keep the backup and previous image until the new deployment has
passed its own acceptance checks. Do not delete persistent volumes.
