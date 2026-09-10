# PastureStack Server v1.6.413

> **Superseded by `v1.6.414` for the service resource form.** Runtime and
> database behavior remain valid, but Web Console `1.6.104` prevents the init
> checkbox from overlapping the process-limit field and adds complete create
> and upgrade payload regression coverage.

This release completes the Docker Compose performance-setting support started
in `v1.6.412` and supersedes that image for deployments using
`PASTURESTACK_MARIADB_*` variables.

## Operator-visible result

- Java heap, pre-touch, bounded GC and safepoint logs, and embedded MariaDB
  performance settings remain independently configurable through the typed
  environment variables documented in the
  [performance settings guide](../performance/README.md).
- Embedded MariaDB startup now declares its internal database context while it
  renders the generated configuration. Its own `localhost` connection is no
  longer misclassified as an operator-configured external database.
- External-DB mode still rejects every `PASTURESTACK_MARIADB_*` variable;
  external database tuning belongs on that separate database service.
- Omitting all new variables continues to preserve the established Server
  defaults. Invalid sizes, conflicting options, impossible relationships, and
  free-form JVM fragments still fail before application startup.

## Root cause and regression coverage

`v1.6.412` correctly rejected embedded-MariaDB settings when an external
database host was supplied. During embedded startup, however, the legacy
launcher subsequently assigned `CATTLE_DB_CATTLE_MYSQL_HOST=localhost` before
generating the MariaDB configuration. A second validation pass could not
distinguish that internal handoff from an external host and stopped the
container.

The renderer now receives an explicit internal `embedded` context only from
the bundled MariaDB startup path. Tests reproduce the internal `localhost`
state, verify the complete rendered configuration, and separately prove that
external mode and an operator-supplied external host remain rejected.

## Compatibility and publication gates

The runtime application stack, APIs, UI, ports, volumes, authentication,
catalog, host compatibility, and persisted-data formats are unchanged from
`v1.6.412`. The release keeps Orchestration Engine `0.183.295`, Web Console
`1.6.103`, WebSocket Proxy `0.23.14`, API Explorer `1.1.18`, Compose Executor
`0.14.36`, Node Agent `0.13.27`, and vSphere CLI Bundle `0.55.2`.

Publication requires the complete source gate, a clean image build, an actual
embedded-MariaDB and Java startup with tuned values, live value readback,
container restart and repeated readback, merged-rootfs Trivy vulnerability and
secret scans, CycloneDX SBOM, provenance and SBOM attestations, and an immutable
GitHub Release bound to the exact source commit.

The unchanged security base retains Ubuntu's official curl and libcurl
`8.18.0-1ubuntu2.5` fix for `CVE-2026-8932`, glibc
`2.43-2ubuntu2.4`, and the reviewed GNU coreutils `uniq` upstream fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`. Ubuntu still marks
`CVE-2026-18374` as needing evaluation for Resolute, so its OpenVEX status
remains an execution-path determination rather than a claim of an unavailable
package fix. The OpenSSL closure for `CVE-2026-75803` and removal of the
unreachable `diff3` path for `CVE-2026-53910` are inherited unchanged. Any
unmatched vulnerability at any severity remains a release blocker.
