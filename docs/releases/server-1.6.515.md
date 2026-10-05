# Server v1.6.515

Status: source packaging of the published Web component. Server exact-source CI,
immutable image publication and isolated native acceptance remain pending.
No Server515 digest or QA deployment is claimed. The complete functional matrix
remains INCOMPLETE, and historical HOLD results are unchanged.

## Repair

Web Console `1.6.177` prevents ended log and terminal workspace entries from
opening another connection. Late ticket/broker responses, socket callbacks and
timers retain their original entry identity and cannot update a replacement.
Ended terminal input is disabled. Explicitly opening a new entry and reconnecting
a live session remain supported.

API contracts, role permissions, workspace persistence, generation/mutex and MFA
are unchanged. This packages the normal Web release; it is not a runtime patch.

## Published Web component

- Signed source and numeric tag `1.6.177`:
  `b9b841e65afe1d89a5b03ac767e9168bccd3c3ea`.
- Reviewed tree: `109a60fc005d9dc18e38864089dd0055980485c3`.
  Normal PR175 squash merge `5d150806be20226657e5caa8a0150d068006c772`
  has the same tree and a verified signature.
- [Formal CI37255121243](https://github.com/PastureStack/web-console/actions/runs/37255121243):
  841 tests passed, zero failures/todo, including17 new lifecycle regressions;
  both CodeQL checks passed. Two CI archives were byte-identical.
- `web-console-1.6.177.tar.gz`: `2982494` bytes, SHA256
  `4e34eb2b3165f078134cddcf1721239b3da7baf11dd683991b2d6aa5bae944e0`.
  Anonymous HTTP200 download matched those immutable archive bytes.

These observations establish the published Web component, not Server515
artifact/runtime or live UI acceptance.

## Unchanged assembly and rollback

Engine `v0.183.333`, source `0d94f7d879d314235e582a7f4062914a27b82709`,
WAR SHA256 `8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328`
and Catalog Service `0.20.12` remain pinned. All other component/plugin pins,
the Server460 immutable base, four build stages and final one-runtime-layer
publication/config-comparison flow are unchanged.

VEX and vendor-pending declarations change only their Server release identity;
the reviewed CVE statements and exact vendor-pending set are unchanged.
The new artifact still requires its own source, image, runtime and security gates.

Quick Start keeps the published immutable514 reference until515 publication and
readback complete. Preserve514, existing configuration, named volumes and backups
for rollback. Catalog database IDs, including API template IDs, may remap within
an existing refresh transaction; this repair does not change that514 contract.
