# PastureStack Server v1.6.412

> **Superseded by `v1.6.413`.** The `v1.6.412` image correctly validates and
> renders the typed settings, but embedded MariaDB startup can misclassify its
> own internal `localhost` handoff as an external database when
> `PASTURESTACK_MARIADB_*` is configured. Use `v1.6.413` for these settings.

This release makes the reviewed JVM and embedded MariaDB performance settings
first-class Docker Compose environment variables. Operators no longer need to
replace image files or maintain a custom MariaDB configuration for these
settings.

## Operator-visible result

- Java initial and maximum heap, pre-touch, and bounded GC plus safepoint log
  rotation can be configured independently with typed `PASTURESTACK_JAVA_*`
  variables.
- Embedded MariaDB buffer-pool size and upper bound, redo-log size, query-cache
  state, transaction-log flush policy, doublewrite state, and binlog sync can
  be configured independently with typed `PASTURESTACK_MARIADB_*` variables.
- Omitting every new variable preserves the established Server defaults.
- Invalid sizes, unsafe free-form fragments, conflicting legacy JVM options,
  impossible size relationships, and embedded-database settings in external-DB
  mode fail before the Server starts.
- Requested MariaDB values are read back from the live database after startup;
  a later configuration override therefore fails visibly instead of appearing
  to work.

The complete Docker Compose example and every supported variable are in the
[performance settings guide](../performance/README.md). Host-wide
`vm.swappiness` and dirty-page controls remain host kernel settings; this
release does not request privileged container access to disguise them as
container configuration.

## Compatibility and validation

The runtime application stack remains Orchestration Engine `0.183.295`, Web
Console `1.6.103`, WebSocket Proxy `0.23.14`, API Explorer `1.1.18`, Compose
Executor `0.14.36`, Node Agent `0.13.27`, and vSphere CLI Bundle `0.55.2` from
`v1.6.411`. Existing API, UI, ports, volumes, database contents, OIDC behavior,
container-management workflows, and host compatibility are unchanged.

The environment contract has deterministic tests for default preservation,
every accepted value, Java and MariaDB rendering, external-DB rejection, and
invalid-input failure. Release validation additionally starts a real embedded
database and Java process with tuned settings, verifies their effective values,
restarts the same container, and repeats the readback. It also starts the image
without any new setting and checks the prior JVM and MariaDB defaults.

Publication still requires all Server source gates, a clean no-cache image
build, initial and restart `pong`, the public-origin and private-cache API
contract, merged-rootfs Trivy vulnerability and secret scans, CycloneDX SBOM,
provenance and SBOM attestations, and an immutable GitHub Release bound to the
exact source commit. Any unmatched vulnerability at any severity remains a release blocker.

The unchanged security base retains Ubuntu's official curl and libcurl
`8.18.0-1ubuntu2.5` fix for `CVE-2026-8932`, glibc
`2.43-2ubuntu2.4`, and the reviewed GNU coreutils `uniq` upstream fix
`d64e35a8a4c0e4608321433e0d84d917e4e36371`. Ubuntu still marks
`CVE-2026-18374` as needing evaluation for Resolute, so its OpenVEX status
remains an execution-path determination rather than a claim of an unavailable
package fix. The OpenSSL closure for `CVE-2026-75803` and removal of the
unreachable `diff3` path for `CVE-2026-53910` are also inherited unchanged.
