# PastureStack Server v1.6.305

This release promotes an evidence-backed Docker host support policy without
changing the established host API or persisted data model.

## Runtime change

- Base image: `ghcr.io/pasturestack/server:v1.6.304`
- Runtime image: `ghcr.io/pasturestack/server:v1.6.305`
- Newest supported Docker Engine: `29.6.2`
- Exact modern supported releases: `24.0.9`, `29.4.1`, and `29.6.2`
- Docker 25 through 28 and unlisted Docker 29 patch releases are not claimed as
  supported.
- The support policy is applied as a deterministic configuration-only backport
  to the existing orchestration-engine application configuration archive. Java
  classes, API schemas, database identifiers, Web Console `.16`, Catalog
  coordinates, and external data volumes are unchanged.

## Host matrix

The two-host matrix covered:

- Ubuntu 24.04.4, Docker `29.6.2`, cgroup v2, and the maintained node agent;
- Ubuntu 22.04.5, Docker `24.0.9`, cgroup v1, and the legacy-compatible agent;
- the same Ubuntu 24.04.4 host before upgrade on Docker `29.4.1`;
- registration and reconnect;
- API and WebSocket proxy paths;
- logs, exec, console, and statistics;
- managed image pull and container create, start, restart, and delete;
- metadata and all deployed system services;
- bidirectional encrypted overlay traffic;
- Server restart recovery;
- Docker package upgrade and rollback preparation;
- zero disposable workload residue after the matrix.

## Supply-chain validation

- Docker's official `29.6.2` static Linux archive was independently downloaded
  and verified as SHA-256
  `d6204aea92238e2453d5445c885b9d2e5eb8f82915568ec50edf9dbe12a3ac74`.
- Server development, node-agent base, and source-build fallback downloads all
  use Docker `29.6.2`; every file-backed download is checksum-verified.
- All 45 Server source gates pass.
- The focused Server image is reproducible from the public source commit and
  semantic base tag.
- Fresh startup, authenticated-root behavior, restart recovery, settings
  exposure, Web Console preservation, and Catalog preservation pass.
- Trivy `0.72.0` reports zero actionable High or Critical vulnerabilities and
  zero detected secrets.
- The operational image coordinate remains a semantic version tag. Image
  digests are release-verification evidence only and are not inserted into
  Catalog, API, Web Console, or other user-facing runtime fields.

## Compatibility boundary

This release does not claim blanket Docker 24 or Docker 29 compatibility.
Support applies only to the exact versions and host configurations documented in
[`docs/hosts/README.md`](../hosts/README.md). Windows hosts, Docker 25 through
28, and unlisted operating-system or storage-driver combinations still require
their own matrix.

PastureStack is an independent community effort to preserve, audit, and
modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by
Rancher Labs or SUSE.
