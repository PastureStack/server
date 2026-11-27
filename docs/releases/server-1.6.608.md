# Server v1.6.608

## Published identity

Image `ghcr.io/pasturestack/server:v1.6.608@sha256:40b5e3c43a5a05453d11eea16086201fc80f9ae496ddf0fb5e79fa84860dcad7`.
Producer `ba81e2c04c0fbc3c2ffbba8e6a51eed892cb80da`. The exact publication workflow passed required checks.
The isolated existing installation completed deployment and one real restart;
each observed startup was at least 180 seconds old with 60 seconds of continuous
readiness. Production was not accessed or modified.

## Verified component inputs

API Explorer **1.1.22**, producer `f84aad3e40f4a364aab42273e46767f756fb551f`.
Archive SHA-256: `31564c3409313b7f5ce95486f6445f099646957f7c984de3f045245884e5c5f0`.
The shared native request editor uses a label/type rail, inset NULL/expand
controls, accessible action order, a stable footer and responsive body scroll.
Exact values, masking, schema fields and request behavior remain preserved.
Both supported locales, four widths and complex input/error states passed in
real Edge against JavaScript/CSS/font bytes identical to the published archive.
Required CodeQL, 19 product/security tests, two byte-identical builds, SBOM and
source/product High/Critical/secret checks passed.

Web Console **1.6.243**, Engine **0.183.395**, Catalog **0.20.20**, Agent **1.2.36**,
managed LB **0.9.35** and the reviewed Catalog pin remain unchanged. Official
Ubuntu 26.04 package locks and security classifications from 1.6.607 are retained.
This patch changes no backend authorization, OIDC, firewall or workload settings.

## Acceptance boundaries

The deployed browser loaded JavaScript/CSS matching the published Explorer
archive. Both supported locales at 1440, 802, 390 and 320 pixels passed expansion,
preview and cancel with no writes, overflow, browser errors or API failures.
The deployed Server restart and three existing Hosts passed; original mounts,
environment overrides, AppArmor and actual restart policy were preserved.
The previous Server container/image and verified database backup remain retained. Existing
unchanged Cron, Catalog history and scoped LB UI evidence retains its original
scope. An empty secondary list does not qualify non-empty secondary behavior;
arbitrary historical downgrades and all module collectors remain unqualified.

## Upgrade and recovery

Preserve all three named volumes, socket mount, operator environment overrides,
HTTPS origin, AppArmor and the existing restart policy. Keep the previous Server
image/container and a verified database backup. Use the existing
[upgrade and recovery procedure](../upgrades/README.md); never create empty
replacement volumes or change workload configuration to deploy this UI patch.
