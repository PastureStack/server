# Server v1.6.609 candidate

## Candidate boundary

Web Console 1.6.246 is published. Exact Server publication, deployment and the
nonempty-secondary browser lifecycle remain required for this candidate.

## Verified component inputs

Web Console **1.6.246**, producer `e59bfb76e90a0da24508ec447637d6cf87f8abf8`.
Archive SHA-256: `43fbf48ac556d9f798aed6d8f132c4f1fd5f906c561efd7d4dbd4a4ac2576eec`.
The LB editor waits for user, scale and scheduling label sections before merging
them into the shared launch configuration. This preserves existing labels while
child editors initialize; intentional label removal remains supported. System
labels without an LB-form control are retained; editable labels remain removable.

The focused 21-case validation, required CodeQL, original artifact provenance,
runtime SBOM attestation and two reproducible builds passed before publication.
The existing enabled build ceiling and initially-off page behavior are retained.
Native secondary authorization and direct-field visibility are unchanged.

Engine **0.183.395**, API Explorer **1.1.22**, Catalog **0.20.20**, Agent **1.2.36**,
managed LB **0.9.35** and the reviewed Catalog pin retain their identities.
The publication log records the exact exported rootfs byte count so deployment
capacity can be budgeted from this immutable artifact rather than a guessed size.

## Acceptance boundary

The isolated nonempty fixture is provisioned through the supported native
upgrade strategy. Its Compose export, previous upgrade strategy and actual
dependent sidekick must be checked through UI upgrade/rollback and a separate
upgrade/finish transaction. Empty lists do not qualify that test. Existing
unaffected source, Catalog, Cron, API-dialog and scoped LB evidence keeps its
original version and limits; it is not replayed or promoted to a whole-matrix PASS.

## Upgrade and recovery

Preserve existing volumes, socket mount, operator environment overrides, HTTPS
origin, AppArmor and restart policy. Retain the previous Server image/container
and a verified database backup. Follow the [upgrade procedure](../upgrades/README.md).
No production deployment is claimed by this source candidate.
