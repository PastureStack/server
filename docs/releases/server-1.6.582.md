# Server v1.6.582

## Publication and acceptance boundary

The immutable [Server v1.6.582 release](https://github.com/PastureStack/server/releases/tag/v1.6.582)
was built by [publisher 42362455329](https://github.com/PastureStack/server/actions/runs/42362455329)
from `0620f4de11a916463e9379fac75e8fe8a85ca01e`, tested tree
`acf436649156cc12e49a07502577faf2c234047d`. Its immutable image reference is
`ghcr.io/pasturestack/server:v1.6.582@sha256:773e6166b219729ffa67a0f16ce4e10e493e86669b58fb47a2818d28ca513bc5`. All 35 anonymous public assets,
36 native release-attestation subjects, OCI provenance and SBOM verification passed.
The actual assembled image passed startup/restart and current scan policy: zero
effective Critical/High or available-fix findings, with thirteen tracked no-fix
Medium package occurrences. Source, image and publication checks do not establish
complete frontend or business-workflow acceptance. Matching 8080 native acceptance
remains separately recorded; this release does not authorize production deployment.

## Verified component inputs

This assembly pins published Engine `v0.183.384`, Web Console `1.6.224` and
optional Bridge `0.2.26`. Native roles, current project membership, API Key
operation limits and the four independent default-off settings remain authoritative.
Every proposed write still requires its own human review and approval.

Ordinary Service upgrades can change supported configuration without changing
the image: omitting the image preserves it, an empty ports array clears ports,
health-check objects merge and explicit null clears the health check. The typed
preview records the reviewed configuration before the existing upgrade owner runs.
Builtin-local Volume creation supports a logical, unallocated Volume with only
name and description. It does not allocate a Host disk or mount a workload;
equal display names do not establish resource identity.

Container-log reads use the Container's current LOGS authorization and a bounded,
actor/project-bound private broker request. The Server broker validates the pinned
Host API v0.38.8 three-byte stream prefix (`00 `, `01 ` or `02 `), then streams
application text with at most 200 lines and 64 KiB, under a five-second broker
dial/read deadline. Synchronous authorization/audit work is outside that deadline. It closes the
upstream reader at the limit or cancellation without allocating an entire large
WebSocket message, and preserves valid UTF-8 at the byte boundary. Literal
`[RANLOGS]` in application text is preserved. Logs are untrusted application text
and may still contain application secrets.

The LB image-check correction preserves the exact LB subtype and native-owned
Volume graph while removing a false denial. A stale ordinary-Service link plan
can remain visible in the human inbox for cancellation after its configuration
snapshot changes. That exact stale conflict never authorizes apply: apply still
rejects the stale plan with 409. Current actor, Key revision/revocation, role,
project and resource UUID checks remain required; an arbitrary message code does
not grant a stale-plan exception or expose the captured snapshot.

Engine producer `6ead99132f575b05c564f94882f59088f19e7511` passed 471 suites,
4,216 tests and all 402 required methods, with zero failures/errors and one
inherited skip. Its qualified packaged closure has 71 class roots; cattle.jar
SHA-256 is `fe018cc40af5576ec50d73994cca3e577c860f958216df26cc5966cfd815449a`.
The sixteen serialized role-schema inputs retain the published383 bytes; the
fresh packaged effective typed-role projection was separately qualified.

Web producer `5a378edd498449044320bf720262779f9b84866a` passed all 1,142 browser
Ember tests and 269 distinct focused source cases. Its runtime archive SHA-256 is
`4c33f0e1ab823cdf7315d6859a7ff92133fec3a5c20077fb44cbfadc444abaa4`;
the optional Bridge0.2.26 ZIP SHA-256 is
`fa175480d6f6bca42ed0ab5beb296eb397b8b4df0ca88b0d1545260447b98481`.
The exact immutable component assets have verified cryptographic release
attestations and anonymous-byte readback receipts. These component and focused
source results do not establish complete frontend or native workflow acceptance
for this Server assembly.

The recipe's multistage and flatten steps, proxy, Agent, Host API, Catalog,
Compose, official APT pins and security thresholds remain unchanged. Existing
VEX statements and the 13 package-scoped no-fix finding rows (nine CVE records)
retain their exact scope. The new Server582 merged-rootfs scan and startup/restart
passed in its normal publisher; original raw scans and package-scoped exceptions
remain attached to the immutable release. Anonymous and cryptographic readback
passed separately. Native acceptance is a separate evidence layer and is not
inferred from component CI, image health or publication.

Preserve the operator's mounts, named volumes, restart policy, AppArmor and
firewall configuration. This batch introduces no data migration. Retain the
qualified Server581 image, operator configuration and matching database backup
for rollback; restore the complete assembly rather than swapping live bundles.
