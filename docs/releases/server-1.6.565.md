# Server v1.6.565 candidate

Source candidate. The publisher adds the actual image identity only after its
required checks pass; deployment acceptance is recorded separately.

## Verified component inputs

This release consumes original published
Engine v0.183.366, Web Console 1.6.205 / optional Bridge0.2.7 and Compose0.14.41;
Catalog0.20.17 and other runtime components remain unchanged.

Service create supports typed native ports and a closed health-check subset.
Creation remains stopped; start is separately reviewed. Verified completion
reports actual assigned ports without altering the approved intent. Native
role/Key limits, current revision, explicit DENY and exactly-once claims remain.

Catalog's Compose producer excludes typed API response envelopes from mutation
requests and sends explicit empty service links. Engine projection preserves
the real transformer's image/environment/ports/log settings through the current
role schema; hidden and create-only values remain restricted. The audit gateway
forwards only the successful Engine response's authenticated actor metadata;
incoming forged identity headers and response-body fields cannot supply it.

Published producers: Engine `3ce114486954403cead091379916c2d69c052336`, Web `931562ac0302b0406c5c2b44ec7a0f94307e5b2e`,
Compose `ed3dbddda8a04522e6969fef12672bfb30f3d180`. Source component CI and exact original artifact
qualification are separate from designated QA runtime acceptance.

| Published component | Original artifact SHA256 |
|---|---|
| Engine v0.183.366 cattle.jar | `0fd51b38c22c495d5f245527213807fa486e3bba571756b410ef6292f424db81` |
| Web Console 1.6.205 archive | `5e33c9e2c71965552fb1e7c66c2c3f3c19b85fc6e4a74bd64c20c8dd51f57620` |
| Optional Bridge 0.2.7 ZIP | `3b7124d239b3f2b8c2a62775aded1e819953dce7a19471b0f3ac5c00587e20ad` |
| Compose 0.14.41 archive | `a9f489651e1457beaf0e27e04d578ca4d0f66dd60998faa539a20f4da55b19d0` |

Engine original CI ran 3,912 cases with zero failures/errors and one existing
skip. Its 21 new methods are distinct from inherited coverage. Web original CI
passed 1,122 Ember cases and 12 new source cases. All 12 Engine, 13 Web and 20
Compose public assets passed anonymous checksum/length readback. Web archive
provenance and runtime-SBOM attestations passed. Compose's 99 additional
build-only Medium findings have no official fix and remain individually tracked;
the safety policy is unchanged. These are not claims of zero vulnerabilities
or completed runtime acceptance.
No production site, HAProxy, firewall or database setting changes are included.

The four AI opt-ins remain independently default-off. Existing Compose
environment variables, named volumes and restart/security settings are retained.
Back up data and preserve the prior Server image/configuration before upgrade;
rollback uses that exact retained image and compatible data. Never remove volumes.

The publisher records Server checks, immutable image identity and original
component inputs. QA8080 Audit remainder, Catalog launch/archive/restore and
new Service-field/weak-model evidence are recorded separately. Existing
unaffected PASS and original failures are retained; component or release
checks do not establish acceptance of all 243 frontend groups.
