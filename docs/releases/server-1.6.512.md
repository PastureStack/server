# Server v1.6.512

Server512 candidate only. Web174 exact CI and immutable publication/archive
readback are verified; Server512 build/publication/runtime/security and QA
acceptance remain pending.
No Server512 image digest or PASS is claimed.

## Scope

This candidate packages Web Console `1.6.174` VM boot-image form safeguards:
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

## Verified Web174 component; Server512 artifact pending

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
- Independent publication receipt SHA256:
  `aa79ea915bb8d6de4542b1095c35e39479af4d6c24e7b7d9cd2e28ffbf08f603`.
  Local release workspace evidence, not a public asset:
  `.release-evidence/web-console-v174-signed-merge-readonly/published-readback/publication-readback.json`.
- Server512 source, publisher run and immutable image digest pending.

Existing source, builder and Docker exact-coordinate/hash gates remain unchanged;
verified Web component pins do not establish Server512 build/runtime/QA PASS.
Do not use the Server511 digest as Server512 publication evidence.

## Security and acceptance boundaries

The existing 51 OpenVEX statements, vendor-pending exact-set/severity/fix policy
and `2026-10-20` review deadline are retained without widening exceptions.
Server511's 52 raw findings are historical scan evidence, not a Server512 scan.
Server512 SBOM, merged-rootfs scan, licenses, first-start/restart, MFA/API/TLS,
public artifact readback and QA results must come from its own exact artifact.
This is not a zero-CVE claim.

Keep the published [Server511 release](server-1.6.511.md), its verified digest,
Quick Start and historical scoped/HOLD receipts unchanged.
The full permission/resource/locale/layout matrix remains INCOMPLETE;
a packaging candidate does not promote historical QA evidence.
Publication does not deploy or modify the company site or existing environments.
