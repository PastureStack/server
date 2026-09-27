# Server v1.6.475

This patch assembles Orchestration Engine `v0.183.325` and Web Console
`1.6.140` on the preserved Server `v1.6.460` runtime base. Other component
versions remain unchanged from `v1.6.474`. It includes no database migration,
OIDC configuration change, HAProxy change, or production deployment.

Orchestration Engine exposes `projectTemplate.isPublic` as a read-only field to
non-admin v1 readers. A non-admin does not receive a misleading remove action
on a public or non-owned template; direct template mutations remain
owner-scoped for non-admin accounts. Web Console shows ProjectTemplate edit and
remove controls only to administrators or when a non-empty template owner
account ID exactly matches the signed-in account ID. A direct edit URL repeats
that ownership check before opening the editor. The UI guard does not replace
Server authorization.

Web Console also prevents a delayed API-key modal focus after rapid Cancel
from targeting a destroyed input. Shared sortable-table controls reflow into
labelled cards at narrow widths; Container and Host Container lists retain
local table scrolling on desktop.

## Immutable component inputs

- Orchestration Engine `v0.183.325`, commit
  `60aabb3b3c95ab2ed62535a49606a287e037f2fe`, `cattle.jar` SHA-256
  `9ce9358d91ff002c0b64a8c1efd037b26f43ccbe11508a1446760f3baffcb564`.
- Web Console `1.6.140`, commit
  `238cdd1638c308baa5052e033c070cf0c7b9a314`, archive SHA-256
  `dacf7353a1e72e933ac883c3e4c5521e12bb9017706475a7d94f2803c5b5b216`.
- Webhook Automation Service remains `0.10.3`; Authentication Service remains
  `0.4.42`. The signed Ubuntu 26.04 curl packages remain
  `8.18.0-1ubuntu2.7`.

The build verifies release asset hashes and contents, component versions,
source records, and the nested Engine jar identities. Publication additionally
requires the isolated boot/restart gate, merged-rootfs security inventory,
source and SBOM identity checks, and image digest readback. The image pipeline
does not establish role-by-role behavior on the existing QA service.

## Clarification of v1.6.474 QA guidance

The `v1.6.474` release note asked QA to check "owner/member write access and
restricted/read-only denial" for Container. That wording was too broad: a role
label alone does not determine whether Container writes are available. The Web
Console uses the authenticated project's effective API schema methods for
Container write controls. For each QA account and project, record those
methods, then check that the visible controls, direct routes, and actual API
write results agree with the effective capabilities. Include restricted and
read-only accounts in the matrix without presuming their Container write
outcome. This clarification does not change the immutable `v1.6.474` artifact.

## QA and deployment boundary

The ProjectTemplate matrix must cover administrator, exact owner, different
owner, public, and private templates across list controls, direct edit URLs,
schema action links, and actual API mutation results. Check the API-key modal
rapid-Cancel case and the Container/Host Container sortable-table layout at
desktop and 375px in English and Traditional Chinese. Keep untested rows
explicit. Publication does not deploy QA or `stack.ascdc.tw`.

## Upgrade and rollback

After publication, replace only the Server image reference with the immutable
numeric tag `ghcr.io/pasturestack/server:v1.6.475` and its verified digest.
Keep the existing Compose environment variables, named volumes, restart
policy, AppArmor, HTTPS origin, OIDC, performance settings, and firewall
backend. Rollback selects the preserved `v1.6.474` image with the same
configuration and volumes; do not overwrite its tag or digest.
