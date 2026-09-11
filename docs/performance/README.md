# Server performance settings

PastureStack Server supports typed performance settings through Docker or
Docker Compose environment variables. These settings are optional: omitting
all of them preserves the image defaults.

The following example is appropriate as a starting point for a dedicated
16-vCPU host with about 32 GiB of RAM. It is not a universal performance
profile; measure the real workload before increasing it further.

```yaml
services:
  pasturestack-server:
    image: ghcr.io/pasturestack/server:v1.6.420
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      PASTURESTACK_JAVA_INITIAL_HEAP: 2g
      PASTURESTACK_JAVA_MAX_HEAP: 8g
      PASTURESTACK_JAVA_ALWAYS_PRETOUCH: "true"
      PASTURESTACK_JAVA_GC_LOG_ENABLED: "true"
      PASTURESTACK_JAVA_GC_LOG_FILE_COUNT: "5"
      PASTURESTACK_JAVA_GC_LOG_FILE_SIZE: 20m

      PASTURESTACK_MARIADB_BUFFER_POOL_SIZE: 4g
      PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX: 12g
      PASTURESTACK_MARIADB_REDO_LOG_SIZE: 512m
      PASTURESTACK_MARIADB_QUERY_CACHE_TYPE: "OFF"
      PASTURESTACK_MARIADB_QUERY_CACHE_SIZE: "0"
      PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT: "1"
      PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE: "ON"
      PASTURESTACK_MARIADB_SYNC_BINLOG: "1"
    volumes:
      - pasturestack-cattle:/var/lib/cattle
      - pasturestack-mysql:/var/lib/mysql
      - pasturestack-mysqllog:/var/log/mysql

volumes:
  pasturestack-cattle:
  pasturestack-mysql:
  pasturestack-mysqllog:
```

Each setting is independent unless a relationship is listed below:

| Environment variable | Omitted value / behavior |
| --- | --- |
| `PASTURESTACK_JAVA_INITIAL_HEAP` | `128m` |
| `PASTURESTACK_JAVA_MAX_HEAP` | Existing automatic `1g`, `2g`, or `4g` limit based on visible memory |
| `PASTURESTACK_JAVA_ALWAYS_PRETOUCH` | `false` |
| `PASTURESTACK_JAVA_GC_LOG_ENABLED` | `false` |
| `PASTURESTACK_JAVA_GC_LOG_FILE_COUNT` | `5` when GC logging is enabled |
| `PASTURESTACK_JAVA_GC_LOG_FILE_SIZE` | `20m` when GC logging is enabled |
| `PASTURESTACK_MARIADB_BUFFER_POOL_SIZE` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX` | Preserve the MariaDB/image default; requires the current size when set |
| `PASTURESTACK_MARIADB_REDO_LOG_SIZE` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_QUERY_CACHE_TYPE` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_QUERY_CACHE_SIZE` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE` | Preserve the MariaDB/image default |
| `PASTURESTACK_MARIADB_SYNC_BINLOG` | Preserve the MariaDB/image default |

## Guardrails

- Size values require an explicit `k`, `m`, or `g` suffix for Java and an
  explicit `m` or `g` suffix for MariaDB. Arbitrary JVM or MariaDB fragments
  are not accepted through these variables.
- The initial Java heap cannot exceed its maximum. A MariaDB buffer-pool
  maximum requires the current buffer-pool size and cannot be smaller than it.
- GC log file size or file count cannot be supplied unless GC logging is also
  enabled, so a typo cannot leave apparently configured but inactive rotation.
- `CATTLE_JAVA_OPTS` remains available for compatibility, but it cannot be
  combined with the typed `PASTURESTACK_JAVA_*` settings. This prevents one
  configuration surface from silently overriding the other.
- The generated MariaDB configuration is checked again against the live
  database after startup. A later custom `.cnf` that overrides a requested
  value makes startup fail visibly instead of silently ignoring Compose.
- `PASTURESTACK_MARIADB_*` configures only the MariaDB embedded in the Server
  image. External-DB deployments reject these variables; tune the separate
  database service instead of accepting a setting that would have no effect.
- GC and safepoint logs are written to `/var/lib/cattle/logs/gc.log` with the
  configured size and file-count limits. The existing `/var/lib/cattle` volume
  therefore retains them across a container recreation.
- `PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX` is only an upper bound for a
  later administrator-initiated online resize. It does not automatically grow
  the active buffer pool.

The durability defaults are not weakened. Keep
`PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=1` and
`PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE=ON` unless the workload has a reviewed
reason to accept data-loss risk.

## Host-only kernel settings

`vm.swappiness`, `vm.dirty_background_bytes`, and `vm.dirty_bytes` belong to
the Docker host kernel. They cannot be implemented honestly as container
environment variables, and Docker does not allow these non-namespaced `vm.*`
settings under a normal service-level `sysctls` block.

Configure them on a dedicated host through its configuration management or an
explicit `/etc/sysctl.d` file, for example:

```text
vm.swappiness=1
vm.dirty_background_bytes=268435456
vm.dirty_bytes=1073741824
```

Do not grant the Server container privileged mode merely to change host kernel
settings.
