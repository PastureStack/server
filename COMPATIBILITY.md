# Compatibility Contract

## Server v1.6.559 source candidate

Not yet published. README/install examples remain on verified published 558.
The candidate uses Web Console 1.6.200/optional bridge 0.2.2, Engine 0.183.359,
Catalog 0.20.17 and Compose 0.14.40 from qualified original CI/public bytes.
See the [candidate note](docs/releases/server-1.6.559.md) for exact source,
archive/binary/SBOM/lock identities and four independent opt-ins.
The candidate prefers the official Ubuntu Brotli safety package; exact final
rootfs/SBOM validation preserves the immutable earlier bundle proof and all other
package checks. No new VEX exemption or weaker scan threshold is introduced.
Core200, Catalog/Archive, affected roles/layouts/weak-model checks, three
Hosts/Agents and an actual restart remain pending. Existing performance,
origin, volume and rollback rules remain; this is not full frontend coverage.


<a id="server-v16558-managed-retirement-and-search"></a>

## Server v1.6.558 published

Published image: `ghcr.io/pasturestack/server:v1.6.558@sha256:c49c4bb1f7bcee2ae0299f196a8332657967fa2ed4e3a3496854f5bca89ec42b`.
Runtime producer: `33f6056476ee29eb18aa9185e59b4cb3e86c5960`; OCI config:
`sha256:e9d3df5989c64f947150025935fc970f49289175d1337f21f6360f31bd5db025`.
[Publisher 40941691098](https://github.com/PastureStack/server/actions/runs/40941691098)
passed all original source/build, startup/restart, protocol and security gates.
All 35 public assets passed anonymous SHA256/size readback; native provenance and
CycloneDX attestations passed. Documentation commits do not change this producer.
The exact package policy retains ten Medium occurrences across nine officially
unfixed CVEs; applicable fixed, High/Critical, untracked and secrets gates passed.
Browser SBOM coverage remains incomplete.

Web Console 1.6.199 and bridge 0.2.1 remain unchanged. Engine 0.183.358 consumes
original CI producer `1da1f4c37fe43b8c387045c263d286f7db01c574`, JAR SHA256
`46ad548c6e284a7758eb7f65c85fb5878e2ebdc861ef5c396a00a6510709b733`.
Its required CI passed 374 suites / 3,631 tests, zero failures/errors and one
existing conditional skip. Ordinary Full/legacy paths are unchanged.

Designated 8080 upgrade and actual restart preserve operator settings, mounts,
AppArmor and three active Hosts/Agents. Scoped downscale, Service restart and
Stack stop/start passed. The full workflow remains failed at individual Service
stop: the Service is inactive but its container's stop is authorization-denied.
Five real weak-model cases passed with a separately documented strict oracle
correction; old failures and unaffected evidence are retained. See the
[release boundaries](docs/releases/server-1.6.558.md). Catalog/Archive are not
included; remaining frontend workflows and KVM HOLD are separately tracked.

<a id="server-v16557-typed-read-fixes"></a>

## Server v1.6.557 published

Published image: `ghcr.io/pasturestack/server:v1.6.557@sha256:801bb93400d6a225952be167a12454023816b725a28ad9770efa4689b12ba2ff`.
Runtime producer: `9783aacf2b378f39e9dc00469156a57f9eb2e265`; OCI config: `sha256:6e65466bdb73c82ce4bc5c006363ea78f2bf80bcf92c7b729e3f2141e454f4fe`.
[Publisher 40929617683](https://github.com/PastureStack/server/actions/runs/40929617683)
passed source, build, real disposable scoped-Key protocol, startup/restart and
security checks. All 35 public assets passed anonymous byte/SHA256 readback;
native OCI provenance and CycloneDX attestations passed. Documentation commits
do not change this producer. The existing exact package policy retains ten
Medium occurrences across nine officially unfixed CVEs; High/Critical,
available-fix, untracked and source-secret gates passed. Browser SBOM coverage
remains incomplete. Designated 8080 browser/workload acceptance is separate.

Web Console 1.6.199 and bridge 0.2.1 are unchanged. Engine 0.183.357 uses original
CI producer `2cd688b0c066658c41e7d3de5bed8c543687f275` and JAR SHA256
`a46e832314b32292e3423133168020acf93052a7dd29e967bbaabc3df6dca8dc`.
It fixes decoded internal scope reads and native process-pool identities while
preserving public typed IDs, live owner ceilings, child DENY and ordinary Full
access. [Release boundaries and rollback](docs/releases/server-1.6.557.md) keep
unfinished full forms, Catalog launch, other batches and KVM HOLD explicit.

<a id="server-v16556-typed-resource-flows"></a>

## Server v1.6.556 published

Published image: `ghcr.io/pasturestack/server:v1.6.556@sha256:31502d8c873c6997682d8c74cd8b1db9ea80b7b74c1c0e8d8e438931185e8316`.
Runtime producer: `66387f309157fcc64a17e141956eb632a8fcd570`; OCI config: `sha256:60eece627652999f89ce619f934025b3fcf4def4db347adbace87c7992ffa0c9`.
[Publisher 40918679041](https://github.com/PastureStack/server/actions/runs/40918679041)
passed source, build, startup/restart and existing security gates. All 35 public
assets passed anonymous SHA-256 readback; native provenance and CycloneDX
attestations passed. Later documentation commits do not change this runtime producer.
The effective scan retains ten Medium occurrences across nine officially unfixed
CVEs under the unchanged exact package policy; High/Critical, available-fix,
untracked and secrets counts are zero. Browser SBOM coverage is still incomplete.
Designated QA startup/restart and affected role/layout checks passed separately;
new metadata and typed-operation completion findings remain open. See the
[release note](docs/releases/server-1.6.556.md) for the exact acceptance boundary.


Server v1.6.556 consumes Web Console 1.6.199 (producer
`80a47df65f6406087b80aa81cfa99fe1f438ecff`) and Engine 0.183.356 (producer
`24cfa1db113f54de3148cd4ac3191e66a1702806`), retaining the other pinned components.
The matching optional stdio bridge is 0.2.1. Source and release assets record
immutable hashes and the same-tree merged identities. Assembly and 8080 runtime
acceptance remain separate evidence; previous PASS is carried only where unaffected.

The bridge and upgrade properties remain independent of the new opt-in
`api.ai.resource.change.enabled` property. Basic Stack, Service and Container
plans use live owner/Key permissions and human review. Global Services reject
manual scale counts; Stack start/stop preflights its affected children. Advanced
form fields, Catalog launching and other workflows remain pending adapters.
Keep ordinary UI/API paths and use the [AI guide](docs/ai-collaboration.md) for
activation, known boundaries and safe downgrade preparation.

<a id="server-v16555-webmcp-actor"></a>

## Server v1.6.555 published

The published linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.555@sha256:59b2335d31c705184a155d21d89ee3be99b71b841d2b674b5d6c4ba656c730cc`,
produced from `db04a4710c4d7019913610afbdd912245dc488d1` in successful
[publisher 40868492262](https://github.com/PastureStack/server/actions/runs/40868492262).
Its distinct OCI config is
`sha256:2ee478ba85bd70d89ed2457bfbc3181e732454d5fcc6ac35df0f3aac2b27e5af`.
All 35 public assets passed anonymous byte/checksum readback. Native provenance
and CycloneDX attestations bind this image, source and publication workflow.
Documentation commits do not change the runtime producer.

Web Console `1.6.197` restores the authenticated actor after a fresh-cookie
browser session resumes, allowing the human upgrade-plan inbox to load.
Separate human confirmation, Engine `v0.183.355`, role/Key permissions and other
component inputs remain unchanged. See the [release note](docs/releases/server-1.6.555.md).

The raw runtime scan retains 52 findings; ten Medium package occurrences across
nine officially unfixed CVEs remain tracked for review by November 5, 2026.
Untracked, High/Critical, available-fix and secret counts are zero under the
existing policy. The browser runtime SBOM retains its incomplete coverage.
Scoped 8080 deployment, the complete seven-tool flow and random-marker
persistence across upgrade and restart remain pending.

<a id="server-v16554-webmcp"></a>

## Server v1.6.554 published

The published linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.554@sha256:8fa087166970ca3670ad4a19b5b90a313041adb503f1a4be9d459e65bc8248a1`,
produced from `25f5f40f852d7c0cb97b8776bd832d6fce3a89e5` in successful
[publisher 40862854807](https://github.com/PastureStack/server/actions/runs/40862854807).
Its distinct OCI config is
`sha256:249e90384126e9dea1f4d150eb4aeb5be66696f73339c655c7931891b8a0a6ad`.
All 35 public assets passed anonymous byte/checksum readback; image provenance
and CycloneDX attestations match this exact digest, source and publication workflow.
Documentation commits do not change the runtime producer.

The release integrates Web Console `1.6.196` and Engine `v0.183.355`.
The build verifies the browser's enabled capability ceiling and off initial
mode against the exact archive. Backend activation remains explicit.
Seven typed tools share current RBAC and per-Key policy checks; service-upgrade
plans require separate authenticated human approval. No general action proxy
or approval tool is exposed. See the [release note](docs/releases/server-1.6.554.md)
and [AI collaboration guide](docs/ai-collaboration.md).

The raw runtime report retains 52 findings. The qualified effective report
retains ten Medium package occurrences across nine officially unfixed CVEs,
reviewed again by November 5, 2026. Untracked, High/Critical, available-fix and
secret counts are zero under the existing release policy. The browser runtime
SBOM retains its explicitly incomplete coverage.
Scoped 8080 deployment, the full seven-tool flow and random-marker persistence
across upgrade and restart remain pending; publication does not establish those results.
The fresh-cookie UI restore can leave the authenticated account identity unset
and block the human inbox. This product issue motivates the separate Server555
candidate; it does not invalidate the recorded Server554 publication evidence.

<a id="server-v16553-brotli"></a>

## Server v1.6.553 published

The published linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.553@sha256:daf2562134dcd735a265f531f2e7fdf0a3aca762062566e4406c35ba7ce81101`,
produced from `b0c121abf9a812f83204ee93bb28ee7046815021` in successful
[run 40182084293](https://github.com/PastureStack/server/actions/runs/40182084293).
Its distinct OCI config is
`sha256:bf7147449c0e9e029579b6ae708abd7506d4dfccf5ca7c7966474f254aa4afb9`.
All 35 anonymous release assets matched their producer checksums; native OCI
provenance and CycloneDX attestations matched this exact image and source.
Documentation commits do not change the runtime producer.

The qualified build-only Ubuntu backport bundle applies the accepted Google
Brotli decoder fix for CVE-2026-111497. The final image verified
`libbrotli1 1.2.0-3build1+pasturestack.1` through an ordinary compression and
linkage control. Its seven selected existing packages are `libbrotli1`,
`libc-bin`, `libc-gconv-modules-extra`, `libc6`, `libp11-kit0`, `libpcre2-8-0`
and `libpcre2-posix3`. Package ownership, ABI, configuration and the original
package set/provider are preserved. These are PastureStack downstream rebuilds
of pinned Ubuntu sources, not packages issued by Canonical.

The release pins published Catalog `v0.3.18` source
`00eec89e5fdeb9728c1c41babccad8b7dfc8b297` and Node Agent `v1.2.34`, based on
compatibility base `v0.3.8`. Their immutable publication identities remain
separate. Web Console `1.6.195`, Engine `v0.183.354`, Host API `0.38.8` and
Temurin `25.0.5+8` retain their verified inputs and application behavior.

The full raw report retains 51 finding occurrences; the qualified effective
report retains 10 occurrences across nine officially unfixed CVEs. Critical,
High, available-fix and secret counts are zero under the existing release
policy. Exact-package code-absence decisions do not exempt the entire image.
The original browser runtime SBOM and its incomplete coverage are retained;
this release does not claim a new browser attestation or complete coverage.

Scoped QA8080 cutover, actual Brotli runtime control, strict TLS, one Server
restart and post-restart verification passed. Environment, mounts, AppArmor,
restart policy and the three existing data volumes were preserved. All three
Hosts/Agents are active; Agent `v1.2.34` has its separate per-Host acceptance
receipts. The Server552 rollback remains retained. Eight-Stack functional
and normal finish-upgrade acceptance passed separately across both projects.
Together with the two previously completed independent Stack adoptions, the
security-refresh scope has ten accepted affected Stacks and three Node Agent
`v1.2.34` adoptions. The two unchanged NFS/diagnostics Stacks retain their health readbacks
without new owning-function tests. Existing tenant container IDs, mounts and
marker hashes were preserved; rollback checkpoints and old images remain.
Role, UI and language evidence is carried forward, not rerun for this CVE refresh.

Keep the existing environment, authentication, firewall backend, mounts,
volumes and restart policy. Infrastructure Stacks and Host Agents adopt new
images only through their normal upgrade lifecycle; changing Server defaults
does not override an operator's existing database settings.
See the [release note](docs/releases/server-1.6.553.md) for publication and
scoped deployment evidence. Production, HAProxy and host firewall configuration
were not changed by this QA deployment.

<a id="server-v16552-runtime-backports"></a>

## Server v1.6.552 published

The published linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.552@sha256:f19a0fdd7340fde910c8eb66311bbe11d682301f5fe2df7768638b866e5ef1f4`,
produced from `6be16e0c62473e65e4222e144fba513d61717f34` in successful
[run 40149543657](https://github.com/PastureStack/server/actions/runs/40149543657).
Its source, startup, restart, raw/qualified vulnerability scans and SBOM gates
passed before publication. Anonymous asset and registry identity readback and
both native image attestations were verified against this exact producer.

The 8080 test deployment retained its settings, three data volumes, socket
bind, AppArmor and restart policy. Package checks, MariaDB regex controls,
one restart and all three Host/Agent states passed. The 551 rollback remains
available. Production, HAProxy and host firewall configuration were not changed.

The digest-pinned, build-only Ubuntu backport bundle installs only existing
packages. It retains the original package set, selected coreutils provider and
configuration. The Python compiler keeps its original inputs; the final runtime
uses the qualified library packages. Source/native-test qualification and actual
installation receipts are retained under
`/usr/share/pasturestack/security/ubuntu-backports/`. These downstream Debian
packages apply accepted upstream fixes to pinned Ubuntu sources; they are not
packages issued by Canonical.

Node Agent `v1.2.33` pins base `v0.3.7`. Catalog `v0.3.17` records the component
producer commits, image digests, SBOMs and scan evidence. Existing environments
retain their configuration and require the normal infrastructure-stack upgrade
flow to adopt new Catalog revisions. No host firewall backend is selected or
changed by the runtime library installer.

Available fixes and unreviewed findings block publication. Officially unfixed
Low/Medium findings remain registered; exact-package code-absence decisions
require separate source, package and native-scanner evidence. The original raw
report is retained. See the [release note](docs/releases/server-1.6.552.md).

<a id="server-v16551-release-assets"></a>

## Server v1.6.551 published

The immutable linux/amd64 image is
`ghcr.io/pasturestack/server:v1.6.551@sha256:150c3eaa2d84df6236e7634843e506a79df71d9e434ad2038427108c14ac358e`,
produced from `9abef4712901981e5917c41356bb261974fdba47` in successful
[run 40120970328](https://github.com/PastureStack/server/actions/runs/40120970328).
All 33 assets passed anonymous byte/checksum readback. The Host API archive also
matches its original producer SHA-256, retains its internal checksums and binary,
and both image attestations bind the exact producer and digest.

The 550 PCRE2 fixes, Web Console 1.6.195, Engine v0.183.354 and other component
inputs are unchanged. The 8080 cutover, one restart, package integrity/linkage,
MariaDB regex controls and three active Host/Agent states passed. Configuration,
three existing data volumes, socket bind, AppArmor and the 550 rollback were
preserved. No production site, HAProxy or firewall was changed.

The scan retains 13 pending LOW/MEDIUM occurrences across 10 CVEs. Unrelated
native candidates and build-host coverage are separate; none is presented as a
remediated consumer. See the [release note](docs/releases/server-1.6.551.md).

<a id="server-v16550-pcre2-backports"></a>

## Server v1.6.550 published

The Server image is valid, but its standalone Host API Release attachment was
mistakenly replaced with an empty gzip during manual publication completion.
Use 551 or the original Host API producer release for that download. The immutable
bad attachment is retained as failure evidence; checksum self-consistency alone
did not establish producer identity. See the [correction](docs/releases/server-1.6.550.md).

The immutable one-layer linux/amd64 identity is
`ghcr.io/pasturestack/server:v1.6.550@sha256:03542028c3ce4be11d7ff87f96beddf5179c67caf9f0d28ad57043acf3cf52c5`,
produced from `54deb98ee33ffab78437070d61179b602844182e` in
[run 40116218929](https://github.com/PastureStack/server/actions/runs/40116218929).
All 34 assets passed anonymous checksum readback; both image provenance and SBOM
attestations bind the same digest and producer. The original job remains failed
at its final release-note heading check. The exact signed image completed
publication without a rebuild or tag overwrite; the attachment correction above
supersedes the broader asset claim in the original immutable
[completion receipt](https://github.com/PastureStack/server/releases/download/v1.6.550/publication-recovery.json).
The permanent note preflight now validates the actual candidate document.

The two PCRE2 packages use first-party `10.46-1build1+pasturestack.1`, built from
original Ubuntu source/packaging with the complete supported upstream backport
series. They are not issued by Canonical. Original native tests, package-owned
bytes, SONAMEs, hardening, both library hashes and five actual consumers passed.
The deployed image also passed MariaDB regex controls and one controlled restart,
with the existing HostConfig, environment, three data volumes, socket bind,
AppArmor and the 549 rollback container retained. Three Host/Agent states remain
active. No production site, proxy or firewall was changed.

The fresh runtime scan retains 51 raw occurrences, 38 exact VEX dispositions and
13 pending LOW/MEDIUM occurrences across 10 CVEs. Eight PCRE2 CVEs are fixed;
other artifacts and build-host SDKs are tracked separately. Browser component
pins and its incomplete coverage are unchanged. This is scoped acceptance, not
an all-feature or all-project zero-risk claim. See [the release note](docs/releases/server-1.6.550.md).

<a id="server-v16549-web-console-sbom"></a>

## Server v1.6.549 published

Producer `ed3f334f2c371a3038ca5fe3e63c6581c8c1aabf` completed the source,
build, security, startup/restart, image publication and both attestation steps in
[run 40096562378](https://github.com/PastureStack/server/actions/runs/40096562378).
The original job remains failed because GitHub rejected its zero-byte browser
findings attachment. The same verified CI reports were recovered as 34 immutable
release assets, with the empty TSV losslessly encoded as deterministic gzip.
The published [recovery receipt](https://github.com/PastureStack/server/releases/download/v1.6.549/publication-recovery.json)
records this transport-only completion; no image was rebuilt or tag overwritten.
All assets passed anonymous checksum readback, and both image attestations were
independently verified against the exact producer and image.

The one-layer linux/amd64 image identity is
`ghcr.io/pasturestack/server:v1.6.549@sha256:dae1c8e490e012a030855d73d7af0bfcd85f4c9d9bf94148664d492c35e5684c`.
Its distinct OCI config is
`sha256:ba535844f1b3e37ad3be74c7037ef7be90cd186f7058dad9a421de4d95f09a24`.
Installation examples retain only the numeric tag.

Web Console `1.6.195` retains producer
`f905bc12daae18d98a6ac65942625562fff2a424` and its original browser runtime SBOM
at `/usr/share/licenses/pasturestack/web-console/runtime.cdx.json`. Its archive,
source, version, lock and SBOM hashes passed identity checks. The independent
fresh-DB scan recognized all 87 npm PURLs, reported zero browser findings and
explicitly retained six unsupported source snapshots as unknown. The SBOM and
coverage report remain `incomplete`; no OS VEX or not-affected disposition is
applied to these snapshots.

The complete runtime gate retains 51 raw findings and 29 exact, officially
unfixed LOW/MEDIUM occurrences across 18 CVEs after existing VEX dispositions.
HIGH/CRITICAL, available fixes, unregistered findings and secrets are zero.
Tracking is not remediation or zero risk. Build-host Ruby inventories and
unmeasured Server intermediate-stage packages remain separate from runtime
coverage. The Web195 Node build container passed Ruby-absence gates before and
after building; this does not establish Ruby absence on the enclosing runner.

The same digest passed the scoped 8080 cutover with environment, HostConfig,
all three data volumes, the existing Docker socket bind and AppArmor preserved.
Actual-container readback verified
Server 549, Web195 and the producer's original runtime SBOM hash. Chrome155
passed OIDC with IdP and platform TOTP, seven JSON API reads, three active
Hosts/Agents, session refresh and a received WebSocket frame. The successful
pass had no browser/HTTP/request errors or passive DELETE requests.

The six-stage build, final one-layer publication process, other component pins,
named volumes and operator settings are retained. This scope did not rerun the
full permission matrix or add a manual Server restart. See the
[release note](docs/releases/server-1.6.549.md) for retained fixture failures,
the consistent backup, acceptance boundaries and rollback guidance.

<a id="server-v16548-provider-watch"></a>

## Server v1.6.548 published

Official producer `62dddd5269e2f4b9b8925e424f55359146c786ae` passed
[publisher 40018625225](https://github.com/PastureStack/server/actions/runs/40018625225).
All 26 immutable release assets passed anonymous checksum readback. Image
provenance and SBOM attestations were independently verified against the exact
source, workflow and published image identity.

The one-layer linux/amd64 published image is
`ghcr.io/pasturestack/server:v1.6.548@sha256:a20b7f32d53152a7be11b28ff0c081679e42161e3142718424a3bcabfab115be`.
Its distinct OCI config is
`sha256:58c9ac3c9d9002a0a02aac683caf5d7544d239930b55da5fd41ac18c5b7201b7`.
Installation examples use only the numeric tag.

Catalog `v0.3.16`, pinned to source
`070e08d8f85ffc2779a0f97eb4e356c857812d34`, adds Network Services revision 13
with Network Plugin Manager `v0.8.25` and Metadata Service `v0.10.6`.
The manager reselects authorized, running local CNI providers on lifecycle
events and bounded retries. Metadata retains each local dataset's opaque
version token; explicit external-metadata version overrides remain unchanged.
Internal DNS, older template revisions, questions, sidekicks, volumes,
firewall-backend choices and operator overrides are preserved.

The complete runtime gate reports 51 raw findings and 29 tracked, officially
unfixed LOW/MEDIUM occurrences across 18 CVEs after exact existing VEX
dispositions. HIGH/CRITICAL, fixed-available, untracked findings and secrets
are zero; tracking does not mean remediation or zero risk. Scoped real-host
acceptance passed for eight infrastructure stacks, network/watch behavior,
browser authentication and two controlled same-version Server restarts.
Five transient WebSocket handshake 502 responses during controlled downtime
are retained separately from the failure-free normal before/after checks.
See the [release note](docs/releases/server-1.6.548.md) and
[upgrade guidance](docs/upgrades/README.md).

<a id="server-v16547-network-lifecycle"></a>

## Server v1.6.547 published

Official producer `eb018efeb3ff5740e63adf054ef19265868b3538` passed
[publisher 40008002413](https://github.com/PastureStack/server/actions/runs/40008002413).
All 26 immutable release assets passed anonymous checksum readback, and the
image provenance and SBOM attestations were independently verified against
the exact source, workflow and published image identity.

The one-layer linux/amd64 published image is
`ghcr.io/pasturestack/server:v1.6.547@sha256:09b14e3ad99d75223dca5251f6a27fa9dfec0cc55a3670b683ad406125f24de7`.
Its distinct OCI config is
`sha256:872a8760d53ea02a9d0b7e805d50314efbd06df0316100e9438e0910e1eb0852`.
Installation examples use the numeric tag without a digest suffix.

Catalog `v0.3.15` adds Network Services revision 12 with Network Plugin Manager
`v0.8.24`; Metadata `v0.10.5`, Internal DNS `v0.17.13`, earlier revisions,
questions, sidekicks, volumes and firewall-backend choices are retained.
Metadata/DNS replacement belongs to the Server lifecycle. The manager no
longer deletes overlapping dependency instances and waits for Metadata with
bounded requests, backoff and cancellation. Other local orphan handling remains.

The v1.6.546 security inputs and exact dispositions remain in force: 51 raw
runtime findings become 29 tracked, officially unfixed LOW/MEDIUM occurrences
across 18 CVEs after existing exact VEX dispositions. HIGH/CRITICAL,
fixed-available, untracked findings and secrets are zero. Publication is not
real-host upgrade or full functional acceptance; see the
[release note](docs/releases/server-1.6.547.md) and
[upgrade guidance](docs/upgrades/README.md).

<a id="server-v16546-security-refresh"></a>

## Server v1.6.546 published

This release consumes independently verified security releases.
It keeps the existing authentication, authorization, registration, storage,
service-upgrade and API contracts. Ubuntu packages stay on the installed
26.04 series; host Docker daemons and firewall backends are not changed.
Temurin changes to 25.0.5+8; embedded Go products use the reviewed fixed
toolchains and same-major dependency updates.

The Engine's build environment uses the official pip 26.2.2 source with a
reproducible urllib3 2.8.0 vendoring rebuild, identified as
26.2.2+pasturestack.1. This is a build dependency version, not a new project
release-tag convention. Its stream-size and TLS regressions, ensurepip,
venv and virtualenv paths are checked. No JWT, MFA or TLS verification is
disabled.

Raw findings, exact package versions and official unfixed status are retained.
Tracking an unfixed LOW/MEDIUM finding does not mean it is fixed or risk-free.
HIGH/CRITICAL, available fixes, unregistered findings and secrets remain
release blockers. Existing operator environment variables and named volumes
must be preserved. See [release details](docs/releases/server-1.6.546.md).

Official producer `c1b4b335f77f8faaae8239af9e8d5a8189ce07b8` passed
[publisher 40000369416](https://github.com/PastureStack/server/actions/runs/40000369416).
All 26 immutable release assets, the anonymous registry readback, and the
provenance/SBOM attestations were verified. The one-layer linux/amd64 image
manifest is `sha256:7b29b87ab40f427c2a6a5909330dd859745e9f0780166658ffd0556b6f0873d2`;
its distinct OCI config is
`sha256:22fbb5fe50be0317a25571b8d0ac4d1782a0bfae9959d0b72666ed8ca897f2ca`.
The published image identity is
`ghcr.io/pasturestack/server:v1.6.546@sha256:7b29b87ab40f427c2a6a5909330dd859745e9f0780166658ffd0556b6f0873d2`;
installation examples keep the numeric tag without a digest suffix.
The complete gate reports 51 raw findings and 29 tracked, officially unfixed
LOW/MEDIUM occurrences across 18 CVEs, due for review on 2026-10-27.
HIGH/CRITICAL, fixed-available, untracked findings and secrets are zero;
this is not a zero-vulnerability claim.

The internal compose executor is updated to 0.14.39. That release does not
publish three-platform legacy Compose CLI downloads. The optional
`RC16_ARTIFACT_BASE_URL` compatibility URLs are therefore not changed to
nonexistent 0.14.39 CLI archives; those URLs remain an operator-supplied
integration, separate from the bundled executor and maintained PastureStack CLI.

The immutable machine-driver bundle 0.16.5 replaces the inherited 0.14.0
executable with Go 1.27.3 security updates. Both executable hashes, the archive,
source metadata and legal files are verified. Existing provider configurations
are preserved; the retired Packet provider is not enabled for new hosts.
The bundled machine package becomes the default, without overriding an
operator's explicit `CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL`.

## Server v1.6.545 published

Official source `858ec54df70b8089ef900a16bed1287d94e7f692` passed
[publisher 39893305304](https://github.com/PastureStack/server/actions/runs/39893305304).
All 26 immutable release assets passed checksum verification. The manifest is
`sha256:f79279d9d00d0301353663e000dc41b1ed49efe45e4ed878e03d1207cfea2a44`;
the distinct OCI config is
`sha256:6fc2e01d80288d65991b3886cea5390395a754f3d22e3a9acd1576007f62ec6a`.
The linux/amd64 image has one runtime layer, 516,540,955 compressed bytes.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.545@sha256:f79279d9d00d0301353663e000dc41b1ed49efe45e4ed878e03d1207cfea2a44`.

Engine `0.183.353` compares complete public-endpoint identities, including the
service, host and instance references. Web Console `1.6.193` sends the existing
service upgrade action directly after validation/readiness instead of first
PUTting a full service clone. Normal create/edit, shared saving/error lifecycle,
authorization and `InvalidReference` validation remain unchanged.

All other component pins, frozen authorization schemas and runtime settings are
retained. The final merged-rootfs-and-active-payloads gate reports 74 raw
findings and 30 tracked unfixed LOW/MEDIUM package occurrences across 19 CVEs;
HIGH/CRITICAL, fixed-available, untracked findings and secrets are zero.
Tracking is not remediation or zero risk.

The QA rollout and actual Server restart passed, preserving all three volumes,
operator overrides and AppArmor. A primary service and sidekick upgraded from
BusyBox 1.36.1 to 1.37.0 without a full service PUT. The upgrade returned 202,
the subsequent link update returned 200, and the normal Finish Upgrade UI
returned 202. API, database and Docker readback confirmed the new instances,
unchanged published address/port, retained volume data and configuration, and
the same new instance identities after Server restart. See the
[545 release note](docs/releases/server-1.6.545.md). Keep the previous image,
database backup, persistent volumes and operator overrides for rollback.

## Server v1.6.544 published

Official source `d6e966329b588693a6b904989865e18f731ffbad` passed
[publisher39726684553](https://github.com/PastureStack/server/actions/runs/39726684553)
and anonymous exact-set/checksum readback of all 26 immutable release assets.
Its manifest is
`sha256:e9015d5e6d6525a684feb0161918aa7d089ecaee136907119170a7b82cdda19d`;
the immutable image coordinate is
`ghcr.io/pasturestack/server:v1.6.544@sha256:e9015d5e6d6525a684feb0161918aa7d089ecaee136907119170a7b82cdda19d`.
the distinct OCI config is
`sha256:7ca8a7082b15e8d03ea3cfdc19d61fe77b35c012c1e63daf9f4a96a31fe46eb8`.
The linux/amd64 image has one runtime layer, 516,490,074 compressed bytes.
The QA8080 upgrade and actual restart passed with matching source and image
identities. All three persistent volumes, runtime overrides and LB database
settings were preserved; a 543 rollback and backup were retained. This Server
switch does not establish upgraded Host/Node processes, active-stream remediation
or complete native-matrix acceptance.

The 544 assembly consumes the original tested bytes of official Host API
`0.38.7` and Node Agent `0.13.31`, including the Windows Node package. Host API
keeps confirmed scoped authorization loss from being overwritten by a later
transport disconnect or cancellation-derived backend error. Its bounded final
check distinguishes confirmed denial from an unavailable authorization service;
ordinary JWT handling, genuine completion and backend failures remain unchanged.
The terminal reason describes authorization at finalization, not which watcher
first closed the connection. Node Agent retains exact Host API `0.38.7` matching
without a legacy fallback.

Host API's actual binary producer is
`cd2a8d2b5e37f1b79a4b487760db5f3f7b3f818b`; Node Agent's Linux and Windows
producer is `68ae58d886621540208b98378ed517b3525244e0`. The numeric component
tags bind their original CI bytes, not a rebuild from later documentation commits.
Engine `0.183.352`, Proxy `0.23.17`, Web Console `1.6.192`, CNI `0.2.5`, CLI
`0.6.19`, LB `0.9.32`, frozen schemas and all other pins remain unchanged.

The 17 local component inputs, 26 release assets, four nested Go payloads,
separate JDK stage and one-runtime-layer assembly remain required. Preserve
all three persistent volumes, runtime overrides, LB database settings, custom
audit directories and the previous official image and backups for rollback.
Bundled package changes do not prove that existing running hosts have upgraded.
The final merged-rootfs-and-active-payloads gate reports 73 raw findings and
29 tracked unfixed LOW/MEDIUM package occurrences across 18 CVEs, review
2026-10-27; untracked, HIGH/CRITICAL, fixed-available and secrets are zero.
Tracking is not remediation or zero risk. The four nested payloads retain their
separate actual-binary qualification, raw scans and CycloneDX SBOM.
See the [544 release note](docs/releases/server-1.6.544.md).

## Server v1.6.543 published

Official source `a9559b6ae3c46955e9665a0ccce7358707480af7` passed
[publisher39714403303](https://github.com/PastureStack/server/actions/runs/39714403303)
and anonymous exact-set/checksum readback of all 26 immutable release assets.
Its manifest is
`sha256:d5664f64924c089ff67ba155cd5a1fc195f06a45ed71c855e9a558fb689240a3`;
the distinct OCI config is
`sha256:b8cdbdd45afc1d69c36bdd5f960218bad63b62f04d333cb0913c4873e6250b51`.
The linux/amd64 image has one runtime layer, 516,486,942 compressed bytes.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.543@sha256:d5664f64924c089ff67ba155cd5a1fc195f06a45ed71c855e9a558fb689240a3`.
The QA8080 upgrade and actual restart passed with matching source and image
identities, all three persistent volumes, runtime overrides and LB database
settings preserved, and a 542 rollback and backup retained. This is not stream
or complete native-matrix acceptance.

The assembly replaces only WebSocket Proxy `0.23.16` with the
immutable official `0.23.17` bytes. The actual CI/binary producer is
`6fc9f6a2ee3c010b5376887b387a32f243240026`; the numeric tag points at verified
merged main `9eb4bed975db048cf41acedfd03a058da34dd992`, with an identical tree.
Authenticated Host API backends require canonical `0.38.x` patch >= 5 and
the exact `key-audit-v1` / `key-delegation-v1` capabilities. Unknown protocol
families, malformed versions and unauthenticated declarations remain rejected.
Engine `0.183.352`, all other component pins, security gates and persistence
contracts are unchanged from published 542, including custom audit directories.
The final merged-rootfs-and-active-payloads gate reports 73 raw findings and
29 tracked unfixed LOW/MEDIUM package occurrences across 18 CVEs, review
2026-10-27; untracked, HIGH/CRITICAL, fixed-available and secrets are zero.
Tracking is not remediation or zero risk. The four active nested payloads retain
their separate actual-binary qualification, scans and SBOM.

Preserve the three volumes, runtime overrides, LB database settings and previous
official image and backups for rollback. Publication evidence does not establish
complete native-matrix acceptance. See the [543 release note](docs/releases/server-1.6.543.md).

## Server v1.6.542 published

Official source `c7244b0e0ca1038286fdd451f7208453f7e3805d` passed
[publisher39706118112](https://github.com/PastureStack/server/actions/runs/39706118112)
and anonymous exact-set/checksum readback of all 26 immutable release assets.
Its manifest is
`sha256:b64293f7d815603b29c65395ff83aa6f4e00b1053b639685f501553c5f538c18`;
the distinct OCI config is
`sha256:bbba300dad5659d4868cab053b034428bf7c719f434cc28023e0560e8bc323dc`.
The linux/amd64 image has one runtime layer, 516,485,802 compressed bytes.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.542@sha256:b64293f7d815603b29c65395ff83aa6f4e00b1053b639685f501553c5f538c18`.
The QA upgrade and actual restart passed with all three persisted volumes,
runtime overrides and LB database settings preserved, and a 541 rollback retained.
This deployment evidence is not complete native-matrix acceptance.

Server `v1.6.542` packages official Engine `v0.183.352`. Its project-scope
checks preserve live membership and inactive-project authority without adding
request-local capabilities or object grants while filtering account responses.
Normal Project manager capabilities and Full/legacy Key boundaries remain.
This corrects a permission-check side effect; it is not evidence of an
unauthorized write.

The actual WAR producer is `70ba8cff544fcd5607f3054d30ac8b5cf09783d6`, not
integration main `109f2623f00ca3a3a9079414a0f0f8bd23cd1eb2`.
The official `cattle.jar` SHA256 is
`1f17603554f1ee3fb651c6570690cb2d7b8c2fa27de17ae260d0cc68b402d826`.
All other 541 component pins, frozen schemas, settings and persistence
contracts are retained, including the custom audit-directory contract.
The actual merged-rootfs-and-active-payloads gate reports 73 raw findings and
29 tracked unfixed LOW/MEDIUM package occurrences across 18 CVEs, review
2026-10-27; untracked, HIGH/CRITICAL, fixed-available and secrets are zero.
Tracking is not remediation or zero risk. Custom24/OIDC and active-stream
acceptance remain separate; no whole-matrix PASS is implied. See the
[542 note](docs/releases/server-1.6.542.md).

## Server v1.6.541 published

Official source `b4bbc6807f83e2bcc1a7ba46c132e4259ff48e79` passed
[publisher39691051968](https://github.com/PastureStack/server/actions/runs/39691051968)
and anonymous exact-set/checksum readback of all 26 immutable release assets.
Its manifest is
`sha256:05976db2df0c39e2df6e133f2b228da6273676d7b0e6c82172be89704b14aff4`;
the distinct OCI config is
`sha256:3edd57c76ece4fe7b2a478abea6a03fecf10c7a5d56fbc03a4bda77b5cf7c599`.
The linux/amd64 image has one runtime layer, 516,480,269 compressed bytes.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.541@sha256:05976db2df0c39e2df6e133f2b228da6273676d7b0e6c82172be89704b14aff4`.
The QA upgrade and actual restart passed with all three persisted volumes,
runtime overrides and LB database settings preserved, and a 540 rollback retained.
This deployment evidence does not establish full native-matrix acceptance.

Its only component replacement from official Server `v1.6.540` is Windows per-host-subnet
`v0.2.5` bundle. The original-CI producer is
`e102e0bb38d84b0a9cbf87e5458cf1bc74d01904`; its normal verified integration main
`188f53ae35adf54eca7f357750a210cb2ab6edb8` has the same complete source tree.
The Windows PE is Go `1.27.3`, CGO disabled, amd64. The existing producer uses
`-buildvcs=false`: no embedded VCS is expected, not a claim of `vcs.modified=false`.
Exact original-CI archive, PE, startup and provenance-receipt SHA256 pins bind
this CNI-only contract. Host/Node retain exact embedded producer revision and
`vcs.modified=false`; there is no general no-VCS fallback.

Engine `v0.183.351` still uses actual WAR producer
`1befd83278618f9a5b7cdaf96522004dd89918ba` and JAR SHA256
`efd0e826364c551f782b281f081d53cadb48faa7d5c37c2f101e6f9c7d7f9ea6`.
Host API `0.38.6`, Linux/Windows Node Agent `0.13.30`, CLI `0.6.19`, LB `0.9.32`
and all other 540 component byte pins are unchanged. Read-only comparison of
the actual 540 baseline and final 541 image confirmed eleven runtime/JAR files,
88 console assets and thirteen translation files byte-for-byte. This supports
carry of their unaffected 540 acceptance only; it does not replay those cases
or certify the changed Windows CNI's native networking.

Four active compressed Host/Node/CNI payloads passed independent actual-Go-binary
qualification and scans: four positive `gobinary` targets, each with zero
vulnerabilities/secrets, and a CycloneDX1.7 nested SBOM with 128 components.
The final merged-rootfs gate retains 73 raw findings and 29 exact unfixed LOW/MEDIUM
package occurrences across 18 CVEs, review 2026-10-27; untracked, HIGH/CRITICAL,
fixed-available and secrets are zero. Tracking is not remediation or zero risk.
Local build inputs
are 17; the public immutable release envelope remains 26 assets. The CNI legacy
`rancher/per-host-subnet.exe` and `rancher/startup_per-host-subnet.ps1` paths stay
compatible. Only superseded CNI024 is removed inside the new image after active
files and all references are validated; unrelated bundles, live hosts, data
volumes and rollback images are not cleanup targets. The new image's
`CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL` selects 025, but does not silently
replace an already-installed Windows CNI. Normal explicit Windows upgrade and
native networking validation remain required. No new scanner exception or
Windows-native certification is claimed. See the [541 note](docs/releases/server-1.6.541.md).

## Server v1.6.540 published baseline

Official source `cb78888bd156f9aca3b0c31b2b2076319bc116cf` was anonymously read
back and deployed to the owned QA125 target with startup/restart health, all
three volumes, runtime overrides and the two LB DB settings preserved. This is
a targeted deployment result, not full native-matrix PASS. Its registry manifest
`sha256:b6b3909578f4e05a3cdccb1c24640ee3fbc6f8919d0b06a787ee1d3830d7e1c2`
and OCI config
`sha256:2a2377f42dfa0dccf2940528d484cbe333c9e7e817a6902ba968bf3021c6a14e`
are different identities. Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.540@sha256:b6b3909578f4e05a3cdccb1c24640ee3fbc6f8919d0b06a787ee1d3830d7e1c2`.
A Docker local image ID may equal either manifest or config according to
its image store. This baseline does not establish any 541 artifact or runtime
result.

## Server v1.6.539 published

Producer `95ed547ccfe5c1c7d5c9f049e11f27b81c0a00f9` passed required checks and
[official publication](https://github.com/PastureStack/server/actions/runs/39412956932).
All 25 release assets passed anonymous checksum/exact-set readback. Manifest:
`sha256:c9550fa6257da54d1d57e1acff2563f89908a346d4088853bc550d82ac3644ae`.
Distinct OCI config:
`sha256:08f38f6169e2e7b2c0d9a2d6e4e29a3a787e77b2f7e7265bf801e2d5c0878e86`.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.539@sha256:c9550fa6257da54d1d57e1acff2563f89908a346d4088853bc550d82ac3644ae`.
The linux/amd64 image has one runtime layer, 540,238,249 compressed bytes.

Linux Node Agent `v0.13.29` uses a consistent host mount view, retains usable
partitions after partial collection failure, excludes read-only Snap images and
reports new local-storage budgets in whole MiB. Web Console `1.6.192` treats
unknown capacity as unknown rather than zero. Bootstrap image `v1.2.31` and the
Windows Go package `v0.13.27` remain distinct and unchanged.
Existing `localStorageMb` is a persisted scheduler budget, not a live free-space
meter: upgrading the Agent does not silently overwrite it or an operator's
override. The QA repair used normal project-scoped Host PUT for three exact,
proven historical unit errors, preserving the original budget and rollback
values; other installations must review their own provenance, not copy QA values.

Fresh persisted-data README installation was exercised on official 538: initial
local administrator, four automatic system stacks, first Host, DNS/egress/port,
terminal/log streams, container recreation, Server/Docker restart and VM reboot.
Its disk finding was then fixed and verified on published 539 across three
existing Hosts, using the running Agent executable, native filesystem capacity,
API data and six rendered Host pages. These are separate evidence scopes, not
a claim that every historical matrix case or a new OS install was repeated.
Volumes, runtime overrides, AppArmor and the previous recovery image were kept.
The actual iptables-nft backend was preserved; native Docker nftables mode and
KVM are not certified by these checks. Company production was not changed.

Final-image security remains 73 raw findings and 29 exact unfixed LOW/MEDIUM
package occurrences across 18 CVEs, review 2026-10-27. Required gates found zero
untracked, CRITICAL/HIGH, fixed-available or secret findings. Tracking is not a
remediation claim. See the [release note](docs/releases/server-1.6.539.md).

## Server v1.6.538 published

Immutable Server producer `9dd8f1da85c57fc2424b9f58c278331cf679b8fc` packages
official Web Console `1.6.191` and API Explorer `1.1.19`, and replaces the inherited
Server460 JDK with official Temurin `25.0.4.1+1`. Official workflow
[39362063157](https://github.com/PastureStack/server/actions/runs/39362063157)
and anonymous digest/checksum readback of all 25 release assets passed without
bypassing required checks. Manifest:
`sha256:10284f7c3e3a04d7212accae9bdb6daac89ea2f23bc39cd1064e937415af231e`.
Distinct OCI config:
`sha256:cd754a3eb44536004322bd28471bc094a5c13ead64b420fcde07a97d9a1912a5`.
Artifact identity (not an installation command):
`ghcr.io/pasturestack/server:v1.6.538@sha256:10284f7c3e3a04d7212accae9bdb6daac89ea2f23bc39cd1064e937415af231e`.
The linux/amd64 image has one flattened runtime layer (540,239,336 compressed
bytes). Numeric installation tags remain required; documentation commits do not
replace the producer or its immutable build-time evidence.

Actual candidate JDK identity, native libnet/libnio operations and Java schema
serialization passed. Fresh final-image startup/restart returned HTTP200/pong
after 11/7 polling attempts; 34 MFA-policy API and seven registration-entry checks
passed. Registration entry checks do not prove an active node. The final-image
security gate records 73 raw findings and 29 exact unfixed LOW/MEDIUM package
occurrences across 18 CVEs, review 2026-10-27, with zero untracked, critical/high,
fixed-available or secret findings. Tracking/VEX is not remediation or zero risk.

Engine `v0.183.350`, authentication, API Key/RBAC, archive, performance environment
variables and three-volume contracts are unchanged. Targeted QA8080 deployment
acceptance passed separately from the official image gates, preserving the three
named volumes and runtime overrides through startup/restart. Both existing
Schedulers completed normal Catalog revision4 to revision5 / `v0.8.19` upgrades
with existing explicit answers and effective runtime configuration retained;
both are active/healthy and
all three existing Hosts/Agents remain active.

The bounded acceptance total is 29 unique narrow checks: 25 carried PASS receipts,
two API Explorer locale cases and two additional Scheduler workload cases. It is
not a rerun of all thirteen locales, the role matrix, OIDC or Passkey acceptance.
Owned test fixtures were removed and read back. VM definitions/disks were not
removed or reconfigured; company production was not modified. The previous
working image/container and backup were retained.
No company site deployment or whole historical matrix PASS is implied. See the
[release note](docs/releases/server-1.6.538.md).

## Server v1.6.537 published

Immutable Server producer `f1df33f2a8b9e9265a9b8eeb9ad464786eb7f62e` packages
official Web Console `1.6.190` and Engine `v0.183.350`. Official workflow
[38742185175](https://github.com/PastureStack/server/actions/runs/38742185175)
and anonymous exact-set readback of all 24 assets passed without bypassing checks.
Manifest: `sha256:81aafa0347910449ef528526f02e75a12acfce2f3987b803b92cb3b96fd0ac2d`.
Distinct OCI config: `sha256:f49f36d2d6d2bd397c62330a0ff616aa8a3bbd5fce9cba10da45efabf9144363`.
Artifact identity (not an installation command):
`ghcr.io/pasturestack/server:v1.6.537@sha256:81aafa0347910449ef528526f02e75a12acfce2f3987b803b92cb3b96fd0ac2d`.
The linux/amd64 image has one runtime layer; documentation commits do not replace
the producer. Numeric installation tags remain required. See the
[release note](docs/releases/server-1.6.537.md).

Stack and Service `archived` is a persisted boolean with missing values treated
as false. Archive requires stopped services and instances, rejects system/driver
resources, and has no start/stop/delete or storage lifecycle side effect. Empty
Stacks may be archived. Parent and child flags remain independent; restore does
not clear separately archived children. Archived resources must be restored
before starting or adding/moving children into them. Archive/restore uses the
existing update authorization and native v1/v2-beta APIs, not a new role grant.
Older Engines do not implement archive enforcement; code rollback does not
promise retained archive behavior and archive never replaces data backups.

The console's personal, per-environment archive switch changes only visibility.
Read-only users may include archived resources without gaining write controls;
the effective schema and update capability remain authoritative. Older Engines
without a readable/updatable boolean field do not offer the action. The modal
warns that mounts and volumes are retained and require operator backups.

Reviewed pre-release isolated evidence covers focused tests, native role/Key
archive/restore, thirteen-locale layouts, owner-read Key audit, and separate
physical workload/mount preservation and first-host checks. It does not establish
an exhaustive preserved-database upgrade or distributed race matrix. Separate
official final-image startup/restart passed with HTTP200/pong after 12/8 polling
attempts, with 34 MFA-policy API checks and seven registration-entry checks; this
is not a Docker Healthcheck or a company-production deployment claim. Existing API
Key policy, authentication/OIDC/MFA, three-volume persistence, CLI defaults,
performance overrides and firewall contracts are not changed by this feature.
The new final-image scan records 66 raw findings and the existing exact 22 unfixed
package findings across 11 CVEs after VEX policy, review 2026-10-20. Its gate passed
with zero untracked, critical/high, fixed-available or secret findings. VEX and
vendor tracking are not remediation, a HIGH waiver or a zero-risk claim.

## Server v1.6.536 published

Immutable Server producer `b8cefb51db7f5e88341fdf231f6ae43d773fb9c7` passed the original official workflow [38681298101](https://github.com/PastureStack/server/actions/runs/38681298101) and anonymous release readback. Manifest: `sha256:84b701244ccd83abc313cfad47c52edf9c58fa49cdd5c2da129cdac0c81d8094`. Distinct OCI config: `sha256:4b56a5f4f58edf2ff08414fde91cc70da440562d7b6264ec62aaca133c256237`. Artifact identity (not an installation command): `ghcr.io/pasturestack/server:v1.6.536@sha256:84b701244ccd83abc313cfad47c52edf9c58fa49cdd5c2da129cdac0c81d8094`. Documentation commits do not replace the producer. Numeric installation tags remain required.

This packaging update retains Web Console `1.6.189`, Engine `v0.183.349`, API Key policy, authentication, volumes, performance settings and firewall behavior. QA startup/restart passed with the original runtime configuration. No database migration or runtime binary patch is used.

### Maintained CLI error reporting

Official immutable [CLI `v0.6.18`](https://github.com/PastureStack/cli/releases/tag/v0.6.18), producer `2fd1298ffdc25e17008cb089fccf7780ed8728d5`, passed its original release/security gates and anonymous archive/SHA256SUMS readback. The three external download defaults use the producer's platform-before-version names. `PASTURESTACK_CLI_RELEASE_BASE_URL` follows the effective `CATTLE_RANCHER_CLI_VERSION`; without it the historical RC16 layout remains available. Explicit DEFAULT/active URLs and saved database settings remain authoritative. Existing custom mirrors are not silently migrated. Changing a download setting does not install a binary inside Server.

On the official Server535 QA runtime, the maintained native CLI performed the same ordinary inspect command with Full, absent-policy legacy and Closed Keys. Full/legacy DTOs matched exactly; Closed returned nonzero with HTTP403 `KeyPolicyDenied`, no DTO and matching authorization/response audit pairs. The single empty Stack, three Keys and temporary client directory were normally removed. This evidence retains its actual535 provenance; it is not a536 rerun or a whole-client/role matrix. The old0.6.14 silent exit-zero defect and original failure receipts remain historical evidence.

E2E-02 acceptance is the bounded original F-G evidence plus root review of exact unchanged UI pointers, with original versions and original FAIL retained; no new browser run is claimed. Unchanged535 action/role/rollback evidence is carried only within its original scope. Remaining matrix gaps, historical HOLDs and deferred KVM work remain unverified.

The Server final-image gate retains 22 unfixed package findings across 11 CVEs, review 2026-10-20. CLI retains 100 exact reviewed LOW/MEDIUM tracker rows under the approved no-fixed policy. Raw findings, vendor status and precise VEX decisions are preserved separately; tracking is not remediation, not_affected or a HIGH waiver. Source SBOM inventories do not prove runtime safety or zero risk.

Preserve the existing named volumes and runtime overrides; retain the previous working container for code rollback without restoring old policy/revocation/expiry or database state.


## Server v1.6.535 published

This patch packages immutable Engine `v0.183.349` with unchanged Web Console
`1.6.189`. Engine producer: `0733430fac11892a17ba53749fe02d99d26b1f52`;
`cattle.jar` SHA-256:
`6e61f05598c12941c3b07ebfcf81f40e7fb1bd5439ec4c7d9c34484306378f04`.

Server producer: `6b7dca3a4d9154e37f9475e7b47d73bce26e1938`.
Artifact identity (not an installation command):
`ghcr.io/pasturestack/server:v1.6.535@sha256:634613baf631d54e4cf576aeaa2f9f003b035fdfec4a28e28aa3c8f0aa38283d`.
Official workflow [38672753267](https://github.com/PastureStack/server/actions/runs/38672753267)
and immutable readback of 24 assets passed without bypassing required checks.
The linux/amd64 image has one runtime layer. Manifest:
`sha256:634613baf631d54e4cf576aeaa2f9f003b035fdfec4a28e28aa3c8f0aa38283d`.
Distinct OCI config:
`sha256:599313735f18cc95330e0bbb76bd76bd74251c8bc4f56cba019afed4a0a3fc31`.
Documentation commits are separate from the immutable producer.

Fifteen resource-typed action pairs extend scoped-Key admission and queued
reclassification without adding restrictions to Full/legacy Keys or widening
owner authority. The focused Engine suite passed 150 cases and affected Server
packaging contracts passed 38 cases; unaffected suites are carried forward.
No schema migration, runtime patch, authentication or firewall change is needed.

The official 535 image passed QA startup/restart and ten bounded native Stack
output cases across both API roots, with eight audit pairs and normal fixture
cleanup. Actual 535 -> retained 534 -> 535 code rollback retained Closed/expired
Key policy, revision and expiry in twelve denial cases without restoring the
database. The final container was ready 535 and the two test Keys were removed.
Prior six-role OIDC A comparisons retain their original 534 provenance; neither
this release nor those results claim completion of every role/action combination.

The final-image gate reports zero untracked, critical/high, fixed-available or
secret findings under its existing vendor/VEX policy. It retains 22 unfixed
MEDIUM package findings across 11 CVEs for review on 2026-10-20. Newly reported
CVE-2026-107161 remains Ubuntu 26.04 Needs evaluation; its upstream CVSS 7.5 High
score is retained, not represented as fixed or not affected. See the
[release note](docs/releases/server-1.6.535.md) for acceptance and rollback limits.

### Legacy CLI error reporting

The configured official CLI `0.6.14` download is an external client, not an
executable installed inside Server. Native Full and stored-null legacy Key
`inspect` commands produced identical data with no extra authentication headers.
Legacy policy readback is canonical Full with revision zero, not JSON null.

The same client returned exit code zero and no output when a Closed Key was
correctly rejected with HTTP 403 `KeyPolicyDenied`; the server's matching audit
pair confirms denial, not successful access. This client error-reporting defect
remains open. The maintained `0.6.17` source propagates the error, but it is not a
published product and its original release gates have not passed. Do not treat
empty CLI output or exit zero as proof of a successful API operation. Use an
HTTP client that checks response status for constrained-Key automation until a
verified maintained CLI is released. The server does not waive the Key policy.

## Server v1.6.534 published

This release packages immutable Web Console `1.6.189` and unchanged Engine `v0.183.348`.

The immutable Server producer is `52714c372b38ea0b6f56bb205fbdfb0a584707e1`. Official workflow [38663986172](https://github.com/PastureStack/server/actions/runs/38663986172) and readback of 24 assets passed without bypassing required checks. The linux/amd64 image has one runtime layer. Registry manifest: `sha256:e218bd31b39207c969f331aab097fd9773ef0071216e794f9a4bd23010d8fc96`. Distinct OCI config: `sha256:1d31677fbc05073830eaee66592a8c274edd7d4cf743c3c3371383b5e36bd7fd`. Artifact identity, not an installation command: `ghcr.io/pasturestack/server:v1.6.534@sha256:e218bd31b39207c969f331aab097fd9773ef0071216e794f9a4bd23010d8fc96`. Documentation commits do not replace the producer.

Immutable Web producer: `f30f5e81dd9ee25878c3aff681eed5bb61883453`. `web-console-1.6.189.tar.gz` is 3,024,592 bytes, SHA-256 `1c90e273b7db8ebf9d851a0ae1ec49dc59067b5ee1099ea3886919c1a79ccdfc`. Official publication and anonymous readback passed; later documentation commits do not replace this producer.

Official QA deployment and restart passed with preserved volumes and runtime overrides. The final 52-case matrix covers 13 locales, 1440px/390px widths and light/dark themes: 44 unaffected Web 188 results are carried, and eight fa-ir/en-us views were newly run on Web 189 after the step-circle RTL fix. These are not 52 new Web 189 runs. A separate ordinary-HTTP native copy was newly verified on Web 189 with the Clipboard API absent. Clipboard payloads matched exactly. Permission rejection was an explicit denial fixture, distinct from the real HTTP fallback. Preferences, presentation and clipboard were restored; page errors, missing translations and unexpected resource writes were zero.

Six new focused CSS cases passed for the exact shared step-list change, SVG geometry, generated LTR/RTL background and number alignment, both themes and version identities. Four actual-DOM cases added and passed on Web 188 are carried for native hover/leave, real static tooltip content, feedback success/failure, listener cleanup after destruction, action-menu overrides and host registration copy. The earlier thirteen clipboard/host cases and one corrected-caption rerun retain their original evidence; they were not replayed. The unchanged 32-key resource contract across 13 locales is carried from the same translation sources, not presented as a new resource run.

The official curl packages use Ubuntu's `8.18.0-1ubuntu2.8` security backport. The scanner feed still reports the 54 exact curl findings covered by evidence-backed OpenVEX `fixed` statements; raw findings are retained rather than reported as zero. The original 20 MEDIUM findings across 10 CVEs remain vendor-pending for review on 2026-10-20. See the release note for the exact package/PURL boundaries and unchanged gates.

Focused acceptance does not complete the broader role/backend/lifecycle matrix; historical HOLDs and deferred KVM cases retain their status. See the [release note](docs/releases/server-1.6.534.md).

## Server v1.6.533 published; RTL visual follow-up required

This candidate packages immutable Web Console `1.6.188`, source
`8e12216fd6f8d843ed043b4c0afcec995d33caeb`, archive SHA-256
`3467dfb37d7723b9293bc64145603d09ba24799ad726feb89177c9fa38b4ed92`.
Native non-bubbling pointer events are owned by the tooltip element lifecycle,
with run-loop entry and listener cleanup. Existing action-menu overrides and
static context forwarding are preserved. Four new actual-DOM focused cases
passed. Engine `v0.183.348`, APIs, registration, authentication, permissions,
networking and all other component inputs are unchanged. Official publication,
QA startup and restart passed. Producer: `6ef201a937500f894f8ec0f5a589cb7f796b66c3`.
Artifact identity, not an installation command:
`ghcr.io/pasturestack/server:v1.6.533@sha256:f5bc5eb860bec0d6477d03da7e02ee3c683d23c67e9a3d850d36a2a256fb6216`.
The distinct OCI config is `sha256:011862871af1ac207f3ba72ba68c51e41faf7cfc15527ad9ea321b0d339289e4`.
All 52 actual-browser clipboard views and ordinary-HTTP copy passed; subsequent
visual review found the existing RTL step background remained left while its
number moved right. This is not complete whole-page layout acceptance; the
alignment repair requires a new immutable component and Server patch.
See [the release note](docs/releases/server-1.6.533.md).

## Server v1.6.532 published; browser acceptance incomplete

This release packages immutable Web Console `1.6.187` with unchanged Engine
`v0.183.348`. Shared clipboard messages initialize before rendering and report
success/failure in all 13 supported locales. Copy hints fit the viewport; Custom
host commands remain LTR in RTL interfaces. Commands, registration APIs, native
navigation, permissions, OIDC/MFA, networking and other component pins are unchanged.

Thirteen focused rendered cases and one corrected-caption case passed; 32 keys
across 13 locales passed the targeted resource contract. The Web archive has
SHA-256 `b9797c08cf8c698e7cabac4bc9cd12fba0faa181c8781875d93a3de7109f2db3`
from signed normally merged source `b45f8ee73c72b5f58b010dd55c64d5aef7406c61`.
Its official immutable release and anonymous readback are complete. Server532
source is `77f1120f2b8796344ef1c2f8c4a6de8d54eb21fd`; exact artifact:
`ghcr.io/pasturestack/server:v1.6.532@sha256:28dc6b10cfa37843f3c737a4d3bc15bb4c180791fcb710f034d19150458456ce`.
The distinct OCI config is `sha256:cfeec9c242c0aa3952cbb01162a80bd374f742c27d9fee1a783c3f9841c2a8b4`.
Official publication, startup/restart HTTP200/pong and preservation checks passed.
Real-browser acceptance found missing native hover event dispatch after the
Ember upgrade, so532 is not a completed52-view acceptance.188/533 addresses it;
the matrix is not inferred from source tests.
See [the release note](docs/releases/server-1.6.532.md).

## Server v1.6.531 published

This release packages immutable Engine `v0.183.348` and Web Console `1.6.186`.
The shared Default uses the configured public Native project template; catalog
reload also repairs its empty binding when the template is already installed.
Existing bindings, custom settings and other projects are preserved. Definitions
may exist with zero hosts; service activation waits for an active host.
Native machine-driver cards display their distinct API names without changing
driver records, IDs, initialization or action targets. Catalog localization and
intentional empty display names are preserved. The personal API Key page,
owner RBAC, role schemas, HTTPS, MFA and provider/backend behavior are unchanged.

The immutable published producer is `aea01351c270133607bcc0104236c58ff91fc7fd`.
Official Server publication and immutable readback are complete. The registry
manifest for `ghcr.io/pasturestack/server:v1.6.531` is
`sha256:950a9cee2400c3ac0a97aac75e5ff278994d03293e28ac7c821b782e8bed48a4`.
Published artifact identity (not an installation command):
`ghcr.io/pasturestack/server:v1.6.531@sha256:950a9cee2400c3ac0a97aac75e5ff278994d03293e28ac7c821b782e8bed48a4`.
Installation examples use the released numeric `v1.6.531` tag; documentation
commits do not replace the published producer or image.

Fourteen focused Engine and four rendered Web cases passed, and both component
releases passed immutable readback. The isolated upgrade from Server 530
repaired an existing unbound Default and introduced no duplicate stacks, services
or drivers after restart. A fresh three-volume installation registered one host
through the public workflow: Default bound to template `1pt1`, with four core
stacks and six active, healthy services. Metadata, managed DNS, HTTPS egress
HTTP 200 and published host port `18297` to probe port `18080` passed. Readiness
survived Server restart, Docker restart, guest reboot with a changed boot ID,
and native API probe recreation from `1i15` to `1i16`.

Native Chrome 154.0.8037.98 confirmed eleven distinct driver IDs/names on v1 and
v2-beta, zh-tw/en-us at 1440px/390px, four generic icons without duplicate
records, and the same identities after restart. Page errors were zero, and all
five screenshots were visually reviewed. The published deployment and its
subsequent restart also passed. Narrow affected-path acceptance completed with
the existing host defaults and unchanged role logic; broader role/backend
matrices are outside this verification. See the [release note](docs/releases/server-1.6.531.md).

## Server v1.6.529 published

This release packages Engine `v0.183.347` and Web Console `1.6.184`.
Subscription terminal audit retains the first close/failure result, bounded
delivery retry and exactly-once physical cleanup without restoring authorization.
The console labels event subscriptions, including completion records without a
target ID; this adds no resource-picker or grant capability. Full/legacy behavior,
live restricted-Key checks, owner RBAC and audit bounds remain unchanged.

Thirty focused Engine tests and three focused Web unit tests, including actual
labels in all thirteen production locales, passed at the component level.
The immutable producer is `f0a1edd7258b4005c5b9fa205c1b93435f759583`.
Official workflow [38405824990](https://github.com/PastureStack/server/actions/runs/38405824990)
and immutable readback passed. The linux/amd64 image has one runtime layer;
its registry manifest is
`ghcr.io/pasturestack/server:v1.6.529@sha256:0e85f22039a17d114a0d86cf1b682063695773a09bf1a0c308baf32aa2ed394a`.
The distinct OCI configuration digest is
`sha256:00d56e427357b5e3f7517ebbb3ba3def64d022944f3ad2cb8e5ac8295067bdc2`.
Thirty-six native subscription cases passed with twelve local-MFA actors:
global admin, owner, member, restricted, readonly and no-access, two per role.
Full, Closed and global-read Custom admission, client-close audit, owner Custom
revocation and exact disposable cleanup were verified. Two unaffected passed
cases were carried, not replayed. No full matrix
or active-agent lifecycle PASS is inferred. Historical results below keep their
original release scope. See the [release note](docs/releases/server-1.6.529.md).

## Server v1.6.528 published

This release packages Engine `v0.183.346` and unchanged Web Console `1.6.183`.
Operation-specific lookups allow an authorized named export or registered action
to load its exact operand while ordinary GET/list, references, owner RBAC, scope,
deny precedence and expiry retain their existing boundaries. Method dispatch and
old queued-Key checks remain in force. Other components, role schemas,
authentication, broker, registration, HA and runtime settings are unchanged.
Container/Instance Link Stack ancestry uses total null-safe comparisons and a
unique-PK scalar marker, avoiding MariaDB's unsupported row/IN optimization.
No global optimizer setting is changed or read authority broadened.

The immutable producer is `cbd0a988d0cd2882842f4f2a8012af3f841b479e`.
The linux/amd64 image has one runtime layer. Its actual registry manifest is
`ghcr.io/pasturestack/server:v1.6.528@sha256:1d6bbc1081b5ead8cabcd3f72ff17bf3522d90d94ad97ed83add425a9880e42f`;
the distinct OCI configuration digest is
`sha256:d420681bc58de55239ae212b7d929d37e9eca2beb484a44d48368f609054fa0c`.
Original publication and immutable readback passed. Sixteen scoped Link/Container
direct/list hit/miss reads on both API roots passed with 32 matched audit events,
unchanged database snapshots and owned cleanup. The separate isolated QA upgrade
from Server526 and one restart preserved runtime settings and all three volumes.
Complete role/action/resource coverage remains separate.
See the [release note](docs/releases/server-1.6.528.md) for the exact scope.

## Server v1.6.524 published

The internal-lookup repair packages released Engine `v0.183.342` and unchanged
Web Console `1.6.183`. Internal reads necessary for an already-authorized
mutation do not grant external read/list or expand the owner's live RBAC.
Other components, role schemas, onboarding and HA behavior are unchanged.
The immutable published source is `cc52ce16363333ef77345ff768acddcdf839dde7`; the linux/amd64 image has one
runtime layer. Its registry manifest is
`ghcr.io/pasturestack/server:v1.6.524@sha256:0b4ae5f87ef54f25081d728e2ae5eda51ea093ab52768bb7451229ab512092ba`;
the distinct OCI configuration digest is `sha256:65061d2f1d4baf2b7e1fd75fe96cfcfaa4a0a22e251ac2ea7fd9ec4c74d61cd6`.
The final image passed 96 native update/delete and read-isolation cases without
adding read grants. Startup and restart preserved the existing runtime settings
and three data volumes. The complete role/resource matrix remains separate.
See the [release note](docs/releases/server-1.6.524.md).

## Server v1.6.523 published

The minimal HA backup release uses released Engine `v0.183.341` and Web Console
`1.6.183`. Dedicated registration-token Basic authentication is preserved.
Custom add-host requires RegistrationToken POST; built-in and Other drivers
require Host POST, using the current project's loaded native schemas.
Cancel / Go Back preserves the external return target across driver changes and
API-host settings refresh; missing or self-referencing targets return to Hosts.
Native project creation with legacy/full API Keys now binds initial work to the
actual manager-created project and rechecks ownership after that phase. Existing
roles and non-creation authorization, other components and the broker are unchanged.

HA dumps use the configured database connection and private temporary output.
Only successful, nonempty SQL output is committed to the ZIP response; failure
and timeout clean up owned files without returning CLI stderr or secrets.
Existing export authorization is unchanged.

Clean merged component source, official assets and the final image have been
verified. Publication run `38287883898` passed startup/restart, native MFA,
the seven-check registration entry gate, security, SBOM and provenance gates.
The image is linux/amd64 with one runtime layer, built from
`d20b39b896631b7e7e384ed9c60dc29080679f67`. Its registry manifest is
`ghcr.io/pasturestack/server:v1.6.523@sha256:ba9eddbdaa2d7b10c402f59f767de9b5728e48e69d07120c12d9e630c2d2d57a`;
the separate OCI configuration is
`sha256:02a25d1bd58e1ab4e7b8f7986bd0b7eb61e2c5c08a1034ebbae9209f5d4bfdec`.
Six native HA cases passed: both API roots returned complete SQL ZIPs for full
access and denied readonly/read-plus-export Keys. Twelve matching audit events,
unchanged protected resource snapshots, no export jobs and exact temporary
resource cleanup were verified. Full role matrix and deployment acceptance
remain separate gates.
Entry-only checks do not establish an active node or a full permission matrix.
Integration candidates are not this published release. See the
[release note](docs/releases/server-1.6.523.md) for component identities and scope.

## Server v1.6.521 published

The [official release](https://github.com/PastureStack/server/releases/tag/v1.6.521)
is the immutable image
`ghcr.io/pasturestack/server:v1.6.521@sha256:bd368b3ac58c7b161442906241aa7ef2a41360a164cb3ca181d0b84742fb2194`.
It packages Web Console `1.6.181` and Orchestration Engine `v0.183.337`.
The image has 22 layers; publication identifies producer
`d478d917f989903dafc6bb834b7f9017126a68bd` and protected-main merge
`d0d1b417833c25e4a6b765e27e3a52f450d7c0e1`.
See the [release note](docs/releases/server-1.6.521.md) for audit identity scope.
Install examples use the published numeric tag; immutable identities stay in
release records. This is not C-03, C-05 live or full-matrix acceptance.

## Server v1.6.518 published

Immutable image:
`ghcr.io/pasturestack/server:v1.6.518@sha256:4040180d74574b1e72710decb09874d29a32e45808658156753700b548c8647e`,
from signed source `7607f4d4cd64b3c99b8ed9faa809109ad49cf893` and successful
[publication run 37566647090](https://github.com/PastureStack/server/actions/runs/37566647090).
Public asset checksums, SBOM identity, the single runtime layer and fixed
FreeType `2.14.2+dfsg-1ubuntu0.2` were independently read back.

Pins published Catalog `v0.3.13` source
`b6b658888fce50d3ec217eb4eba0f26ab0113baf`, Network Services revision `10` / template `v0.3.8`,
and Network Plugin Manager `v0.8.22` for Metadata-driven CNI configuration
migration. After validating desired files, the manager atomically replaces
each file and retires only an unrequested old configuration matching the
exact legacy network/bridge/IPAM triplet. Its original contents remain in a
recoverable `.pasturestack-retired` copy outside the active CNI set. The
reverse Metadata transition supports rollback; unrelated administrator files
remain untouched. Replacement is atomic per file, not across the whole bundle.

Web Console `1.6.180` and the audit broker support explicit `timeScope=all`
for query/export without the implicit 24-hour range. Explicit dates still use
the existing half-open interval and 366-day maximum; authorization, environment
filters, 20,000-row scan cap, 10,000-row export cap and DB retention remain.
Publication and scoped isolated-QA deployment/read-only checks passed; this is
not full functional-matrix acceptance. Engine `v0.183.333`, Catalog Service `0.20.12`,
Authentication Service `0.4.42`, HAProxy, OIDC, four build stages and the single
final runtime layer flow remain.
VEX decisions, vendor-pending findings and review deadlines are not reset.
README/Compose install examples use published numeric tag `v1.6.518`; digest
identities stay in release records. Historical HOLDs and incomplete coverage
are not promoted to PASS. See [the release note](docs/releases/server-1.6.518.md).

## Server v1.6.517 published

Packages Web Console `1.6.179` with the official shell-quote `1.11.0` fix in
both dependency and browser vendor copies. Signed component source
`826bff55b8885efc9ff1faec0272ef442e4ff702`, archive SHA256
`1bb7e0acf7040738f2c6413046553609cbbaf14b833abb6ef2c7237b453eaf90`;
formal CI 37502593612 passed 851 tests and produced two identical archives.
Official Server publication run 37505065403 passed; signed source/tag
`352f1097c002224e84a1719a0df50e4ae4a1219a`, immutable image
`ghcr.io/pasturestack/server:v1.6.517@sha256:2bf411c5828b7090f9dab950942befcc22295c7dce9a5db2e3d2d6c9dfd2f7d8`.
Anonymous asset/manifest readback agrees. Isolated startup/restart, 34 MFA/API
checks and the artifact SBOM/scan passed: nine vendor-pending Medium package
findings / five CVEs, zero untracked/available-fix/Critical/High/secret findings.
The isolated QA host also passed pinned deployment: first start/restart (11/9
probes), unchanged runtime/environment/volume contracts and five core-table
counts. Real Authentik plus platform TOTP login using the existing OTP EXE,
five protected APIs (all 200), two WebSockets, zero passive token DELETEs and
one explicit logout DELETE passed. The loaded browser vendor rejects four
hostile line-terminator cases and preserves three legitimate round-trips.
This scoped acceptance does not promote historical matrix HOLDs or untested
hardware to PASS. Engine `v0.183.333`, Catalog `0.20.12`,
runtime contracts, four build stages and one final runtime layer remain.
Historical evidence is kept in release records; the concise README's current
install identity is checked against those records. Existing security review
deadlines, historical HOLDs and incomplete matrix/hardware evidence remain.
See [the release note](docs/releases/server-1.6.517.md).

## Server v1.6.516 published

Package published Web Console `1.6.178`, signed source
`60a494e943150ecd300d1aa653ee397f590b575b`, archive SHA256
`7d4476f3ae1ecd455d0de25008b62327d8c2fa02fafe2b5252ce79fb3309d981`.
Formal CI 37273270200 passed 848 tests; two archives and anonymous immutable
download agree. Only exactly inactive environments skip scoped network/policy
reads; global project/member reads and capabilities remain authoritative.
Other states, authorization errors, generation/mutex, OIDC and MFA are unchanged.
The new status hint exists in all 13 packaged locales. The numeric lightweight
tag binds the signed Web source commit; it is not a signed tag.

Server source is `e024e054be7371c60d719d0590ca3f5b86bdb6ee`; its immutable image is
`ghcr.io/pasturestack/server:v1.6.516@sha256:3741b7d87273387f36b49e44d407c240658db0ab7fc7fb8d518ae08f55ac733c`.
[Publisher 37275775509](https://github.com/PastureStack/server/actions/runs/37275775509)
and independent public artifact readback passed. Tag and immutable manifest
bytes, config/version/revision identity, checksummed release assets and SBOM
identity agree. Publication and isolated QA acceptance are separate evidence.
The actual isolated 516 deployment separately passed: first start and restart
each reached HTTP 200/pong after ten bounded probe attempts. Runtime settings
and five core-table counts have zero differences; the existing AppArmor,
three named volumes and `unless-stopped` policy remain. Docker health is null,
not healthy; no company-site deployment is claimed.

Image catalog defaults pin normally merged commit
`7670ffd81d5f0b5570197fb03c7e55b46da45bf3` (IPsec Overlay 12 / v0.14.38).
Explicit user catalog settings, existing template revisions and backend/plugin
ownership are preserved. Template visibility is not managed upgrade acceptance.
Engine 333, Catalog Service 0.20.12, four build stages and one final runtime layer
remain unchanged. VEX/vendor-pending changes only their release identity;
review deadline and findings are not reset. In one inactive environment, native
detail/reload, edit/remove cancellation, DELETE 200 and absence from the list
after reload were observed. The parent cleanup timeout remains HOLD. A separate
read-only database observation confirmed the environment and four networks were
purged, with no remaining members or dependent resources. Fresh API and complete
foreign-data preservation verification remain incomplete; this is not full
native lifecycle PASS. The full matrix is INCOMPLETE and historical HOLDs remain.
See the [release note](docs/releases/server-1.6.516.md) for exact artifact identities.

## Server v1.6.515 published

Package published Web Console `1.6.177` from signed source
`b9b841e65afe1d89a5b03ac767e9168bccd3c3ea`, archive SHA256
`4e34eb2b3165f078134cddcf1721239b3da7baf11dd683991b2d6aa5bae944e0`.
Its numeric lightweight tag binds this signed source commit; the tag itself is
not signed. Normal PR #175 merge `5d150806be20226657e5caa8a0150d068006c772`
has the same reviewed tree and a verified signature. Formal CI 37255121243 passed
841 tests, including 17 new regressions; anonymous archive readback matched both CI builds.
Ended logs/terminal entries cannot reconnect or accept late responses and old callbacks;
explicit new entries and live reconnects remain supported. Permission checks, API contracts,
workspace persistence, generation/mutex and MFA are unchanged.
Engine 333, Catalog Service 0.20.12, all other components/plugins, the pinned 460 base,
four build stages and final single-runtime-layer publication flow are unchanged.
Server 515 source is `f0267ff3a347ea526088db1749b1d3c8dfd9bd37`; its immutable image is
`ghcr.io/pasturestack/server:v1.6.515@sha256:fcc79f616927040ef2b3a5c58662fa948823220dbc57ffe275dee2ad88764d47`.
[Publisher 37256753740](https://github.com/PastureStack/server/actions/runs/37256753740)
and independent public artifact/runtime/security readback passed. Separate isolated
QA 515 / Web 177 deployment and readback passed: initial-start and restart polling
reached HTTP 200/pong after 10 and 11 attempts, respectively. Runtime configuration,
environment overrides, three named persistent volumes and five core-table counts
were preserved, with `docker-default`,
`unless-stopped`, database backup and 514 rollback retained. There is no Docker
Healthcheck: running/pong is not Docker healthy. Native lifecycle acceptance
remains pending; deployment readback is not native UI or full-matrix PASS.
A separate fresh Project v2 native run remains HOLD after a successful deactivate
response and a UI wait timeout. Native removal and database cleanup are incomplete.
Quick Start follows published 515; retain 514, configuration, named volumes and rollback backups.
The complete matrix remains INCOMPLETE; historical HOLDs and 514 evidence are unchanged.

## Server v1.6.514 published

Package Catalog Service `0.20.12` from verified main CI `37177694304`, source
`d708579092eae0fd03b2750ac594ff0396cf563b`; 39 integration cases passed twice and archives
are reproducible. Official publication run `37178033799` succeeded; anonymous public
readback verified two asset bytes, both binaries, source LICENSE and immutable coordinates.
Publication receipt SHA256 is `552ba8ab75e5379e462a44b03dc94d21b32e75476bd768db3d11cfee25d666de`.
Exact component hashes are recorded in the release notes.
Skip root `.git` metadata, reject invalid revision folders before allocating a template,
and rebuild an empty/unnamed cached index within the existing catalog transaction.
The cache check is scoped by catalog name and environment; another catalog cannot satisfy it.
Startup refresh can rebuild an affected catalog without a source commit change. Database
and API template IDs may remap; catalog origin, template keys, versions, content and labels
must be preserved and checked independently of those IDs.
Back up persistent data before upgrade and keep the old image and backup for rollback.
No SQL repair, live binary override, role change, authentication change or firewall change.
Web Console `1.6.176` repairs 21 native-select `mut` bindings through the existing
invokable function contract, including project member-role edits. Permission checks,
identity metadata and Web175 image-error handling remain unchanged. Component and native
DOM/model/save verification are required; hiding the timeout alone is not acceptance.
Engine333, four build stages, the final one-layer image and all unrelated pins remain.
Server514 source is `076aa43c6b978dfe65cd0fb3a05efc97ec5d02dd`; its immutable image is
`ghcr.io/pasturestack/server:v1.6.514@sha256:45712644bc11325df927d10bdbab47421168cc3c512eb5f2a51d85020671a71f`.
[Publisher37179046649](https://github.com/PastureStack/server/actions/runs/37179046649)
and independent public artifact/runtime/security readback are recorded in the release notes,
with receipt SHA256 `59340dd9c4b365df3e08633d71be66b56640e7d9cc673a79670c78c7739b2d70`.
Quick Start follows this exact published514 identity. QA125/8080 now runs514/Web176;
first-start11/restart9 probes returned HTTP200/pong, runtime settings, volumes and five
core-table counts were preserved, with512 retained for rollback. Two real read-only catalog
migration captures agreed:12 blank Git stubs and2 README-only entries were removed while
valid origin/template/version/content/label semantics were preserved. Native UI and the
full resource/role/locale/layout matrix remain INCOMPLETE, not PASS. The image has no Docker
Healthcheck; running/pong must not be reported as Docker healthy.
Traditional Chinese/English native VM/container forms passed eight cases and
two INIT toggle/restore checks without creating resources or starting a VM;
other locales, GPU hardware and VM runtime remain unverified.
Historical513/512 publication and rollback records are unchanged; no zero-CVE claim is made.

## Server v1.6.513 published

Server `v1.6.513` packages 正式 Web Console `1.6.175`：
映像補正／語系切換同步表單自有 required 錯誤，保留非映像錯誤及後續 backend save 錯誤。
正式 source `bb905d092700c262497b88f5773e7714fc1f4be4`、
tree `b2b38347e5fa24bd945706fd2aaab0136ea4ef45`、
[CI37163340764](https://github.com/PastureStack/web-console/actions/runs/37163340764)
821／821、fail／skip／todo 0；兩 production archive 一致，簽章數字 tag 及匿名讀回已核對。
公開 archive 2982158 bytes，SHA256
`9833467b2be47d4fa01f09954fcd35beb292c59d382d5c1aecd76d17c6a387a2`。
Publication receipt SHA256 為
`a177e4d2a20bff51b18c8f233e87672a3f343ff5a1df12edcc57771ae41ba125`。
Server513 source 為 `eefc84d670188f8d81978d6ce600d1c0400fe720`，正式不可變映像為
`ghcr.io/pasturestack/server:v1.6.513@sha256:d6df82fe1ec29d720af47fe62ec83dcf0f96ce1b0dcfc00059363f8621dc61ab`。
[Publisher37164995463](https://github.com/PastureStack/server/actions/runs/37164995463)
與獨立公開讀回通過：23 assets／22 SHA-256、SBOM來源／digest／版本及單runtime layer，
隔離首次啟動13次／重啟7次後HTTP200/pong、34 MFA/API、TLS1.2／1.3、
不信任TLS憑證拒絕與private API `no-store`。這些是正式成品驗證，不是QA部署／UI PASS。
Engine333、460 base、四 build stages／單 runtime layer、其他 component／package pins、
原生 save／payload／角色／OIDC-MFA、ENV／volumes／AppArmor 契約不變。
VEX51 exact-set 與 vendor-pending severity／available-fix／untracked／secret 門檻不放寬，
513 actual scan raw52／VEX51，vendor pending為8 Medium package findings／4 CVEs；
untracked／Critical／High／available-fix／secret均0，2026-10-20 review deadline保留，不宣稱零CVE。
No migration or runtime patch is required.
Quick Start指向已發布513 exact digest；QA目前仍512，513尚未部署，
舊512／511發行、rollback與 scoped/HOLD 證據不升格，full matrix INCOMPLETE。
原生UI／角色／語系／版面及VM開機仍待本版實機驗收。
詳見[已發布發行說明](docs/releases/server-1.6.513.md)。

## Server v1.6.512 published

Server `v1.6.512` packages Web Console `1.6.174` 的VM映像表單防呆與缺映像訊息。
只移除全新VM的一般容器預填／quick picks，保留自訂／initialValue／last-used、
一般容器預設及原生required／willSave語意；不改Engine、schema、角色或VM runtime。
Web174正式signed source為 `d24b7f4e164f058e3ef9057347caa2080e2b5407`、
tree為 `c408e8b018d99db2ca228203880f4e72663ab1b7`。
[正式CI37152802665](https://github.com/PastureStack/web-console/actions/runs/37152802665)
通過817／817，fail／skip／todo為0；
[數字tag `1.6.174`](https://github.com/PastureStack/web-console/releases/tag/1.6.174)
已簽章發布，匿名公開archive原bytes與CI一致，2982022 bytes，
archive SHA256為 `6408775898f412e4b27092eeddd9cdc2028ad7b27835f489139c2d0cf62c6776`。
獨立publication receipt SHA256為 `aa79ea915bb8d6de4542b1095c35e39479af4d6c24e7b7d9cd2e28ffbf08f603`；
此為Web component讀回，不代表完整功能矩陣 PASS。
Server512 source 為 `c533ac7753d222abb515848effc27d007bd700b6`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.512@sha256:805078de83c0320c751dff90304bd841b8e64bec720079198258d22fa41d0145`。
[正式 publisher37153784888](https://github.com/PastureStack/server/actions/runs/37153784888)
及獨立公開讀回通過：23 assets／22 SHA-256、單 runtime layer、
隔離首次啟動12次／重啟8次後 HTTP200/pong、34 MFA/API、TLS1.2／1.3、
private no-store 與不受信任 TLS 憑證拒絕均核對。這些不代表全部實機操作或權限已驗收。
實際 merged-rootfs scan 為 raw52／VEX51、8 Medium package findings／4 vendor-pending CVE；
Critical／High、available-fix、untracked 與 secrets 為0，不宣稱零 CVE。
Engine333、460 digest-pinned base、四build stages／最終單runtime layer、其他component pins、
runtime ENV／volumes／AppArmor、VEX51 exact-set、vendor-pending門檻與2026-10-20期限不變。
No migration or runtime patch is required.
Quick Start 對齊512已核實公開digest，511仍為歷史rollback參考；
歷史HOLD及full matrix INCOMPLETE不升格。
詳見[已發布發行說明](docs/releases/server-1.6.512.md)。

## Server v1.6.511 published

Server `v1.6.511` packages Web Console `1.6.173` 的原生Project
Template卡片名稱修正：使用模型既有 `name`，不依賴未實作的 `localizedName`。
Web正式source為 `c8b8bb2659fdad3539cf6a72866c94a77ec516b6`，
tree為 `f590310e157edea79de81fcf333e8b39dbc5677e`。
CI `37115288389` 通過812／812，fail／skip／todo為0，兩次production成品一致；
CI archive SHA256為
`a566684e6e0831630a15cb7212989c0e9fe707ed07965156c2b664b9cdb5ba27`。
Web數字tag `1.6.173` 已簽章發布，匿名公開byte讀回與CI SHA256一致；
Server source為 `e995f8f35bc6335effaceb6c973f7915c68df2ab`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.511@sha256:bce474ce4403398044a7c24aafe6c8314bac38b44731540c5ffaa2dfc40699cd`。
正式publisher37116124788與公開讀回通過：23 assets／22 SHA-256、單runtime layer，
隔離首次啟動13次／重啟9次後HTTP200/pong、34 MFA/API、TLS1.2／1.3、
private no-store與不受信任TLS憑證拒絕均核對。
Engine維持正式 `v0.183.333`，460 digest-pinned base、單runtime layer驗證、
角色／schema／登入／production環境／持久volumes契約與安全門檻保留。
No migration or runtime patch is required.
Server511實際scan保留raw52 findings、VEX51 statements、8 Medium package findings／
4 vendor-pending CVE，review 2026-10-20；Critical／High、available-fix、
untracked與secrets均為0，不宣稱零CVE。Quick start採本版已核實公開digest。
QA125/8080升級與獨立只讀核對通過：首次啟動11次／重啟10次探測後HTTP200/pong，
既有binds、environment、`unless-stopped`、`docker-default`與五項DB計數不變。
映像未定義Healthcheck，不宣稱Docker healthy。
當版既有Template117原生只讀proof已通過：3 Full17/14 guards、0資源寫入，
source-bound proof核對同一ID及空stacks/services；這不是native create finalizer。
當版Process原生list/link/detail及同一ID direct GET只讀驗收通過：兩API roots×六角色
共12/12格、0資源寫入；僅涵蓋一個實際ID，不代表所有ID或write操作。
當版全新Project key `1c6998` 已獨立核對為
`DERIVED_SCOPED_KEY511_VERIFIED_NOT_ORIGINAL_PASS`：同一次實機child有4筆原生寫入、
13 guards、6筆停用／刪除前cookie-free issued Basic GET、4 barriers及18項首次交付判斷。
原parent的QA receipt identity schema失配HOLD不重寫，只讀derived核對沒有重跑寫入；
詳見[發行說明的證據與範圍](docs/releases/server-1.6.511.md)。
Project與Host原生流程仍獨立pending，完整矩陣 INCOMPLETE；不以key scoped結果升格。
既有版本的scoped PASS與歷史HOLD不重寫或升格，公司站不部署。

## Server v1.6.510 published

Server `v1.6.510` packages Web Console `1.6.172` 的 create-only first
delivery，Engine保留正式 `v0.183.333`。canonical store 只保存正常資源身分；
首次201限定欄位由 request-local delivery 交給本次非 canonical modal clone。
Web172正式 source／archive 已固定並匿名讀回，808／808測試通過。
Server正式 source為 `1a323f5f690ed89a4f03e7ead1ad2e51ddeb4fdf`，映像為
`ghcr.io/pasturestack/server:v1.6.510@sha256:82e4ee7fa51dae3fb6b1f339ee794d17b593f6feae2fd313ef5354ccaaf2d89f`。
正式 publisher37110936143與公開讀回通過：23 assets／22 SHA-256、單 runtime
layer、34 MFA/API、首次啟動／重啟、TLS、SBOM與成品scan均核對。
QA部署及新key create／edit／deactivate／delete尚待原生驗收，不宣稱生命周期PASS。
No migration or runtime patch is required.
460 digest-pinned base、單 runtime layer、role/schema、登入、production環境變數與
volumes不變。510成品scan保留raw52、VEX51與8 Medium／4CVE
vendor-pending exact-set（review 2026-10-20）；不宣稱零CVE。
509正式digest、6974／6977 scoped closures、6982 HOLD與active保留資源不重寫或升格；
公司站不部署，完整矩陣仍 INCOMPLETE。

## Server v1.6.509 published

Server `v1.6.509` 已正式發布，封裝 Web Console `1.6.171` 與
Engine `v0.183.333`。create-only 欄位僅限真正的 POST create response，
不包含 POST action；既有首次 API Key 金鑰交付、角色授權、所有 frozen
schema、登入、防火牆與持久資料契約保持不變。

No migration or runtime patch is required.
Engine CI273 suites／1164 tests、隔離啟動與正式元件六檔讀回已通過。
Server source 為 `261bb23c980f5f896375923233e36f6554b99751`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.509@sha256:d934c9d7bc7387626fedca5d403210fac70b7b4e35e334dcdb439f79f555ab87`。
正式 publisher `37105881483` 與公開成品讀回通過：23 assets／22 SHA-256、
public tag／digest／config、單 runtime layer、34 MFA/API、首次啟動／重啟與TLS均核對。
成品 raw52 findings／VEX51 statements、8 Medium package findings／4 CVE exact-set 保留；
Critical／High 為0，安全門檻不放寬，不宣稱零CVE。
QA8080 的509部署與唯讀驗收通過：首次啟動13次、重啟9次重試後均為200 pong；
環境變數、執行設定與五表筆數不變，508回復容器與資料庫備份保留。
owner2513 的 Account6974 續接scoped PASS：本次PUT200／deactivate202／DELETE200，
3筆原生寫入／9個full16及14API守門，cleanup=true；508 POST201與HOLD保留。
Project6977 續接移除scoped PASS：本次僅DELETE200／4個守門，cleanup=true；
508已知POST201／PUT200／deactivate202不能拼成509新4writes或整案PASS。
全新Project key第二次僅POST201建立1c6982，3個守門與Store barrier通過，
Web171首次交付timeout而HOLD；未執行issued Basic讀取／edit／deactivate／delete，
active資源保留、不自動重試或清理，第一次0資源寫入HOLD不升格。
Web172修正尚未包含在509不可變成品，不宣稱原生首次交付已修復。
Host原生註冊／healthy／停用／移除仍pending；空template首次0writes／0guards HOLD，
guest或fixture不能建立Host PASS。上述結果不代表Docker healthy、公司站部署
或完整權限／語系／版面矩陣通過。
508 scoped PASS 與歷史 HOLD 保持原版本及原狀態，不升格為509證據。

## Server v1.6.508 published

Server `v1.6.508` 已正式發布，封裝 Web Console `1.6.171`。
Server source為 `69744f3ef0c00c14147fb83480306e07ccb667d9`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.508@sha256:e24f9993593bb609a7a0e26dc12fbbb21ab402b73c60af28955b988b83b6ac04`。
正式publisher `37095694250` 與公開讀回通過：23 assets／22 SHA-256、
public tag／digest／config、單runtime layer、34 MFA/API、首次啟動／重啟與TLS均核對。
正式成品讀回不代表QA部署、Docker healthy或native Volume驗收。
Web signed source 固定為 `fc37f5af9320e492bec7e7244cd62144908b720e`；1.6.171 已正式發布。
公開 archive SHA256 為 `49fac41ca93eb628d0877104f9512ef382ffd9dbc89e04c940196b3a9c57798b`，
CI `37094728912` 通過802/802，含10項新回歸、100次barrier與22項audit self-tests；CodeQL通過。
API-store compatibility revision 5 的 canonical adoption 僅限新建 POST201、
精確 type／server-generated ID、同 Store／generation／base URL；action 清除 createIdentity。
無相符 cache、GET／PUT／action／非201／204／errors 維持原語意，沒有狀態／時間排序 heuristic。
Engine保持 `v0.183.332`，WAR SHA256為
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`；
API／Auth／CRUD、pool/mount證明與部署／回復參數不變。
8個 MEDIUM package findings／4 CVE、51個 VEX statements 與安全 exact-set 不放寬。
Web建置audit仍為7 High／3 Moderate／0 Critical，精確上游待補風險複核至2026-10-10；
這不是零CVE或runtime整體不受影響的宣告。
QA8080已部署508，首次10次／重啟9次HTTP200/pong；runtime、environment及
五表counts差異0。三named volumes、AppArmor、restart policy與507回復點保留；
health=null，不宣稱healthy。Registry member生命周期分項通過（5次原生寫入及
2次API憑證收尾），英文憑證必填驗證／取消零寫入通過。原生Volume同ID生命週期
已可追溯續接通過：POST201／DELETE200、readonly兩版DELETE405、no-access兩版
GET／DELETE403，繁中／英文可讀拒絕與取消、刪除、刷新終態皆核對。
16個生命週期守門區分12個既有證據與4個本次守門；no-access API既有4請求／9守門
與本次零API請求／5畫面及終態守門分開，不重送已完成請求，不追認歷史HOLD。
完整矩陣INCOMPLETE。
508發布時的Quick start曾對齊其完整不可變映像；507歷史來源、HOLD與scoped PASS不拼成新版本整體PASS。

Server `v1.6.507` 已正式發布，封裝
Web Console `1.6.170`（source `09df1480c5f4b58c6a9a9060ff94d980792f7015`）。
範圍僅 nullable Volume 關聯欄位的前端分類相容性；Engine `v0.183.332`／
原 WAR、API／Auth、角色授權、pool/mount 證明、部署參數與安全門檻保留。
正式 CI archive SHA-256 為 `900974b07bb20ba5b2e7c1dede7012a53c6e2c96cd094c67cb7019434c4f27c9`；
Web170 與 Server507 已正式公開；Server source 為
`34287791861643ba93edd9923fa11dd504172f60`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.507@sha256:c0ee312207e38f4e31b8503521c0e43cbf178110e91fac61c23056026603c91e`。
publisher37083174895及23 assets／22 SHA-256、單runtime layer、34 MFA/API、TLS、
SBOM與安全門檻均讀回；QA／原生驗收另行記錄，不借用506證據。
完整矩陣仍 INCOMPLETE，506 已發布／部署實績及歷史 HOLD 保留。
QA507首次9次／restart8次HTTP200/pong，runtime／環境參數／五表counts差異0，
原named volumes、AppArmor、restart policy與506回復點保留；health=null。
首輪QA根分割區滿的HOLD不追認，新部署通過3GiB空間及本機精確image守門。
本版兩筆既有隔離Volume已通過原生Store／列表／刷新、取消零寫入、
唯讀兩根DELETE405、owner原生DELETE200及終態消失；新建仍在追查。
主機新增入口三低權限角色的繁中、英文拒絕分項通過，無資源或註冊Token寫入。
這些不是全矩陣、主機註冊或完整多語系版面PASS。精確清除10個停止的舊Server
容器後，保留507與最近506回滾點，主機UI重新登入／刷新無舊重複項目；VM與資料卷未刪除。

Server `v1.6.506` 已正式封裝 Web Console `1.6.169`，將本機 Volume 的
`externalId` 視為識別碼而非配置綁定。完整 pool/mount 關聯、主機／image／
instance null binding、環境 schema 與 API 授權保護均不變。Engine 保持
`v0.183.332`，不涉及資料遷移、認證或防火牆變更。正式 source 為
`3cfb920a428fc2af6af6a07a832d6882663f544d`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.506@sha256:f6860a1d0e96587b05afbf72d52c063921ff8473a976552c6d0a01d223a7a188`。
publisher37079727511已通過；Web169正式CI791/791。QA8080部署完成，首次11次／
restart9次HTTP200/pong，runtime／environment／五表counts差異0，505回復點保留；
health=null，不稱healthy。原生生命週期及完整角色矩陣另案驗收，不以正式成品或來源測試代替。

The packaging migration preserves established database schemas, API paths and fields, event names, environment-variable aliases, service names used by stored data, container labels, filesystem upgrade paths, and bootstrap contracts.

已發布的 Server `v1.6.505` 封裝 Engine `v0.183.332` 與既有 Web Console `1.6.168`。
Server source 為 `400f7dc8d533a5f13a555398c595b9ae42e0c454`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.505@sha256:b3dd402cfd773b4d37ecf06f716187833e56cc6f211b7ab920dccf8dcb7366c5`。
正式 publisher `37072151759` 及23個 assets／22項 SHA-256、公開 image/component
identity 讀回通過。隔離映像首次啟動／一次重啟均 HTTP 200/pong，分別在第10／6次
探測取得；34項 MFA/API、TLS、單 runtime layer 與成品 SBOM／安全門檻通過。
這些是正式成品證據，不是 QA8080 部署、Docker healthy 或原生 Volume PASS。
本次 API/schema 有窄幅相容性補齊：v1 與 v2-beta Volume 恢復 server-owned
唯讀 `isNative`。客戶端不能寫入該欄位；其他欄位、methods、完整 actions、
角色限制及環境隔離不變，無資料庫 migration。8080 的實際 504 schema 讀回
證明兩個 API 根都缺漏分類，補充更正先前只歸因於 v1 驗收工具的診斷；
原始零資源寫入 HOLD 不改成 PASS。Engine 正式 source 為
`7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295`，WAR SHA-256 為
`31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5`；
正式 CI 通過270 suites／1,150 tests，failure／error／skip皆為0，含6個新增回歸。
QA8080 已部署本版並完成一次重啟；HTTP 200/pong、runtime／環境參數與
五項資料筆數保存，504 回復點保留。Docker health 為 `null`，不稱為 `healthy`。
原生建立／列表／取消／刷新／刪除仍在驗收，完整資源／角色矩陣尚未完成。
未配置 local Volume 的 `inactive` 是合法狀態，原生清單不要求 `active`；
移除須核對當次 action 與空關聯，不要求額外 activate／deactivate。
部署環境、掛載、restart、AppArmor、HTTPS origin、OIDC/MFA 與 firewall 契約保持。
Vendor-pending 8個 Medium package findings／4個 CVE、2026-10-20複核期限、
VEX 51 statements 與安全門檻不放寬；正式發行不代表零 CVE或完整矩陣 PASS。

已發布的 Server `v1.6.504` 固定封裝 Web Console `1.6.168`；Web tested source／
archive、SSH-signed numeric tag 與 Server 正式成品均已讀回。Server source 為
`e33ef8565ebe40dd188170baa46da8092fc131b9`，不可變映像為
`ghcr.io/pasturestack/server:v1.6.504@sha256:11393d4a5189601464d2a2e1ffc823160bedd6bda6c1fbae12457337f7cb9e2f`。
正式 publisher `37063207602` 與 23 個公開 assets／22 項 SHA-256 驗證通過。
測試環境首次啟動／重啟均 HTTP 200/pong，runtime、環境參數、既有掛載及五表
counts 無差異；503 回復容器與資料庫備份保留，health=null，不稱 healthy。
安裝指引已對齊本版；正式公司站未部署或修改。

Volume 的新增 CTA、直接新增路由及既有 update 路由都要求目前 project 與
schemaProjectId 相符；建立仍須實際 schema 的 POST 能力，update 原有 PUT
判斷保留。獨立未配置 local 區段及原生 Add 不依賴任何 pool 存在；列表以
實際 GET storagePools 完整 collection 與包含 inactive mounts 的完整 scoped
mount cache 判斷，避免將停止工作負載仍持有的 Volume 當成未使用。
原始403、network／sync error 保留並交既有 route／growl 診斷，不轉成空關聯。
只有目前 project/schema 相符且當次資源 advertised deactivate 才原生停用，
active→detached 後沿用既有 advertised remove／原生刪除，不另造清理 API。

API/schema、後端授權、資料／state 語意、Engine `v0.183.331`／exact WAR、
session ownership、OIDC/MFA、部署參數、相依套件、安全門檻及多階段／單 runtime
layer 契約不變；無需 migration 或 runtime patch。Web168正式CI `37061716638`
通過788／788個 QUnit案例、fail／skip／todo皆為0，包含16個 scoped Volume案例；
兩次production archive一致。上述 component 與成品／部署證據不代替原生
建立／列表／清理或完整矩陣 PASS。首次原生驗收在任何資源寫入前，因工具
誤要求 v1 schema 的 isNative 欄位中止；原 HOLD 保留，原生驗收仍待完成。Vendor-pending
8 個 Medium package findings／4 個 CVE、reviewAfter、VEX statements 與 policy
保留；正式504僅同步必要的 release-coordinate metadata，不放寬任何門檻。
詳見[發行說明](docs/releases/server-1.6.504.md)。

Published Server `v1.6.503` packages immutable Web Console `1.6.167` for
schema-only ID lookup normalization. It does not change API schemas, server
authorization, ordinary resource IDs, project-store isolation, Engine
`v0.183.331`, authentication/session ownership, MFA or runtime/firewall settings.
Missing schemas do not grant capabilities. No migration or runtime patch is
required. Web source `dff35fc4bce340e21cac7204146a7bcb20a7b60b` and archive
SHA-256 `e8e714fc06282de75a3570aac1d4d4d04a3c9478d982d0d5aaeae14efa8ebbaf`
match the immutable component publication. Its validation passed 772/772 tests
with zero failures, skips or todo, including four actual Store/schema cases,
and produced byte-identical production archives. Official publisher
37015013747 passed isolated startup/restart, 34 MFA/API checks, TLS,
exact-rootfs single-layer comparison and final-image SBOM/security gates.
Anonymous registry and all 23 release assets match Server source
`df061d5c93d0e4fdbc0e06664493ac5328a6f596`; the public image is
`ghcr.io/pasturestack/server:v1.6.503@sha256:4a8997768c5c16a9aefdc682f906aab34417e204d622d03116e62b2fcfe0af79`.
Eight Medium package findings covering four CVEs remain vendor-pending until
review on 2026-10-20; publication is not a zero-vulnerability result.
QA deployment passed first start and one restart with HTTP 200/pong after nine
attempts each. Runtime settings, environment overrides, named mounts and
five-table count baselines were preserved; the prior immutable Server502
rollback and database backup were retained. Docker health is `null`, not
`healthy`. Packaged exact-fixture QA confirmed GET-only registry/credential
models for the readonly role and denied all 24 normal-CSRF v1/v2-beta writes for readonly/no-access
roles, with the existing readable permission errors. That bounded result does
not establish all API authorization, thirteen-locale or lifecycle acceptance.
Existing 502 HOLD results are not promoted and the complete matrix remains
INCOMPLETE. See [the release notes](docs/releases/server-1.6.503.md).

Published Server `v1.6.502` packages Web Console `1.6.166` for the shared
inactive-state display label in thirteen supported catalogs. Only display
translations and component/release pins change; Engine `v0.183.331`, its exact
WAR, API/schema, authorization, session ownership, OIDC/MFA, icon/color and
state semantics, deployment overrides and firewall contracts are unchanged.
No migration or runtime patch is required. Official publisher 37003831065
passed startup/restart, 34 MFA/API checks, TLS, exact-rootfs single-layer and
final-image SBOM/security checks. Anonymous registry and 23 release assets
were verified against the immutable publication. The public image is
`ghcr.io/pasturestack/server:v1.6.502@sha256:ee6d0141574280473cb27a638814ae924b3d5bfe344f1ee0e1741aae0f3efddb`.
Eight Medium package findings covering four CVEs remain vendor-pending.
Component validation passed 768/768 tests, including eight state/date rendering
cases; it does not establish all packaged UI, resource/role or layout cases.
The QA upgrade and one restart returned HTTP 200/pong with unchanged runtime
configuration, named mounts and account/credential/setting/membership/host counts;
the prior immutable 501 container and database backup were retained. This is
deployment preservation evidence, not native-browser or role-matrix acceptance.
The full permission/resource/locale matrix remains INCOMPLETE. See
[the release notes](docs/releases/server-1.6.502.md).

Published Server `v1.6.501` packages Web Console `1.6.165` to keep complete
container names readable on Host cards without shrinking IP/action areas.
The shared subpod layout alone changes; real names/IDs, API permissions,
authentication/session ownership, Engine `v0.183.331`/exact WAR, database
schema, Compose overrides, named volumes, AppArmor, restart and nftables
contracts remain unchanged. No migration or runtime patch is required.
Web source/archive are pinned in the build and verified by actual 767/767 CI
cases with identical production archives. Publisher 36980705366 passed,
including single-layer comparison, startup/restart, 34 MFA/API cases,
TLS and exact final-image SBOM/security checks. Public digest is
`ghcr.io/pasturestack/server:v1.6.501@sha256:0a671e2695eecc74d79ef666267a40e81172205f0f8b1d0b12a7dbbed446becd`.
Native QA initial/reload accepted six exact Docker IDs and complete names,
including distinguishing rollback suffixes. Actual menu open/close, separate
IP/action areas and both screenshots passed scoped review, with zero resource
writes or page/console/loading errors. One restart preserved runtime settings
and database counts. The historical 500 visual HOLD remains unchanged and the
full permission/resource/locale matrix remains INCOMPLETE. See
[the release notes](docs/releases/server-1.6.501.md).

Published Server `v1.6.500` packages Engine `v0.183.331` to accept only the two
stable imported-container lifecycle pairs, running/active and stopped/inactive,
in both selection and the name-only full-row CAS. All existing ownership,
full Docker ID, active Host/Agent, unique mapping, managed/service exclusions,
role/schema denials and deployment/authentication contracts remain unchanged.
No migration or runtime patch is required. Engine source is
`515a5d37a1194f827bc3ffde34db729905ecb2b1`, with exact WAR SHA-256
`0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e`.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.500@sha256:7ffd67a7f82da0d374d7846b97b5a2fb71647ad01a159120418544591899f5f5`,
from source `abdee460eb67c8cd02a2db8e9a55b15f58020d83` and successful
[publication run `36973764295`](https://github.com/PastureStack/server/actions/runs/36973764295).
Exact public asset/image/component readback matched. The unchanged merged-rootfs
gate retains 52 raw findings and eight Medium vendor-pending package findings
(four unique CVEs), with zero untracked, Critical/High, fixed-available or secret
findings; this is not a zero-CVE claim.
QA500 first start/restart returned `HTTP 200` / `pong` (nine and 10 attempts).
Runtime-contract and tracked five-table count differences are zero; original
environment overrides, three named volumes, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved. Docker health is `null`, not
Docker `healthy`; count equality is not a whole-database comparison. The
previous Server499 rollback is retained and stopped. Native Host1 initial/reload
checks matched five unique full Docker IDs, names and links, excluded removed
mappings, and observed a forwarded WebSocket server message without resource
writes or browser/console errors. Screenshot review still found indistinguishable
truncated rollback names, so visual acceptance remains HOLD pending a scoped
Web Console layout correction; the full resource/role matrix
remains INCOMPLETE. No company-site, all-page or all-locale acceptance is claimed.
See [the release notes](docs/releases/server-1.6.500.md). Historical 499 name
failure and browser HOLD below remain unchanged and are not promoted to 500.

Published Server `v1.6.499` packages Engine `v0.183.330` from source
`3f7320a8063a5471618be5b8be6a168f49559847`, with exact CI WAR SHA-256
`c01cbbfd63625fc09f39c5494775919aad6db22c92050b217b28b940b57e1de3`.
Only eligible standalone imported-container names are synchronized to fresh
full-ID Docker names; managed-service logical names remain unchanged. No
database-schema or stored-data-format migration is introduced. Web Console
`1.6.164`, Engine329 role/schema protections, Compose, mounts, OIDC/MFA/session
ownership, runtime base and security thresholds remain unchanged. Engine330's
signed release, exact CI assets and isolated H2 startup passed. The immutable
Server image is
`ghcr.io/pasturestack/server:v1.6.499@sha256:8552137dd4e40bf20dee5524cabf09540ed7431328e584ca1e488065e6fec394`,
from source `0a656e617c51059b92fb37a9b0571f142e8463aa` and successful
[publication run `36969193015`](https://github.com/PastureStack/server/actions/runs/36969193015).
Exact build/flatten and isolated first start/restart `HTTP 200` / `pong`
(12 and eight attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks passed;
untrusted certificates were rejected. Public assets/image/SBOM readback matched.
The unchanged merged-rootfs gate reports 52 raw findings and eight exact Medium
vendor-pending package findings (four unique CVEs), with zero untracked,
Critical/High, fixed-available or secret findings; this is not a zero-CVE claim.
QA499 first start/restart returned `HTTP 200` / `pong` (nine attempts each), with
original environment overrides, mounts, AppArmor and restart policy preserved;
runtime-contract and tracked five-table count differences are zero. Docker
health is `null`, not Docker `healthy`. Targeted name acceptance remains failed:
Engine330 rejects normal stopped/inactive instance/mapping pairs. Retained
rollback containers were not deleted or manually renamed. The browser HOLD
and this product defect remain recorded pending a new immutable correction;
these results are not full-matrix or company-site acceptance. See
[the release notes](docs/releases/server-1.6.499.md). The published 498
evidence below is historical to that release and is not promoted to 499 proof.

Published Server `v1.6.498` packages Engine `v0.183.329` and Web Console `1.6.164`.
Readonly/restricted GenericObject key/resourceData visibility changes in both
API versions; privileged roles retain those fields. Use typed plugin APIs for
safe low-role configuration reads. No stored-data migration, authentication,
session, Compose/AppArmor/nftables or Web Console version change is introduced.
The immutable image is
`ghcr.io/pasturestack/server:v1.6.498@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7`,
from source `ea58d92167eef31b76c7616f41df4d515530c359` and successful
[publication run `36954622994`](https://github.com/PastureStack/server/actions/runs/36954622994).
Exact build/flatten, isolated first start/restart `HTTP 200` / `pong` (10 and six
attempts), 34 MFA policy/API checks and TLS 1.2/1.3 checks passed; public
assets/image/SBOM readback matched. The final one-layer merged-rootfs scan has
52 raw findings and eight exact Medium vendor-pending package findings (four
unique CVEs), with zero untracked, Critical/High, fixed-available or secret
findings. This is not a zero-CVE claim. The exact Engine329 WAR's normal CI
executed 266 suites / 1,123 tests with zero failures, errors or skips.
The recorded QA498 `8080` upgrade ran the immutable 498 image / Web Console `1.6.164`.
First start/restart returned `HTTP 200` / `pong` (11 and 10 attempts); runtime
contract and tracked five-table DB-count differences were zero. The original
three named volumes, environment overrides, `docker-default` AppArmor and
`unless-stopped` restart policy were preserved. Docker health is `null`, not
Docker `healthy`; counts do not establish whole-database equality. The previous
`v1.6.497` rollback container is retained and stopped. Limited Receiver
role/API/header/message gates passed in scoped QA. Member retains privileged
reads; restricted/readonly typed reads retain safe configuration without URLs,
and GenericObject exact/list reads omit key/resourceData in both API versions.
No-access exact API requests return 403. Member Add is visible;
restricted/readonly Add is hidden, with Traditional Chinese direct-create
denial and no-access unavailable messages verified. Normal owner fixture
creation/deletion and cleanup were verified. Secret and other 498 resources,
all-resource, full-page and all-locale acceptance are not established.
Publication smoke and QA startup alone do not establish backend-write
authorization or company-site acceptance. Historical HOLDs remain
HOLD and the matrix remains INCOMPLETE. Preserve original volumes/settings for
rollback; rolling back to 497 restores the low-role capability exposure.
See [the release notes](docs/releases/server-1.6.498.md) for exact component pins.

The first 498 publisher run failed the fixed-available OpenSSL gate and remains
failed evidence. This release selects official Ubuntu `3.5.5-1ubuntu3.7` via
the signed HTTPS `20261002T000000Z` snapshot; security thresholds and the four
remaining unfixed CVEs / eight Medium package findings are retained.

Published Server `v1.6.497` packages officially published Web Console `1.6.164`.
It includes the shared state/date display-locale fixes
and Receiver validation-label fixes without changing API authorization, driver
actions, clone behavior, schemas or stored data. Engine `v0.183.328`, embedded
Cache `5.7.5`, base Server `v1.6.460`, Compose, AppArmor and nftables contracts
remain unchanged. The immutable image is
`ghcr.io/pasturestack/server:v1.6.497@sha256:1a1f05415e50d2ea337140d89063c6d7ae993140befa5aa79c5c83922990021d`,
from source `80d97523052aa86ec761ade8ec487c382a8d5e1d` and successful
[publication run `36836319609`](https://github.com/PastureStack/server/actions/runs/36836319609).
All 56 source gates, exact build/flatten, isolated first start/restart and 34 MFA
policy/API checks passed; public assets/image/SBOM readback matched. The final
one-layer merged-rootfs scan has 58 raw findings and 14 exact vendor-pending
package findings (eight Medium and six Low, six unique CVEs), with zero untracked,
Critical/High, fixed-available or secret findings. This is not a zero-CVE claim.
The recorded QA497 `8080` deployment ran `v1.6.497` / Web Console `1.6.164`;
first start/restart
returned `HTTP 200` / `pong` (10 and nine attempts), with zero runtime-contract
and tracked five-table DB-count differences. The original three named data
volumes, environment overrides, AppArmor and restart policy were preserved.
This is count preservation, not a whole-database row comparison; Docker health
is `null`, and no Docker `healthy` result is claimed. That deployment did not
establish packaged native Receiver browser acceptance. Publication smoke and
QA startup do not
establish full-language/layout, backend-write authorization or company-site
acceptance. Historical HOLDs remain HOLD and the matrix remains INCOMPLETE.
Preserve the nearest `v1.6.496` QA rollback with its original volumes/settings.
The `v1.6.495` image and backups remain retained; its obsolete stopped container
was removed.
See [the release notes](docs/releases/server-1.6.497.md).

Published Server `v1.6.496` pins Web Console `1.6.162`, Orchestration Engine
`v0.183.328` and the WAR's distributed-cache runtime `5.7.5`. Jackson
core/databind metadata is `2.22.3` / `3.2.3`; numeric Hazelcast cluster runtime
remains `5.7.3`. The Host Add Container entry follows the loaded exact-project
Container POST schema; the Secret desktop headings use existing translation
keys. Neither a schema GET nor a hidden UI entry establishes API write
authorization. Established schemas, stored-data formats and API permissions
are unchanged. The immutable image is
`ghcr.io/pasturestack/server:v1.6.496@sha256:6c85435b3de8771e5adff0b247274e0f1b9fe9d66c8b91e07d55a444e5589678`,
from source `d8e0e898b08aae45e040eb085936d11de14027fb` and successful
[publication run `36821096323`](https://github.com/PastureStack/server/actions/runs/36821096323).
Public assets/image readback, official candidate first start/restart and 34 MFA
policy/API checks passed. The one-layer merged-rootfs scan retains 58 raw
findings and 14 exact vendor-pending package findings (eight Medium and six
Low) after VEX, with zero untracked, Critical/High, fixed-available or secret
findings; it is not a zero-CVE claim. Isolated QA496 deployment passed first
start/restart `HTTP 200` / `pong` (10 attempts each), with zero runtime-contract
and tracked five-table DB-count differences; Docker health is `null`, not
`healthy`. Two zero-resource-write `1440 x 1000` desktop cases passed: readonly
Host Add Container absence/Edit unavailability and the member Secret table's
four Traditional Chinese headings. Host statistics remained connecting and
its right-side table was not fully reviewed; the Secret body was masked.
No full-layout, backend-write authorization or lifecycle acceptance is inferred.
Mobile and all-language acceptance remain pending.
Historical HOLDs and the first failed publication remain unchanged; the broader
resource/role matrix remains INCOMPLETE. No company-site deployment is claimed.
Retain `v1.6.495` with its original volumes/settings for rollback; see
[the release notes](docs/releases/server-1.6.496.md) for component source/hash
identities and the publication/QA boundary.

Published Server `v1.6.495` changes the Web Console Certificate editor and
installs Ubuntu's official `libdbi-perl` `1.647-1ubuntu0.26.04.3` security fix.
An existing matching certificate with a masked key and unchanged certificate
and chain may submit only name/description. New or replacement material keeps
full validation. No global write-only exemption, API permission change or
stored-data migration is introduced. The immutable image is
`ghcr.io/pasturestack/server:v1.6.495@sha256:ffd4d1c2a208b0bce3f9f961500ddebfdf7024bbddcf2d1e156cdbe76d30ba56`,
from signed source `512d4b2377e34ce04a33266af19b62ed45949eda` and successful
[publication run `36744673716`](https://github.com/PastureStack/server/actions/runs/36744673716).
It pins Web Console `1.6.161` and the unchanged Engine `v0.183.327`.
Independent assets/image readback and isolated first start/restart passed;
runtime settings and database-count baselines were preserved. The one-layer
runtime scan retains 52 raw findings and eight exact Medium vendor-pending
package findings after VEX, not a zero-CVE claim. Browser and broader
resource/role acceptance remain separate; see [the release notes](docs/releases/server-1.6.495.md).

Published Server `v1.6.494` pins Orchestration Engine `v0.183.327` and
Web Console `1.6.160`; both component releases are published and hash-verified.
The official image is
`ghcr.io/pasturestack/server:v1.6.494@sha256:9d1ddbe6f0c3fa11fefc141e14f419163c7bd14609163373d898ab0a857d790c`,
from source `c3b50ad6891ebbde4612e89dd5a1114bc731431c` and successful
[publication run `36704785404`](https://github.com/PastureStack/server/actions/runs/36704785404).
Its single-layer image and 22 checksummed assets were independently read back.
The security gate retains 52 raw findings and eight exact Medium
vendor-pending package findings after VEX, with zero untracked, Critical/High,
fixed-available or secret findings; it does not assert zero CVEs.
Isolated `8080` deployment start/restart passed with unchanged runtime and
database-count baselines. Certificate API/browser acceptance and the broader
resource/role matrix remain pending. Retain the immutable `v1.6.493` image and
original volumes/settings for rollback; that image retains the Certificate defects.

Certificate name-only and description-only
updates omit `cert` without replacing stored certificate or private-key data.
Explicit null `cert` values are rejected by the existing non-nullable API schema
with 422 / NotNullable; empty and malformed non-null values receive
422 / InvalidFormat. Create validation is unchanged. Certificate
DELETE and remove actions reject alternate and default references from
non-removed load balancer services in the certificate's account with the
existing 405 / InvalidAction response. The console explains only the known
certificate-in-use response in English, Traditional Chinese and Japanese;
public action names remain case-sensitive: undeclared `ReMoVe` receives
422 / InvalidAction during schema validation, not the reference guard's 405.
403 and 404 remain neutral, without service names or IDs. API shapes,
authorization, key masking, database formats and authentication/session
behavior are preserved. No database migration is required. All other packaging
coordinates and runtime security gates are retained from `v1.6.493`.

Preferred product-facing coordinates use `PastureStack/*`, `ghcr.io/pasturestack/*`, `PLATFORM_*`, and `PASTURESTACK_*`. Historical identifiers remain only where existing databases, agents, clients, templates, or upgrade tooling consume them. They must not be mechanically removed.

The catalog helper is packaged and installed as `catalog-service` and `catalog-service-sqlite`. The historical executable path remains only as a compatibility wrapper because the preserved service supervisor and persisted settings still invoke it. Release assets must use the PastureStack filename `catalog-service-<version>.tar.xz`; compatibility aliases must never leak back into the public asset name.

The authentication helper follows the same boundary: the GitHub Release asset and actual executable use `authentication-service`, while the preserved supervisor-facing executable name exists only as a compatibility wrapper.

PastureStack keeps the platform account as the authorization principal
and treats local credentials and external identities as explicit login links.
Provider changes therefore preserve the account identifier, direct project
memberships, and administrator role. OpenID Connect links use exact issuer and
subject values; username and email are never compatibility matching keys.
Explicit reassignment may copy direct memberships and administrator status,
but never copies passwords, API keys, sessions, MFA factors, recovery codes,
or audit history.

Machine management uses the neutral `machine-driver-bundle` asset, and vSphere operations use the neutral `vsphere-cli-bundle` asset. The externally defined executable names inside those archives are compatibility interfaces, not PastureStack branding. Artifact, license, and command-surface checks must pass before assembly; real provider and authenticated vSphere lifecycles still require isolated integration tests.

Server `v1.6.483` packages Web Console `1.6.149`. Secret Edit follows the
effective Secret schema: `name` and stored `value` remain immutable, while
only `description` is submitted on save, including an explicit empty string
when the user clears it. The Server API, authorization, Engine, and stored
resource formats are unchanged from `v1.6.482`. New Registry,
RegistryCredential, Certificate, and Secret action links are refreshed by ID
after creation; ambiguous RegistryCredential writes are not repeated.
Browser write acceptance remains an independent isolated `8080` check.

Secret payload operations use the neutral `secret-delivery-api` asset. The preserved engine still invokes the historical `secrets-api` executable and `/v1-secrets` routes, so Server supplies that filename only as an internal symlink while keeping the public artifact, primary executable, source repository, and license destination under the PastureStack name. Existing database key names and encrypted payload formats remain compatibility data and must survive upgrade and rollback testing.

The established `telemetry.opt`, `service.package.telemetry.url`, and `/v1-telemetry` identifiers remain internal compatibility data. Server installs `usage-telemetry-agent`, retains `/usr/bin/telemetry` only as an internal symlink, and packages the agent privacy notice beside its license and source record. A legacy target variable never enables publishing.

The `webhook.service.*`, `service.package.webhook.service.url`, `/v1-webhooks`, and four established driver identifiers also remain internal compatibility data. Server installs the neutral `webhook-automation-service` executable and retains `/usr/bin/webhook-service` only as an internal rollback link. The public asset and license destination use the neutral name, and the child process receives only the RSA public verification key.

The published `v1.6.482` release changes only Web Console packaging to
`1.6.147`. Service Edit sends just `name`, `description`, and `scale` instead
of the cloned launch configuration or upgrade strategy; the separate quick
scale action sends only `scale`. The Server API and stored-resource contracts
are unchanged. Its verified release identity is Server source
`3d909952d31e8577793acb7e402e10b883e1c8a6` and immutable image
`ghcr.io/pasturestack/server@sha256:e3ac65290f17981201a6cf2857e0f6def3eb79974746bc7110357fd87869a609`.
Isolated `8080` deployment and restart are healthy with Web Console `1.6.147`;
a bounded owner-browser run passed Service Edit Cancel, Save, and injected
`503` retry, plus Container and Service Remove Cancel/Confirm. The six-role
permission matrix remains a separate validation scope.

The published `v1.6.481` release consumes Orchestration Engine `v0.183.326`,
Web Console package `1.6.146`, Webhook Automation Service `v0.10.3`,
Authentication Service `v0.4.42`, API Explorer
`v1.1.18`, Compose Executor `v0.14.36`, Node Agent `v0.13.27`, Load Balancer Service `v0.9.27`, Catalog
Service `v0.20.11`, WebSocket Proxy `v0.23.14`, vSphere CLI Bundle `v0.55.2`, distributed cache runtime
`v5.7.4`, and Catalog Templates at commit
`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07` (Catalog Templates `v0.3.12`). A Catalog upgrade changes
`pinned_commit` first and leaves the last indexed `commit` untouched until
Catalog Service has rebuilt the template index; pre-advancing both values can
preserve a stale nonempty index. Operational container references must use
numeric semantic version tags. The verified release identity is signed Server
source `9c6914cda01a48dda4fb38f62d1a3f0c4db10be8` and immutable image
`ghcr.io/pasturestack/server@sha256:013eb045ed669344a67b8ac85d2ce56193abb74f34628281dec503dced8ab415`.
Web Console `1.6.146` localizes required-field and encrypted-key feedback;
the isolated `8080` browser and six-role write matrix remains pending. The
published `v1.6.480` identity and its pending Registry Add QA are retained in
its release notes. Web Console packaging must retain its
fingerprinted `/assets/ui*.js` entry, and API Explorer must retain
`/api-ui/ui.min.js` and `/api-ui/ui.min.css`.

The frozen `/v1` authorization snapshots expose `runtime`, `shmSize`, and
typed `deviceRequests` on both direct containers and service `launchConfig`
payloads, matching `/v2-beta`. Role-specific create and update permissions
remain authoritative; neither API version bypasses the shared service create
and upgrade validation or Docker conversion path.

OIDC configuration retains a strict source-versus-policy boundary. An already
enabled provider can change only its site access policy without repeating
discovery or local-recovery initialization. The same comparison is applied to
the platform-setting reload event emitted after the save, so the event cannot
reinitialize an unchanged live provider. Startup, a first enablement, provider
switch, or identity-source change still requires fresh local recovery.
Broadening access requires the existing one-use MFA confirmation bound to the
operator, `oidcAccessPolicyUpdate` purpose, and canonical request digest.
`unrestricted` is represented with an empty allowlist in both the API and
database. Its setting update carries an explicit `value: ""` field; generated
client omission rules cannot turn the clear into a no-op. Restricted
allowlists contain only deduplicated `oidc_user` and
`oidc_group` principals, while stable error codes preserve the client contract.
The same two identity types are present in the default external-identity list
and generated project-member schema. Engine `v0.183.310` makes schema creation
wait for completed configuration startup, loads the reviewed list from the
packaged runtime defaults, then merges base and configured
options in stable deduplicated order. Engine `v0.183.311` also unions the
reviewed OIDC types with an older database override and exposes the same types
from its frozen `/v1` schema, so an upgraded installation cannot reject a
valid OIDC project member merely because its persisted list predates OIDC.
Unknown types remain rejected, and the
configured-provider state is restored from persisted settings after restart.
For an external token exchange that Authentication Service has already
validated, Engine `v0.183.311` treats that successful exchange as the provider
boundary and validates every returned identity against the reviewed external
type allowlist. It does not re-read the asynchronously propagated provider
flag for those same identities. Unknown and missing types remain rejected;
generic identity and project-member operations still require current provider
state.
Engine `v0.183.312` validates Authentication Service identities before access
policy evaluation, account lookup, or persistent mutation. The Engine-owned
stable `rancher_id` added after account resolution is handled on a separate
internal path and is accepted only when it resolves to the account
authenticated by that token. A provider-supplied or mismatched platform
identity cannot select another account. This completes the boundary that
`v0.183.311` began without broadening the external or project-member type
contracts.
Engine `v0.183.313` preserves that boundary and makes fresh external-account
activation synchronous. The complete `account.create` lifecycle now reaches
`active` before the token path enters MFA, while MFA continues to reject every
non-active account. Existing accounts, identity validation, session ownership,
and access-policy behavior are unchanged.
Engine `v0.183.314` closes the remaining frozen-v1 schema boundary. When the
historical `/v1 projectMember.externalIdType` options are loaded, only that
field is enriched from the reviewed current core schema. Historical provider
values remain in stable order, `oidc_user` and `oidc_group` become available to
v1 environment and membership creation, and unrelated schemas or enum fields
are not widened. Runtime validation of unknown external identity types remains
fail-closed.
Engine `v0.183.315` restores identity ownership across repeated OIDC logins on
upgraded installations. Authentication credentials are persisted for the
explicitly verified user or administrator, and internal service accounts are
not accepted by login-identity lookup. A historical link owned by the built-in
`token` account is repaired only when the provider, external identity type,
external ID, derived link digest, and target account identity all match. Links
owned by another real account remain fail-closed and require the explicit
reassignment workflow.
Engine `v0.183.316` keeps the existing local administrator recovery path usable
when the external provider is configured with required site access. The
exception is limited to a server-encrypted local-auth payload whose stable
principal is revalidated as an active administrator while platform security
and local recovery are enabled. Ordinary OIDC sessions continue through the
unchanged user or group allow-list.
Engine `v0.183.317` makes shared-project provisioning explicit and
role-preserving. In the default `shared` mode, each successful login reconciles
the stable internal account identity into the single `adminProject` Default
environment only when no direct or group membership already exists. Existing
owner, member, restricted, readonly, and noaccess decisions are never replaced;
existing personal environments remain intact. The optional `personal` and
`none` modes preserve compatible deployments without changing authorization
semantics.
Engine `v0.183.318` resolves an existing external identity link before applying
restricted-site admission. Restricted mode can therefore honor that account's
existing project membership, including the shared Default membership, without
weakening required mode: required mode continues to admit only the configured
OIDC user or group allow-list (plus the separately guarded local recovery
administrator). Inactive or unresolved accounts still fail closed.
Engine `v0.183.319` makes shared-Default reconciliation atomic. It checks all
active direct, group, and stable-identity memberships and creates a baseline
member only while holding the same project lock used by administrator member
updates. Existing owner, member, restricted, readonly, and noaccess decisions
remain authoritative under concurrent login and policy changes.
Engine `v0.183.320` checks project-member collection requests against the
requested project before loading members. A token authorized for project A
cannot use that project's `X-API-Project-Id` header to list project B's members
through `?projectId=B` on either `/v1/projectMembers` or
`/v2-beta/projectMembers`; unauthorized and malformed project IDs return 404.
Authorized collections and direct member-ID access retain their established
project checks.
Engine `v0.183.321` excludes inactive or removed project-member rows from
direct ID reads, matching active membership collections. Active direct reads
still require the caller to have access to the row's project, and an ID from
another project remains unavailable. This applies equally to `/v1` and
`/v2-beta`; a removed row is not exposed merely because its database ID still
exists.
Web Console `1.6.132` uses the effective per-project schema for workload create
and upgrade controls as well as direct routes. A missing POST or PUT method
therefore cannot be bypassed by typing the route, and a project switch forces
capability re-evaluation. Account administration reads exact per-account
`authIdentityLink` records for local and OpenID Connect identity display.
The environment editor separately follows project `update`, project
`setmembers`, and network `update` action links; a direct `?editing=true` URL
does not grant a missing action. These UI guards supplement, and do not replace,
server-side token and project authorization.
The environment editor's network-policy lookup also supplies its project ID
in `X-Api-Project-Id`; an unscoped read of a project-only network is not
treated as evidence that the selected project has no network policy.
The environment detail page offers an Edit entry for network-only capability
after its network model loads, without inferring permissions from a role name.
Direct `/env/:project_id` navigation and refresh select that permitted project
from the router's public RouteInfo before the tab or user Default fallback.
Missing, inactive, and inaccessible IDs retain the existing authorized
fallback; valid URL environments are not replaced by a saved preference.
Each readable account still receives an exact `authIdentityLink` lookup. HTTP
404 for an inactive historical account is isolated to that row and uses the
embedded identity fallback; 401, 403, 5xx, transport, and unexpected failures
continue to reject the route.
Environment view and edit use the project `projectMembers` link, so member
reads follow the same project authorization boundary. A 403 or 404 during the
project or member load is shown as a localized access or not-found message.
Server failures during environment load show a localized retry message instead
of the raw response.
Save failures identify whether the project, members, or network policy failed;
the form warns that an earlier save step may already have completed. Identity
search distinguishes a zero-result lookup from 401, 403, and server failure.
An authenticated account with no active environment is a valid empty state.
The console clears stale project scope, skips project-scoped collections until
an authorized environment exists, and does not loop on an obsolete direct
URL. Account names prefer authoritative identity links in the order name,
login, then external ID; a missing link falls back to the embedded identity.
Descriptions remain account data, and display-only identity links are never
serialized in an account update.
Web Console `1.6.133` applies the active project's effective host POST schema
to host creation and cloning. A direct Add Host URL without that permission
shows a 403 before registration data loads; responses from an earlier project
selection cannot restore stale permissions. Project details wait for the
selected project before reading its network and policy. Host access errors use
localized text across all 13 console locales and remain readable in narrow
and right-to-left layouts. This release changes no backend API or
authentication contract.
Web Console `1.6.135` requests the full active environment collection for a
site administrator's switcher, including environments where that account is
not a direct member. Other signed-in users still request their authorized
collection; the Server remains the authority for `all=true` and direct IDs.
The affected switcher labels use reviewed French and Russian translations.
Web Console `1.6.136` bounds the environment-switcher menu in left-to-right
and right-to-left views and corrects the Persian `/fail` page direction. It
revalidates a stored environment selection with a fresh direct GET. A 403 or
404 falls back to an available environment; 401 and 5xx errors remain visible
to the caller. Environment management consumes a fresh collection, so stale
cached records cannot keep a revoked environment in the list. This refresh
preserves the active environment and its loaded schema on return navigation;
a permitted direct URL still works when its environment is absent from the
collection. An already open view can retain its former selection until
reinitialization or an explicit switch; Server authorization still checks
membership on each request.
Web Console `1.6.137` lets empty pod-list messages wrap within narrow
viewports, including the Russian no-hosts message that overflowed by 6 pixels
at 320 pixels. Pod-column layout, translations, host API, and authorization
behavior are unchanged.
Web Console `1.6.138` waits for each confirmed deletion, prevents duplicate
submits, and keeps failed items available for retry. Authenticated routes wait
for language initialization; denied and missing resource pages translate in
the active locale without changing API authorization.
Webhook Automation Service `v0.10.2` requires the trusted project header to
match a receiver management request and confines receiver lookup, deletion,
name checks, and key or signed-JWT execution to `webhookReceiver` objects.
The internal `/usr/bin/webhook-service` compatibility link is preserved.
Web Console `1.6.139` reads project schema methods before showing Container,
project API-key, or Receiver Hook write controls. Its Container edit modal waits
for primary, port, and link saves; a failed port or link update restores that
field and leaves the modal open, while successful peer updates are not retried.
These separate API writes are not atomic. Webhook Automation Service `v0.10.3`
returns role-specific Receiver schema methods for both schema endpoints and
marks those responses private and non-cacheable; stored receivers and existing
routes are unchanged.
Orchestration Engine `v0.183.325` exposes `projectTemplate.isPublic` read-only
in its core schema, but its frozen `/v1` non-admin user schema omits the field.
It omits remove actions for public or non-owned templates and keeps direct
non-admin mutations owner-scoped. Web Console `1.6.140` shows
ProjectTemplate edit/remove only for administrators or an exact, non-empty
template owner account ID match; direct edit routes check ownership again.
Its sortable-table controls reflow at narrow widths, and closing an API-key
modal before delayed focus runs no longer targets a destroyed input. Role
labels alone do not establish Container write capabilities: use each account's
effective project schema methods when validating the controls and API writes.
Orchestration Engine `v0.183.325` packages FreeMarker `2.3.35` exactly once.
Server `v1.6.475` retains the signed Ubuntu 26.04 curl security revision
`8.18.0-1ubuntu2.7` without replacing the preserved runtime base.
Orchestration Engine `v0.183.326` restores the read-only `projectTemplate.isPublic`
field in the frozen `/v1` non-admin user schema, matching `/v2-beta`; the
administrator's create/update schema and stored data are unchanged.
Web Console `1.6.141` gives the same localized denial on ProjectTemplate
direct-edit routes for 403, 404, and owner mismatch while retaining 401
session recovery. Failed API-key saves display the existing API error inside
the modal without rendering key values.
Web Console `1.6.142` keeps server-issued Receiver URLs and lifecycle state
out of cloned create requests, clears inherited catalog identity on new
private ProjectTemplates, and reports inaccessible direct environment routes
without revealing whether an ID exists. Container table actions remain within
their visible scroll host while data columns keep their own width in LTR,
RTL, narrow panels, and desktop-to-mobile resize transitions.
Web Console `1.6.143` constructs a new private ProjectTemplate from editable
fields and deep-copies its initial stacks. The create request omits Default's
server-owned creation time, lifecycle state, ID, UUID, and catalog identity.
Shared new-resource clones for Host, Service, Container, and VM likewise omit
server-owned identity and lifecycle fields; edit and upgrade copies retain
their existing behavior. Receiver clones omit inactive driver configurations,
and unsupported drivers cannot submit the create form.
Web Console `1.6.144` introduced create-capability checks for Secret,
Certificate, and Registry Add controls and direct Add routes; Registry creation
requires both registry and registryCredential POST. Follow-up isolated QA found
that Registry Add was falsely denied for superadministrator, owner, member,
and restricted roles when schema IDs had different casing, despite both POST
capabilities. Readonly and no-access roles passed their denial checks; Secret
and Certificate checks passed in English and Traditional Chinese. The false
denial caused no resource writes. Web Console `1.6.145` resolves create
capabilities across the mixed-case schema IDs. Denied direct routes retain
localized 403 feedback, and Secret Edit follows its update action link. These
are browser controls and feedback, not changes to Server authorization or API
contracts.
Legacy provider settings are imported only while the encrypted `auth.config`
object does not exist. After that one-time migration boundary, the common
access-mode and allowlist settings are authoritative; service and Server
container restarts cannot replay absent legacy OIDC keys over a saved
restricted or unrestricted policy.
The `/v1-auth` proxy preserves the caller's PastureStack authorization for an
exact `POST /v1-auth/config`, so the actor-bound policy confirmation reaches
the Authentication Service. Provider-backed reads continue to receive the
external identity-provider token; unrelated proxy routes are unchanged.
New browser tokens keep the create-only `clientSessionId` field through the
dynamic authorization overlay and the frozen `base`, `superadmin`, and `token`
v1 schemas. Explicit logout normalizes a cookie's bare key and a
standard `Authorization: Bearer` value to the same database key; mismatched
generations and unsupported authorization schemes cannot revoke the token.
Cookie and session-generation reads, login commit, and explicit logout share
one origin-level mutex. A tab captures its generation when starting requests,
timers, and subscriptions; stale passive failures stop their own work and
adopt the newer committed session without clearing shared state. Storage and
sanitized BroadcastChannel events carry no token material and converge through
one serialized reconciliation path. An explicit logout is the only browser
path allowed to revoke the bound token.
The current-token collection is authenticated only when its first entry has a
non-empty `accountId`, `user`, or `userIdentity`; an HTTP 200 provider
login-options object with no identity is an unauthenticated response. The
console normalizes it to its local 401 contract, clears only an unchanged
Cookie and generation under the authentication mutex, and routes to login
without a passive DELETE or reload loop.
Promise/callback interoperability uses one RSVP-based adapter for
`PromiseToCb`, authenticated-route lookup, and settings loading. Task factories
start in a deferred RSVP turn, so synchronous throws, thenables, plain values,
and Promises share one settlement contract; callback exceptions cannot enter a
second error callback. The 27 `NewOrEdit` consumers share one awaitable,
owner-bound save lifecycle covering validation, persistence, success hooks,
error hooks, completion callbacks, and cleanup. A pre-existing `saving=true`
lock is never claimed or cleared by a duplicate submission. Environment member
loading uses the supported `followLink('projectMembers')` store boundary.

External-service `healthState` remains writable API data, including `null`.
Load-balancer editing persists the chosen target through
`PortRule.serviceId`; this changes no load-balancer runtime or API shape.

Deployments that terminate TLS before the Server container may set
`PROXY_PLATFORM_PUBLIC_ORIGIN` to one exact public HTTP(S) origin. The proxy
uses that origin only for requests whose Host matches the configured authority;
unrelated hosts retain transport-derived forwarding values. Credentials,
paths, queries, and fragments are rejected. Platform API responses are always
rewritten to `Cache-Control: private, no-store`, while static assets preserve
their existing cache policy.

Native MariaDB validation must override both `CATTLE_DB_CATTLE_MYSQL_URL` and `CATTLE_DB_LIQUIBASE_MYSQL_URL`; the application and migration pools are configured independently. The default compatibility path intentionally uses a MySQL JDBC scheme with the MariaDB driver compatibility options.

The embedded database explicitly sets `innodb_snapshot_isolation=OFF`. MariaDB
11.8 enables snapshot isolation by default, but the preserved control-platform
transaction layer predates that behavior and already performs its own
optimistic locking and retries. Leaving the new database default enabled can
surface error 1020 during concurrent system-stack creation. External MariaDB
deployments must apply the same compatibility setting before the Server starts.

Image defaults do not override rows already persisted in the `setting` and
`catalog` tables. Existing installations must audit and migrate the narrow
distribution-coordinate allowlist with
`scripts/migrate-approved-runtime-coordinates.sh` against an isolated restore
before cutover. The tool preserves compatibility setting names, creates an
exact rollback bundle, and changes only approved GitHub, GHCR, CLI, Agent,
load-balancer, and Catalog coordinates.

Before a future release, validate fresh install, preserved-database upgrade,
both database modes, web console and API, CLI, node registration,
authentication, subscriptions, catalog, networking, storage, backup/restore,
rollback, artifact hashes, and non-root execution in isolated VMs.
