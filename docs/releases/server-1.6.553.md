# Server v1.6.553

Published image: `ghcr.io/pasturestack/server:v1.6.553@sha256:daf2562134dcd735a265f531f2e7fdf0a3aca762062566e4406c35ba7ce81101`.

Source commit: `b0c121abf9a812f83204ee93bb28ee7046815021`.

The release workflow passed its source, security, startup and restart checks before publishing this image. Deployment-specific acceptance is separate and is not claimed by these build results.

## Verified component inputs

CVE-2026-111497 affects the Brotli decoder. The accepted Google fix is applied
to the pinned Ubuntu source without replacing Ubuntu packaging or adding
packages to the runtime. The qualified shared bundle binds the official patch,
native owning tests, ordinary compression/streaming tests, three-library ABI,
package bytes, consumer installation receipts and exact-package OpenVEX.

Web Console `1.6.195`, Engine `v0.183.354`, Host API `0.38.8`, Temurin
`25.0.5+8` and their application behavior are retained. Node Agent `v1.2.34`
uses published compatibility base `v0.3.8`. Catalog `v0.3.18`, source
`00eec89e5fdeb9728c1c41babccad8b7dfc8b297`, references the separately published
qualified component images. Node.js
build SDK checks are separate from the static web runtime artifacts.

## Upgrade and rollback

Back up the database and all three named volumes. Preserve the existing Compose
environment, HTTPS origin, ports, AppArmor, mounts and restart policy. After
publication use the numeric `ghcr.io/pasturestack/server:v1.6.553` tag, then
upgrade existing infrastructure Stacks and Host Agents normally. A new Server
default does not override an explicit database setting.

Keep the preceding immutable images and matching data checkpoint. Do not run
`docker compose down -v` or retain an old runtime web-bundle override. A rollback
may require restoring the matching database and volumes; never restore over
the only copy of current data.

## Acceptance boundary

Only affected package installation, linkage, startup/restart and system-service
functions require new evidence. Unchanged UI, language, RBAC and session tests
retain their earlier results. Runtime adoption must identify the actual
container digest on each eligible Host; registry publication alone is not
deployment acceptance. Production, HAProxy and host firewall configuration are
outside this QA deployment.

## Independent publication readback

[Publisher run 40182084293](https://github.com/PastureStack/server/actions/runs/40182084293)
completed successfully. All 35 anonymous release assets matched the producer's
SHA256SUMS and GitHub asset digests. Anonymous tag/manifest/config readback and
both native OCI provenance and CycloneDX attestations matched the exact producer
and manifest above. The distinct OCI config is
`sha256:bf7147449c0e9e029579b6ae708abd7506d4dfccf5ca7c7966474f254aa4afb9`.
The published release-note body above is retained unchanged; later documentation
commits do not become the image producer.

The final image verified seven already-installed backport packages, including
`libbrotli1 1.2.0-3build1+pasturestack.1`, with ordinary compression and linkage
controls. Package/provider/configuration preservation and consumer receipts
passed. The raw scan retains 51 finding occurrences; the qualified effective
report retains 10 occurrences across nine officially unfixed CVEs. Available
fixes, unreviewed findings, Critical/High findings and secrets remain blocking.
The existing browser runtime SBOM retains its original identity and incomplete
coverage; no complete-browser-coverage claim or new browser attestation is added.

## Scoped QA8080 Server deployment

The isolated QA8080 deployment adopted this exact published image and source.
Cutover, independent identity/configuration verification, ordinary Brotli runtime
control, strict TLS (`200 ssl_verify_result=0`), one Server restart and a second
identity/configuration verification passed. The existing environment, mounts,
AppArmor, restart policy and three data volumes were preserved.

The active Server container is `99afac6647e1`; the preceding Server552 container
`b7be489f6085` is retained as
`pasturestack-server-v1.6.552-rollback-553-20261025`, with the original image and
matching data checkpoint preserved. All three Hosts and Agents were active.
The separate Agent `v1.2.34` adoption receipts passed 15 checks on each Host;
these are not a new application/UI/role matrix.

The retained local QA receipts below are separate from the publisher's public
release assets. They bind the Server-only deployment scope; production,
HAProxy, host firewall changes and broader role/UI acceptance are outside it.

| QA receipt | SHA-256 |
| --- | --- |
| `server553-qa-cutover.json` | `fdf8c3c889c7c2f73da86b47533a6275cc002bd7241264df22fa1a9f3f19c6e6` |
| `server553-qa-verify.json` | `ec920d6d7ff0108e12017b465c542de36e2891376fa58eb3e5ef69e495791d32` |
| `server553-qa-smoke.json` | `5bd94dc1d72527dd50770f5d62928198204f85766415fb88f2cfd9029a692920` |
| `server553-qa-restart.json` | `c61d4fe0d30f9a18a8eb53d38a22fcec158a5e7908eed4ac6f9ef106004c2d4b` |
| `server553-qa-verify-after-restart.json` | `863b25498bdbd778f0252ed3b574752e99f8b5e56334d39bd3542b1374b033d1` |

## System Stack adoption

The security refresh has accepted ten affected Stacks: the two independently
completed `network-policy-manager` and `secret-volume-driver` adoptions retain
their original PASS receipts, and the eight Brotli-target Stacks completed
normal Catalog upgrades and `finishupgrade` across Default and the isolated
single-Host project. Those eight final receipts report PASS for complete named
primary/sidekick configuration, exact runtime artifact/producer and Host-role
coverage, rollback retention and post-finish checks. They are active.

One Default bidirectional probe passed cross-Host IPsec SA/packet-delta, DNS and
strict TLS/egress checks. One isolated `1h19` managed namespace passed DNS,
Metadata and strict TLS/egress checks; it makes no cross-Host claim. The common
`runtime553-functional-group.json` receipt has SHA-256
`7ec2af7ca38ee98d783a0d8c6ea94a397951f664f71204dcd7bf0fc2aa571ac0`
and binds all eight current service/launch/instance/artifact sets. Each Stack's
separate `runtime553-<stackId>-stack-final.json` records the final completion.

The normal replacements and recorded healthy states provide the affected
scheduler/health-reporting evidence; no additional test Stacks were created.
Before and after the project probes, the existing `qa545upgrade` tenant
container IDs, images, volume mounts and data-marker hashes matched the retained
Agent snapshots on all three Hosts. Full private checkpoints and previous
images remain available for rollback.

The three Agent `v1.2.34` adoptions retain their 15-check per-Host PASS receipts.
The other two unchanged NFS/diagnostics Stacks carry forward their health
readbacks without new owning-function runs. This acceptance is limited to the
CVE refresh; role, UI, language and other unaffected evidence is retained and
was not rerun or promoted to a new full-matrix PASS.
