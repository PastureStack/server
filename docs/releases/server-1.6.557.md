# Server v1.6.557 candidate

Not published. Install examples continue to use the current published 556 image
until the immutable 557 publication is verified. Deployment acceptance is pending.

## Verified component inputs

- Engine `v0.183.357`, original CI producer `2cd688b0c066658c41e7d3de5bed8c543687f275`,
  merged tag source `6a5230ee2c2e6d4c4aa495035b8de30bb5d64d18`, JAR SHA256 `a46e832314b32292e3423133168020acf93052a7dd29e967bbaabc3df6dca8dc`.
  Required CodeQL and Security run 40926481583 passed: 373 suites, 3,616 tests,
  zero failures/errors and one existing platform-conditional skip.
- Web Console `1.6.199`, producer `80a47df65f6406087b80aa81cfa99fe1f438ecff`,
  archive SHA256 `ab60d4baa10685021b74db09b805dee1f866e9bd0fbccea4d54610df907c7570`.
- Optional stdio bridge `0.2.1`, ZIP SHA256
  `f1477b74da0caefd7fcef77609b55b7d172683bda4afe3ffb884dfdf5a63dfae`.
  Other bundled component pins and live ordinary UI/API paths are unchanged.

## Corrected behavior

Normal validation already decodes resource IDs before internal Key authorization.
The parent resolver now preserves those decoded identities instead of parsing
them a second time. A human-approved create and its original custom-Key receipt
can use the same live scope. Public scope inputs still require exact typed IDs;
foreign IDs, owner ceilings, child DENY and live revision checks remain enforced.

The native process-pool owner supplies a read-only stable bean identity without
changing native display names, null IDs or metrics. AI metadata uses an opaque
identity and a safe fallback display name. Unnamed or duplicate-name pools no
longer break the whole list. The unsupported activeSetting collection is removed
from AI discovery; ordinary settings routes and permissions are unchanged.

The publisher additionally exercises a real scoped-Key preview, human-cookie
confirmation, one empty Stack create and receipt read against its fresh disposable
Server. It checks native pool projection and unsupported-input errors without
Hosts or workloads. This protocol gate does not replace browser acceptance.
No production origin, runtime patch, authentication policy or firewall is changed.

## Acceptance boundary and rollback

Previously unaffected metadata, role and 16 new-modal layout results are retained.
The unfinished 18-pair workflow, remaining read adapters, paired child-DENY control
and weak-model use must be accepted on the designated 8080 installation. This
candidate does not complete every frontend WebMCP workflow. Catalog launch,
advanced forms, other business batches and KVM HOLD remain separately tracked.

Back up the database, preserve named volumes and genuine operator overrides,
and retain the previous image. Keep the three existing opt-in AI properties
and all security, origin and performance settings. No new migration is added.
Before rollback, stop new clients, settle accepted work, cancel unused plans and
revoke temporary Keys. Preserve durable plan receipts and do not replay uncertain
operations. Follow the [Key-policy rollback guide](../upgrades/api-key-policy-rollback.md).
Officially unfixed Medium findings retain their exact package tracking policy;
the release scan must still reject applicable fixed, High/Critical or untracked
findings. Browser SBOM coverage remains explicitly incomplete.
