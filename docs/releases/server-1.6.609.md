# Server v1.6.609

## Published identity

Image `ghcr.io/pasturestack/server:v1.6.609@sha256:ac237e999c735e93ad309f7bc57f346b0063cf5fe62e0930e6ff1bbd34f6641c`.
Producer `d10ae647a6f0cb7384c114463993bafb4d77d411`. Required publication checks and final-image scanning
passed. The isolated existing installation completed deployment and one actual
restart, each with startup age at least 180 seconds and continuous readiness of
60 seconds. Original Docker health configuration and restart policy were kept.
Production was not accessed or modified.

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

A real Edge browser loaded the published Web Console 1.6.246 assets and completed
native upgrade/rollback followed by an independent upgrade/finish/refresh.
Compose export and running containers retained one nonempty dependent sidekick
in every phase. Both previous snapshots were nonempty. Primary and secondary
mounted data, configuration, command, labels and shared network namespace were
verified, including settings without LB-form controls. HTTP and verified TLS
1.2/1.3 passed with actual HAProxy 3.4.8 after upgrade. Four native POST actions
returned 202; service PUTs and browser/API errors were zero.

Twelve negative controls reject empty fixtures, missing old secondary, data loss,
wrong namespace or identity, missing TLS, extra PUT, failed actions, stale Server,
missing dependent replacement, unrepresented-label loss and a browser still
showing its loading overlay. Fixture cleanup
retained all existing images and volumes, three Hosts and unrelated Stack states.

This qualifies one dependent-sidekick topology. Existing unaffected Catalog,
Cron, API-dialog, TCP and sticky-session results retain their original version
and limits; they were not replayed or promoted to a whole-matrix PASS.

## Upgrade and recovery

Preserve existing volumes, socket mount, operator environment overrides, HTTPS
origin, AppArmor and restart policy. Retain the previous Server image/container
and a verified database backup. Follow the [upgrade procedure](../upgrades/README.md).
No production deployment is claimed.
