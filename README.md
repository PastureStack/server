# PastureStack Server

Server assembles the compatible control-platform runtime, orchestration engine, web console, node agent, authentication, proxy, catalog, and database components into a deployable source package.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.

**Upstream:** [`rancher/rancher`](https://github.com/rancher/rancher). This GitHub fork preserves upstream history, authorship, dates, tags, licenses, and copyright notices. PastureStack maintenance is consolidated into one commit after the preserved upstream boundary.

## Project status

This is a compatibility-focused modernization project. Existing Ubuntu 26.04,
Java 25, MariaDB, modern Docker, non-root runtime, artifact-integrity,
authentication, WebSocket, backup/restore, and test work is retained. Server
`v1.6.389` combines Orchestration Engine `0.183.288`, Node Agent `0.13.22`,
Authentication Service `0.4.36`, and the reviewed Ember 7.2 Web Console
`1.6.92`.

Docker Engine `29.4.1` through `29.7.2` is represented as one bounded SemVer
compatibility interval rather than a list of isolated patch releases. Hosts on
an in-range version such as `29.6.2` are therefore reported as supported.

The current image retains the embedded API Explorer's reviewed UI maintenance,
replacing the retired Bootstrap 3.4.1 stylesheet and Glyphicons with API Explorer `1.1.18`,
Bootstrap `5.3.8` CSS, and Bootstrap Icons `1.13.1`. Bootstrap JavaScript
remains excluded; modal and dropdown behavior stays in the reviewed
first-party compatibility layer.

The same release replaces every vulnerable Go 1.26.5 executable found by the
finished-image scan with a Go 1.27.0 build: Authentication Service `0.4.36`,
Catalog Service `0.20.11`, Compose Executor `0.14.34`, Host Provisioner
`0.39.6`, Secret Delivery API `0.3.1`, Usage Telemetry Agent `0.4.1`, Webhook
Automation Service `0.10.1`, WebSocket Proxy `0.23.13`, vSphere CLI Bundle
`0.55.1-pasturestack.2`, and the in-tree Console Broker. Image assembly also
installs the current Ubuntu 26.04 package updates before the final scan. It
also removes the setuid bit from the container's mount helpers and disables
SSH X11 forwarding and GSSAPI authentication; root-only mount operations and
ordinary key-based SSH remain available.

The `v1.6.358` control-plane security update restricts serialized schema
loading to an explicit class allowlist with bounded object graphs and prevents
console-session targets from carrying attacker-controlled URL authority data.

Authoritative host-port and volume preflight protects create and upgrade
operations without weakening project ownership checks. Managed-network checks
cover every eligible host in the environment, while bridge and host-network
checks remain scoped to the selected host. Stopped owners produce an explicit
warning and unknown live-inspection state is never reported as safe. The
runtime registers the complete volume-preflight schema set and rejects an
image that cannot resolve the live action schemas.

The Web Console keeps storage pagination, selected-volume removal, direct host
container routes, relationship refresh, natural sorting, column selection,
search, and live statistics synchronized. It also retains readable WCAG AA
Catalog documentation, reactive Catalog upgrade versions, localized
questions, writable OpenID Connect configuration, broker-aware terminal
recovery, single-owner project WebSocket reconnect, API Explorer `1.1.18`,
administrator-controlled MFA, and all 13 reviewed production locales. SMTP is
configured once per installation; individual accounts store only their own
verified recovery address. Passing compatibility gates does not by itself make
a deployment production-ready.

The embedded MariaDB configuration keeps the established transaction behavior
by disabling MariaDB 11.8 snapshot isolation. This avoids error 1020 during
concurrent system-stack creation while retaining the control platform's own
optimistic locking and retry logic. External MariaDB deployments must use the
same compatibility setting.

## GitHub distribution model

PastureStack is designed not to require operators to host a separate download site, container registry, or catalog server. Reviewed container images are published through the public GitHub Container Registry and operational references use semantic version tags. Digests remain release-verification evidence and are never written into Catalog, Compose, API, or web-console image fields. Versioned binary and web assets are published as flat attachments to the matching `PastureStack/server` GitHub Release. Catalog templates are read directly from the public [`PastureStack/catalog-templates`](https://github.com/PastureStack/catalog-templates) Git repository and must be verified against a full pinned commit SHA.

Catalog stack definitions, their documentation, and referenced public images must remain usable directly from GitHub and GHCR. Catalog entries pin images by semantic version tag and may not require an operator-maintained HTTP mirror, GitHub Pages site, catalog service, or private registry. GitHub Release assets are reserved for immutable Runtime payloads; the catalog itself remains a commit-pinned Git source so stack discovery and version history stay auditable.

Version coordinates are available only when the matching GitHub Release and public GHCR package both exist. Each release is held until its assets, checksums, SBOM, license records, anonymous downloads, and isolated-VM gates pass.

Server `v1.6.389` registers the complete live volume-preflight schema model and preserves the project-scoped authorization required by driver-aware volume configuration, accessible
path completion, and an authoritative `volumepreflight` check. The server
validates container and service create or upgrade requests again at save time,
including storage-driver state, host coverage, existing volume ownership, and
the `pasturestack-nfs` environment-wide `multiHostRW` contract. The Web Console
keeps at most eight naturally sorted path suggestions and combines port and
volume checks with deterministic status precedence.

The Web Console formats schema-validation field names without legacy String
prototype extensions, so a missing localized field label cannot leave a
container or service form stuck in the saving state.

Web Console `1.6.92` preserves the Server `v1.6.358` authenticated visual and
layout contract through a provenance-bound presentation layer while retaining
Ember 7.2, the Bootstrap 5.3.8 JavaScript runtime, current security fixes, MFA,
and adds permission-scoped incident filters and XLSX, CSV, and JSON export to
the audit-log builder without changing result data or column order. Its time-range editor
uses separate hour, minute, and AM/PM columns with smooth deceleration and exact
value snapping; the earlier whole-range 15-minute animation is removed.
The Host details view keeps its CPU, memory, network, and storage chart series
and colors stable between initial rendering and live updates. Dense area charts
do not create per-sample point nodes, Billboard-specific styles apply to both
initial and updated SVG content, and CPU and memory axes start from the Host's
actual capacity. The audit-log filter completes reliably when clearing or reapplying an
unchanged query, and clearing restores the same visible bounded 24-hour range
that is sent to the API. The result table's final authentication/IP heading
keeps its longer-locale wrapping protection while receiving a wider default
column; the identity column uses a compact default so the rightmost heading is
not forced to wrap in shorter locales. Result rows, column order, and other
page regions are unchanged.
The Service log page adds service-scoped time, severity, named-container,
event-scope, event-type, and description filters without changing its existing
table. Container restarts now emit an explicit `service.instance.restart`
record linked to the owning service, while the administrator audit log retains
the corresponding API action record.
The complete filter interface is translated in all 13 selectable locales;
non-English locales no longer inherit the English filter-builder copy.
The audit date calendar is rendered by the application, so month names,
weekdays, date formatting, and week starts follow the selected application
locale instead of the browser UI language. The footer language menu opens
upward, stays aligned to its trigger, and remains inside the viewport.
Server `v1.6.358` is used only as visual
authority; no application code, dependency, security fix, or feature is rolled
back. The current console also retains the classic locale observer contract
required by Ember Intl 9, so the login language selector and audit-log route
initialize reliably before and after locale bootstrap. It retains the global dropdown
destination, so environment and user selectors render their actual options,
keeps inactive full-screen overlays from intercepting controls, and prevents
the legacy positioning shim from throwing on Bootstrap 5 events.
The login card now keeps the language selector visually integrated, centers a
full-width submit button, and provides an accessible show/hide password control
without changing authenticated tables or application pages.
It also preserves each selected text operator in the query-backed audit filter
state. It retains the audit-log filter builder, existing audit table, Bootstrap runtime
boundary, and deterministic loading-overlay lifecycle and
distinct rectangular PastureStack stack-panel loading state. Only the newest
route transition may change its state; successful, rejected, aborted, and overlapping transitions
release it safely, with a 30-second watchdog as a final recovery path. The
retired grass, celestial-body, and orbit scene is rejected by the packaged
image gate. Reduced-motion mode retains a low-displacement layer pulse and
progress-colour cycle instead of leaving the overlay visually frozen.
The release also patches the transitive build dependency `nanoid` to `3.3.17`,
pins Node.js `24.20.0` and npm `12.0.2`, and fails closed when the current
npm advisory service reports a Critical or High finding.

Authentication Service `0.4.36` is installed from its checksum-verified public
release without replacing the established launch wrapper. The packaged image
requires the reviewed archive digest, extracted-binary digest, exact source
commit, static binary, and exact version output before publication.

The embedded Catalog snapshot is pinned to commit
`bc446236c16f1170eb9130b4901af3d57dd82db4`. It retains prior immutable
template revisions and adds Resource Scheduler `v0.8.16` as a new revision,
using only the public semantic-version GHCR coordinate.

The Create button remains disabled during an ordinary live volume check. If a
same-tick recheck races with a click, it no longer becomes a stale client-side
error; the create or upgrade request proceeds to the authoritative server-side
volume and storage-driver validation.

## Quick start

The versioned image is public and does not require a registry login:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 ghcr.io/pasturestack/server:v1.6.389
```

Keep operational image references in semantic `vMAJOR.MINOR.PATCH` form. The matching GitHub Release records the resolved digest for verification without exposing digest-qualified strings to the platform UI. Persistent database and platform state use the image-declared Docker volumes; manage or bind those volumes explicitly before relying on the container for durable workloads.

Existing databases can retain old image, download, and Catalog coordinates even
when the new image contains correct defaults. Audit and migrate only the
reviewed allowlist with
[`scripts/migrate-approved-runtime-coordinates.sh`](scripts/migrate-approved-runtime-coordinates.sh)
after first restoring the latest database into an isolated environment. The
default action is read-only; apply and rollback require `--yes` and use a
checksum-protected rollback bundle. See the
[upgrade and persisted-coordinate migration guide](docs/upgrades/README.md).

The versioned Windows node-agent ZIP is an artifact candidate only. Windows host support remains unavailable until its replacement bootstrap runtime and privileged Windows VM validation have passed; artifact validation alone must not be represented as working Windows host support.

The machine-management dependency is supplied by the independently maintained `PastureStack/machine-driver-bundle` artifact. Its two licensed upstream executables, full license texts, source coordinates, deterministic archive, and provider-plugin handshake are verified before assembly. Real provider provisioning, deletion, upgrade, and rollback remain release gates.

The vSphere command-line dependency is supplied by the independently maintained `PastureStack/vsphere-cli-bundle` artifact. The current recipe builds `govc` `0.55.1-pasturestack.2` from the exact Apache-2.0 upstream commit with Go 1.27.0 and `golang.org/x/text` 0.39.0, verifies the injected version metadata, and carries complete source and license records. Offline command checks do not prove authenticated vSphere inventory, clone, power, delete, upgrade, rollback, or failure recovery; those remain isolated-VM release gates.

Secret encryption and rewrap operations are supplied by the `PastureStack/secret-delivery-api` GitHub fork. Release `v0.3.1` preserves the official `v0.2.2` history, carries complete Apache-2.0 and third-party license text, rejects malformed keys and path-like key names, and passes a loopback local-key API smoke test. Server installs the neutral executable and exposes the historical `secrets-api` filename only as an internal compatibility symlink; database key continuity, restart persistence, backup restore, and Vault integration remain isolated-VM release gates.

Optional aggregate usage reporting is supplied by the true fork `PastureStack/usage-telemetry-agent`. The Go 1.27.0 `v0.4.1` artifact carries its Apache-2.0, source, third-party, and privacy records; Server verifies both archive and executable digests, installs the neutral executable, and retains `telemetry` only as an internal launcher symlink. Publishing is disabled without a new explicit HTTPS target and never inherits the retired destination.

Webhook-driven service scaling, host scaling, service upgrades, and controlled forwarding are supplied by the true fork `PastureStack/webhook-automation-service`. Server installs the Go 1.27.0 `v0.10.1` artifact, verifies the deterministic archive and static executable digests, moves its license and source records into the PastureStack license tree, and retains the historical filename only as an internal compatibility link. The launcher no longer exposes the control-plane private key to this child process.

Metrics mapping uses the unchanged official Prometheus Graphite Exporter `v0.2.0` Linux AMD64 release asset. Server pins the archive, executable, source commit, license, and notice digests; installs the executable from the official archive layout; and retains its Apache-2.0 license and notice under `/usr/share/licenses/graphite-exporter`. PastureStack does not claim authorship of this external component.

Process supervision uses the unchanged official s6-overlay `v1.19.1.1` AMD64 release asset. The build pins its archive digest and source commit, validates the required init and supervision entries, and carries the upstream ISC license in the Runtime license bundle. The public filename adds only a version suffix; the archive bytes remain identical to the upstream GitHub Release asset.

Binary-only compatibility archives are accompanied by the deterministic `pasturestack-runtime-licenses-1.6.278.tar.xz` release asset. It maps every flat Runtime asset to an exact public source commit, preserves tracked license, notice, patent, privacy, and origin files, includes legal files already embedded in archives, and carries its own internal checksum list. The Server image verifies and installs this bundle under `/usr/share/licenses/pasturestack-runtime`.

Automatic CI/CD triggers remain disabled. Release preparation and publication use manually dispatched, gated GitHub workflows so public runners carry the build load without running on every push. Publication is not a production-readiness claim.

## Build and validation

The repository is a packaging layer. Build inputs must be pinned to reviewed source commits and verified artifacts. Run source and shell checks locally before any container build:

```sh
bash scripts/test
bash scripts/check-server-source-gates.sh
```

Full startup, database migration, node registration, web console, backup/restore, upgrade, and rollback checks require isolated VMs. See [COMPATIBILITY.md](COMPATIBILITY.md), [SECURITY.md](SECURITY.md), and [ORIGIN.md](ORIGIN.md).

## Language support

The assembled web console provides English, German, Persian, Filipino, French,
Hungarian, Japanese, Korean, Brazilian Portuguese, Russian, Ukrainian,
Simplified Chinese, and Traditional Chinese for Taiwan. The console owns its
complete message contract, regional date formatting, and right-to-left layout.

New server bootstrap messages use `PASTURESTACK_LOCALE=en-US` or `zh-TW`;
protocol fields, persisted identifiers, and third-party output are not
translated.

## License and attribution

The inherited project remains licensed under [Apache License 2.0](LICENSE), with additional attribution in [COPYRIGHT_DETAILS.md](COPYRIGHT_DETAILS.md). Bundled components retain their own licenses and notices. PastureStack contributors claim authorship only for their own changes.
