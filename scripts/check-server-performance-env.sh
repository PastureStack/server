#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
library="${repo_root}/server/artifacts/performance-env.sh"
work_root=$(mktemp -d)
trap 'rm -rf "$work_root"' EXIT

failures=0
checks=0

check()
{
    local description="$1"
    shift
    checks=$((checks + 1))
    if ! "$@"; then
        printf 'FAIL: %s\n' "$description" >&2
        failures=$((failures + 1))
    fi
}

contains()
{
    case "$1" in
        *"$2"*) return 0 ;;
        *) return 1 ;;
    esac
}

has_marker()
{
    local path="$1"
    local marker="$2"
    grep -Fq "$marker" "${repo_root}/${path}"
}

has_marker_count()
{
    local path="$1"
    local marker="$2"
    local minimum="$3"
    local count

    count=$(grep -Fc "$marker" "${repo_root}/${path}" || true)
    [ "$count" -ge "$minimum" ]
}

validation_fails()
{
    local body="$1"
    env -i PATH="$PATH" PERF_LIB="$library" VALIDATION_BODY="$body" bash -c \
        'source "$PERF_LIB"; eval "$VALIDATION_BODY"; pasturestack_validate_performance_env' \
        >/dev/null 2>&1 \
        && return 1
    return 0
}

source "$library"

check 'entrypoint validates typed performance settings before service startup' \
    has_marker server/bin/entry 'pasturestack_validate_performance_env'
check 'Java launcher consumes typed settings' \
    has_marker server/artifacts/cattle.sh 'pasturestack_java_common_opts'
check 'MariaDB startup renders typed settings' \
    has_marker server/artifacts/mysql.sh 'pasturestack_write_mariadb_config'
check 'embedded MariaDB startup declares its database context' \
    has_marker server/artifacts/mysql.sh \
        '/etc/mysql/mariadb.conf.d/99-pasturestack.cnf embedded'
check 'MariaDB startup verifies live readback' \
    has_marker server/artifacts/mysql.sh 'verify_mariadb_performance_settings'
check 'incremental release image installs the canonical scripts' \
    has_marker server/Dockerfile.web-compose-release \
        'COPY --chmod=0755 artifacts/cattle.sh artifacts/mysql.sh artifacts/performance-env.sh /usr/share/cattle/'
check 'external-DB image keeps the Java helper dependency' \
    has_marker server/Dockerfile.externaldb \
        'COPY --chmod=0755 artifacts/cattle.sh artifacts/performance-env.sh /usr/share/cattle/'
check 'legacy patch image keeps the Java helper dependency' \
    has_marker server/Dockerfile.api-explorer-patch \
        'COPY artifacts/cattle.sh artifacts/performance-env.sh /usr/share/cattle/'
check 'external databases reject embedded MariaDB tuning' \
    has_marker server/artifacts/performance-env.sh \
        'applies only to the embedded MariaDB'
check 'entrypoint revalidates after parsing legacy DB arguments' \
    has_marker_count server/bin/entry \
        'pasturestack_validate_performance_env' 2
check 'operator documentation states the host-kernel boundary' \
    has_marker docs/performance/README.md \
        'They cannot be implemented honestly as container'

unset CATTLE_JAVA_OPTS
unset PASTURESTACK_JAVA_INITIAL_HEAP PASTURESTACK_JAVA_MAX_HEAP
unset PASTURESTACK_JAVA_ALWAYS_PRETOUCH PASTURESTACK_JAVA_GC_LOG_ENABLED
unset PASTURESTACK_JAVA_GC_LOG_FILE_COUNT PASTURESTACK_JAVA_GC_LOG_FILE_SIZE
unset PASTURESTACK_MARIADB_BUFFER_POOL_SIZE PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX
unset PASTURESTACK_MARIADB_REDO_LOG_SIZE PASTURESTACK_MARIADB_QUERY_CACHE_TYPE
unset PASTURESTACK_MARIADB_QUERY_CACHE_SIZE
unset PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT
unset PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE PASTURESTACK_MARIADB_SYNC_BINLOG

check 'default environment validates' pasturestack_validate_performance_env

default_config="$work_root/default.cnf"
pasturestack_write_mariadb_config "$default_config"
cat >"$work_root/default.expected" <<'EOF'
[mysqld]
bind-address = 0.0.0.0
max_connections = 1000
expire_logs_days = 2
innodb_file_per_table = 1
innodb_snapshot_isolation = OFF
sql_mode = ONLY_FULL_GROUP_BY
EOF
check 'default MariaDB configuration remains unchanged' \
    cmp "$work_root/default.expected" "$default_config"

export PASTURESTACK_JAVA_INITIAL_HEAP=2g
export PASTURESTACK_JAVA_MAX_HEAP=8g
export PASTURESTACK_JAVA_ALWAYS_PRETOUCH=TRUE
export PASTURESTACK_JAVA_GC_LOG_ENABLED=true
export PASTURESTACK_JAVA_GC_LOG_FILE_COUNT=7
export PASTURESTACK_JAVA_GC_LOG_FILE_SIZE=32m
export PASTURESTACK_MARIADB_BUFFER_POOL_SIZE=4g
export PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX=12g
export PASTURESTACK_MARIADB_REDO_LOG_SIZE=512m
export PASTURESTACK_MARIADB_QUERY_CACHE_TYPE=off
export PASTURESTACK_MARIADB_QUERY_CACHE_SIZE=0
export PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=1
export PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE=on
export PASTURESTACK_MARIADB_SYNC_BINLOG=1

check 'documented dedicated-host environment validates' pasturestack_validate_performance_env
java_opts=$(pasturestack_java_common_opts 4g)
check 'Java initial heap is rendered' contains "$java_opts" '-Xms2g'
check 'Java maximum heap is rendered' contains "$java_opts" '-Xmx8g'
check 'Java pretouch is rendered case-insensitively' contains "$java_opts" '-XX:+AlwaysPreTouch'
check 'bounded GC log is rendered' contains "$java_opts" \
    '-Xlog:gc*,safepoint:file=/var/lib/cattle/logs/gc.log:time,uptime,level,tags:filecount=7,filesize=32m'

tuned_config="$work_root/tuned.cnf"
pasturestack_write_mariadb_config "$tuned_config"
for expected_line in \
    'innodb_buffer_pool_size = 4G' \
    'innodb_buffer_pool_size_max = 12G' \
    'innodb_log_file_size = 512M' \
    'query_cache_type = OFF' \
    'query_cache_size = 0' \
    'innodb_flush_log_at_trx_commit = 1' \
    'innodb_doublewrite = ON' \
    'sync_binlog = 1'
do
    check "MariaDB config contains ${expected_line}" grep -Fxq "$expected_line" "$tuned_config"
done

export CATTLE_DB_CATTLE_MYSQL_HOST=localhost
embedded_config="$work_root/embedded.cnf"
check 'embedded MariaDB localhost is not misclassified as an external database' \
    pasturestack_write_mariadb_config "$embedded_config" embedded
check 'embedded MariaDB renders the same validated configuration' \
    cmp "$tuned_config" "$embedded_config"
unset CATTLE_DB_CATTLE_MYSQL_HOST

check 'heap injection is rejected' validation_fails \
    'export PASTURESTACK_JAVA_MAX_HEAP="8g -Dunsafe=true"'
check 'initial heap above maximum is rejected' validation_fails \
    'export PASTURESTACK_JAVA_INITIAL_HEAP=8g PASTURESTACK_JAVA_MAX_HEAP=2g'
check 'legacy complete options cannot silently override typed Java settings' validation_fails \
    'export CATTLE_JAVA_OPTS=-Xmx4g PASTURESTACK_JAVA_MAX_HEAP=8g'
check 'invalid Java boolean is rejected' validation_fails \
    'export PASTURESTACK_JAVA_ALWAYS_PRETOUCH=yes'
check 'GC rotation without enabled logging is rejected' validation_fails \
    'export PASTURESTACK_JAVA_GC_LOG_FILE_COUNT=5'
check 'buffer-pool maximum requires an explicit current size' validation_fails \
    'export PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX=12g'
check 'external-DB mode rejects embedded MariaDB tuning' validation_fails \
    'export PASTURESTACK_SERVER_MODE=externaldb PASTURESTACK_MARIADB_BUFFER_POOL_SIZE=4g'
check 'external database host rejects embedded MariaDB tuning' validation_fails \
    'export CATTLE_DB_CATTLE_MYSQL_HOST=db.example.test PASTURESTACK_MARIADB_BUFFER_POOL_SIZE=4g'
check 'buffer-pool current size above maximum is rejected' validation_fails \
    'export PASTURESTACK_MARIADB_BUFFER_POOL_SIZE=8g PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX=4g'
check 'invalid query-cache mode is rejected' validation_fails \
    'export PASTURESTACK_MARIADB_QUERY_CACHE_TYPE=maybe'
check 'invalid durability value is rejected' validation_fails \
    'export PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT=3'
check 'empty configured values are rejected' validation_fails \
    'export PASTURESTACK_MARIADB_REDO_LOG_SIZE='

if [ "$failures" -ne 0 ]; then
    printf 'SERVER_PERFORMANCE_ENV_FAILED checks=%s failures=%s\n' "$checks" "$failures" >&2
    exit 1
fi

printf 'SERVER_PERFORMANCE_ENV_OK checks=%s typed_values=1 injection_rejected=1 default_behavior_preserved=1\n' "$checks"
