# Server v1.6.607 published

## Published identity

Image `ghcr.io/pasturestack/server:v1.6.607@sha256:970746b4d90bed79445496b3cfa02dabb1b0028579d8570b2ffc558c2b34e09a`.
Producer `50bd4d024d8fd6d004e7e983f33d4bfb1687d2a8`.
[Publication](https://github.com/PastureStack/server/actions/runs/46016767923)
passed. Isolated deployment, actual restart and affected UI checks passed with
the explicit scopes below. Production was not accessed.

## Verified component inputs

API Explorer 1.1.21 producer: `5ad80b6851b3162bf89522ea9f45c4975fbb2c47`.
Archive SHA-256: `32f1e104434347e58a4ed6935741ab8c7d96c91c0b1a9b112bb792a3bc5ecafd`.
The exact producer passed required CodeQL, 19 product/security tests, two
byte-identical builds, SBOM generation, npm audit and source/product scans.
The scanned source and product reported zero Critical/High findings and secrets.

Request controls follow the available column width. Narrow dialogs stack values
below labels. Long forms scroll within the body while footer actions remain
accessible. Expanded text follows the same sizing. Password values retain their
exact content instead of absorbing malformed placeholder markup.

Web Console 1.6.243 producer: `af9b70dc1ecf4365ceb58c406821b6620c0c9482`.
Archive SHA-256: `6ffdfb01d370b991a2b21350faff5172e134a5aa818d7f120166713469a36135`.
Its 16 affected component/adjacent-route tests pass. Image-only LB upgrades no
longer send a metadata PUT just because the form materializes an absent sticky
policy name as null. Real edits and explicit name clearing still persist.
The merged source has verified reproducible artifacts, SBOMs and attestations.

Engine 0.183.395, Catalog Service 0.20.20, Agent 1.2.36,
Catalog pin `8c1c28318580d5ec18c14a13b224ce0e02e40bf8` and LB Service 0.9.35
retain their existing component identities. This patch does not change backend
API authorization, OIDC, firewall behavior or existing workload configuration.

## Acceptance boundaries

Local real Edge rendering covered both explorer locales at 1440, 802, 390 and
320 CSS pixels, create/edit/action forms, expansion, preview/cancel, map/array
fields and permission errors. These isolated fixtures are not deployed-QA or
production evidence. Unrelated existing PASS results retain their original scope.

## Official Ubuntu security updates

The first candidate was held by the unchanged security gate because Canonical
released fixes for 29 Expat/Kerberos CVEs after the previous Server release.
The revised candidate installs the five existing binary packages at their
official patched versions, using a separately signed 2026-11-27 snapshot and
offline package-set-preserving installation. Previous exact locks retain their
reviewed snapshots. The Expat runtime-surface removal remains enforced.
See [package identities and validation](../security/ubuntu-20261127.md).

Three additional no-fix Medium findings retain exact tracking and current
Canonical evidence; no High/Critical or fixable-finding exception is introduced.
The revised final merged-runtime scan passed before publication. The five
patched package versions, native links and verified TLS were read back from
the deployed image. Raw findings and no-fix tracking retain their boundaries.

## Subsequent isolated acceptance

Four Explorer viewport widths verified shipped assets, expansion, preview and
cancel with no writes, browser errors or HTTP failures. Native LB UI actions
were upgrade, rollback, upgrade and finish, with HTTP/strict TLS/TCP/sticky
checks through refresh. No service PUT occurred. The secondary fixture was
empty, so non-empty secondary preservation remains unqualified. Original Cron
0.5.0 migration and 22-template historical UI selection are separately scoped
1.6.606 results. Three existing Hosts remained active.

## Upgrade and recovery

Preserve all three named volumes, the Docker socket mount, environment overrides,
HTTPS origin, AppArmor and restart policy. Keep the previous Server image/container
and a verified database backup. Updating this Server does not independently
upgrade any running system Stack or managed LB.
