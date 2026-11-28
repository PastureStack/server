# Server v1.6.609 candidate

## Candidate boundary

Web Console 1.6.244 is published. Exact Server publication, deployment and the
nonempty-secondary browser lifecycle remain required for this candidate.

## Verified component input

Web Console **1.6.244**, producer `ccd1fb7bccfc9e4d5b17c03f0812272ab5ed638d`.
Archive SHA-256: `9d4c83a86ca92209bf8dc50e37df4a539f775e37ad87d9d553963aec53bf2d77`.
The LB editor waits for user, scale and scheduling label sections before merging
them into the shared launch configuration. This preserves existing labels while
child editors initialize; intentional label removal remains supported.

The focused 20-case validation, required CodeQL, original artifact provenance,
runtime SBOM attestation and two reproducible builds passed before publication.
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
