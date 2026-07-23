# PastureStack Server

Server assembles the compatible control-platform runtime, orchestration engine, web console, node agent, authentication, proxy, catalog, and database components into a deployable source package.

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.

**Upstream:** [`rancher/rancher`](https://github.com/rancher/rancher). This GitHub fork preserves upstream history, authorship, dates, tags, licenses, and copyright notices. PastureStack maintenance is consolidated into one commit after the preserved upstream boundary.

## Project status

This is a compatibility-focused modernization project. Existing Ubuntu 26.04, Java 25, MariaDB, modern Docker, non-root runtime, artifact-integrity, authentication, WebSocket, backup/restore, and test work is retained. Passing the documented compatibility gates does not by itself make a deployment production-ready.

The embedded MariaDB configuration keeps the established transaction behavior
by disabling MariaDB 11.8 snapshot isolation. This avoids error 1020 during
concurrent system-stack creation while retaining the control platform's own
optimistic locking and retry logic. External MariaDB deployments must use the
same compatibility setting.

## GitHub distribution model

PastureStack is designed not to require operators to host a separate download site, container registry, or catalog server. Reviewed container images are published through the public GitHub Container Registry and consumed by digest. Versioned binary and web assets are published as flat attachments to the matching `PastureStack/server` GitHub Release. Catalog templates are read directly from the public [`PastureStack/catalog-templates`](https://github.com/PastureStack/catalog-templates) Git repository and must be verified against a full pinned commit SHA.

Catalog stack definitions, their documentation, and referenced public images must remain usable directly from GitHub and GHCR. Catalog entries pin images by digest and may not require an operator-maintained HTTP mirror, GitHub Pages site, catalog service, or private registry. GitHub Release assets are reserved for immutable Runtime payloads; the catalog itself remains a commit-pinned Git source so stack discovery and version history stay auditable.

Version coordinates are available only when the matching GitHub Release and public GHCR package both exist. Each release is held until its assets, checksums, SBOM, license records, anonymous downloads, and isolated-VM gates pass.

## Quick start

The versioned image is public and does not require a registry login:

```sh
docker run -d --name pasturestack-server --restart unless-stopped -p 8080:8080 ghcr.io/pasturestack/server:v1.6.273
```

Use the immutable image digest recorded in the matching GitHub Release when pinning a production-like deployment. Persistent database and platform state use the image-declared Docker volumes; manage or bind those volumes explicitly before relying on the container for durable workloads.

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

The vSphere command-line dependency is supplied by the independently maintained `PastureStack/vsphere-cli-bundle` artifact. The recipe builds `govc` from the exact Apache-2.0 upstream commit with Go 1.26.5, verifies the injected version metadata, and carries complete source and license records. Offline command checks do not prove authenticated vSphere inventory, clone, power, delete, upgrade, rollback, or failure recovery; those remain isolated-VM release gates.

Secret encryption and rewrap operations are supplied by the `PastureStack/secret-delivery-api` GitHub fork. The artifact preserves the official `v0.2.2` history, carries complete Apache-2.0 and third-party license text, rejects malformed keys and path-like key names, and passes a loopback local-key API smoke test. Server installs the neutral executable and exposes the historical `secrets-api` filename only as an internal compatibility symlink; database key continuity, restart persistence, backup restore, and Vault integration remain isolated-VM release gates.

Optional aggregate usage reporting is supplied by the true fork `PastureStack/usage-telemetry-agent`. The standard-library-only artifact carries its Apache-2.0, source, third-party, and privacy records; Server verifies both archive and executable digests, installs the neutral executable, and retains `telemetry` only as an internal launcher symlink. Publishing is disabled without a new explicit HTTPS target and never inherits the retired destination.

Webhook-driven service scaling, host scaling, service upgrades, and controlled forwarding are supplied by the true fork `PastureStack/webhook-automation-service`. Server verifies the deterministic archive and static executable digests, installs the neutral executable, moves its license and source records into the PastureStack license tree, and retains the historical filename only as an internal compatibility link. The launcher no longer exposes the control-plane private key to this child process.

Metrics mapping uses the unchanged official Prometheus Graphite Exporter `v0.2.0` Linux AMD64 release asset. Server pins the archive, executable, source commit, license, and notice digests; installs the executable from the official archive layout; and retains its Apache-2.0 license and notice under `/usr/share/licenses/graphite-exporter`. PastureStack does not claim authorship of this external component.

Process supervision uses the unchanged official s6-overlay `v1.19.1.1` AMD64 release asset. The build pins its archive digest and source commit, validates the required init and supervision entries, and carries the upstream ISC license in the Runtime license bundle. The public filename adds only a version suffix; the archive bytes remain identical to the upstream GitHub Release asset.

Binary-only compatibility archives are accompanied by the deterministic `pasturestack-runtime-licenses-1.6.273.tar.xz` release asset. It maps every flat Runtime asset to an exact public source commit, preserves tracked license, notice, patent, privacy, and origin files, includes legal files already embedded in archives, and carries its own internal checksum list. The Server image verifies and installs this bundle under `/usr/share/licenses/pasturestack-runtime`.

CI/CD remains disabled. Release and package publication are manual, gated operations, and publication is not a production-readiness claim.

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
