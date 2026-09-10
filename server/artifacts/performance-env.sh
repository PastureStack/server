#!/bin/bash

# Shared validation and rendering for the supported performance environment
# variables. Keep this file side-effect free when sourced.

pasturestack_performance_error()
{
    local setting="$1"
    local reason="$2"

    case "${PASTURESTACK_LOCALE:-en-US}" in
        zh-TW|zh-tw|zh_Hant_TW)
            printf 'PastureStack 效能設定 %s 無效：%s\n' "$setting" "$reason" >&2
            ;;
        *)
            printf 'Invalid PastureStack performance setting %s: %s\n' "$setting" "$reason" >&2
            ;;
    esac
    return 1
}

pasturestack_env_is_set()
{
    [[ -v "$1" ]]
}

pasturestack_require_nonempty()
{
    local setting="$1"
    local value="${!setting}"

    if [ -z "$value" ]; then
        pasturestack_performance_error "$setting" '不可為空白 / must not be empty'
    fi
}

pasturestack_require_size()
{
    local setting="$1"
    local value="${!setting}"
    local suffixes="$2"

    pasturestack_require_nonempty "$setting" || return 1
    if [[ ! "$value" =~ ^[1-9][0-9]{0,6}[$suffixes]$ ]]; then
        pasturestack_performance_error \
            "$setting" \
            "必須是正整數加上 ${suffixes} 單位，例如 512m 或 8g / must be a positive size such as 512m or 8g"
    fi
}

pasturestack_size_bytes()
{
    local value="$1"
    local number="${value:0:${#value}-1}"
    local suffix="${value: -1}"
    local multiplier

    case "$suffix" in
        k|K) multiplier=1024 ;;
        m|M) multiplier=1048576 ;;
        g|G) multiplier=1073741824 ;;
        *) return 1 ;;
    esac
    printf '%s\n' "$((10#$number * multiplier))"
}

pasturestack_normalize_java_size()
{
    local value="$1"
    printf '%s%s\n' "${value:0:${#value}-1}" "${value: -1}" | tr 'KMG' 'kmg'
}

pasturestack_normalize_mariadb_size()
{
    local value="$1"
    if [ "$value" = 0 ]; then
        printf '0\n'
        return 0
    fi
    printf '%s%s\n' "${value:0:${#value}-1}" "${value: -1}" | tr 'mg' 'MG'
}

pasturestack_require_boolean()
{
    local setting="$1"
    local value="${!setting}"

    pasturestack_require_nonempty "$setting" || return 1
    case "${value,,}" in
        true|false) ;;
        *)
            pasturestack_performance_error \
                "$setting" \
                '只接受 true 或 false / must be true or false'
            ;;
    esac
}

pasturestack_require_integer_range()
{
    local setting="$1"
    local minimum="$2"
    local maximum="$3"
    local value="${!setting}"

    pasturestack_require_nonempty "$setting" || return 1
    if [[ ! "$value" =~ ^(0|[1-9][0-9]{0,9})$ ]] ||
       [ "$value" -lt "$minimum" ] || [ "$value" -gt "$maximum" ]; then
        pasturestack_performance_error \
            "$setting" \
            "必須介於 ${minimum} 到 ${maximum} / must be between ${minimum} and ${maximum}"
    fi
}

pasturestack_java_tuning_is_set()
{
    local setting
    for setting in \
        PASTURESTACK_JAVA_INITIAL_HEAP \
        PASTURESTACK_JAVA_MAX_HEAP \
        PASTURESTACK_JAVA_ALWAYS_PRETOUCH \
        PASTURESTACK_JAVA_GC_LOG_ENABLED \
        PASTURESTACK_JAVA_GC_LOG_FILE_COUNT \
        PASTURESTACK_JAVA_GC_LOG_FILE_SIZE
    do
        if pasturestack_env_is_set "$setting"; then
            return 0
        fi
    done
    return 1
}

pasturestack_mariadb_tuning_is_set()
{
    local setting
    for setting in \
        PASTURESTACK_MARIADB_BUFFER_POOL_SIZE \
        PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX \
        PASTURESTACK_MARIADB_REDO_LOG_SIZE \
        PASTURESTACK_MARIADB_QUERY_CACHE_TYPE \
        PASTURESTACK_MARIADB_QUERY_CACHE_SIZE \
        PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT \
        PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE \
        PASTURESTACK_MARIADB_SYNC_BINLOG
    do
        if pasturestack_env_is_set "$setting"; then
            return 0
        fi
    done
    return 1
}

pasturestack_validate_performance_env()
{
    local setting
    local initial_bytes
    local maximum_bytes
    local pool_bytes
    local pool_max_bytes
    local gc_log_enabled="${PASTURESTACK_JAVA_GC_LOG_ENABLED:-}"

    if pasturestack_mariadb_tuning_is_set &&
       { [ "${PASTURESTACK_SERVER_MODE:-${RC16_SERVER_MODE:-}}" = externaldb ] ||
         [ -n "${CATTLE_DB_CATTLE_MYSQL_HOST:-}" ] ||
         [ -n "${MYSQL_PORT_3306_TCP_ADDR:-}" ]; }; then
        pasturestack_performance_error \
            PASTURESTACK_MARIADB_\* \
            '只適用於映像內建 MariaDB；外接資料庫必須在資料庫服務端調校 / applies only to the embedded MariaDB'
        return 1
    fi

    if [ -n "${CATTLE_JAVA_OPTS:-}" ] && pasturestack_java_tuning_is_set; then
        pasturestack_performance_error \
            CATTLE_JAVA_OPTS \
            '不可和 PASTURESTACK_JAVA_* 同時設定 / cannot be combined with PASTURESTACK_JAVA_*'
        return 1
    fi

    for setting in PASTURESTACK_JAVA_INITIAL_HEAP PASTURESTACK_JAVA_MAX_HEAP
    do
        if pasturestack_env_is_set "$setting"; then
            pasturestack_require_size "$setting" 'KkMmGg' || return 1
        fi
    done
    if pasturestack_env_is_set PASTURESTACK_JAVA_INITIAL_HEAP &&
       pasturestack_env_is_set PASTURESTACK_JAVA_MAX_HEAP; then
        initial_bytes=$(pasturestack_size_bytes "$PASTURESTACK_JAVA_INITIAL_HEAP")
        maximum_bytes=$(pasturestack_size_bytes "$PASTURESTACK_JAVA_MAX_HEAP")
        if [ "$initial_bytes" -gt "$maximum_bytes" ]; then
            pasturestack_performance_error \
                PASTURESTACK_JAVA_INITIAL_HEAP \
                '不可大於 PASTURESTACK_JAVA_MAX_HEAP / cannot exceed PASTURESTACK_JAVA_MAX_HEAP'
            return 1
        fi
    fi

    for setting in PASTURESTACK_JAVA_ALWAYS_PRETOUCH PASTURESTACK_JAVA_GC_LOG_ENABLED
    do
        if pasturestack_env_is_set "$setting"; then
            pasturestack_require_boolean "$setting" || return 1
        fi
    done
    if pasturestack_env_is_set PASTURESTACK_JAVA_GC_LOG_FILE_COUNT; then
        pasturestack_require_integer_range PASTURESTACK_JAVA_GC_LOG_FILE_COUNT 1 64 || return 1
    fi
    if pasturestack_env_is_set PASTURESTACK_JAVA_GC_LOG_FILE_SIZE; then
        pasturestack_require_size PASTURESTACK_JAVA_GC_LOG_FILE_SIZE 'KkMmGg' || return 1
    fi
    if { pasturestack_env_is_set PASTURESTACK_JAVA_GC_LOG_FILE_COUNT ||
         pasturestack_env_is_set PASTURESTACK_JAVA_GC_LOG_FILE_SIZE; } &&
       [ "${gc_log_enabled,,}" != true ]; then
        pasturestack_performance_error \
            PASTURESTACK_JAVA_GC_LOG_ENABLED \
            '設定日誌輪替大小或份數時必須啟用 GC 日誌 / must be true when log rotation settings are provided'
        return 1
    fi

    for setting in \
        PASTURESTACK_MARIADB_BUFFER_POOL_SIZE \
        PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX \
        PASTURESTACK_MARIADB_REDO_LOG_SIZE
    do
        if pasturestack_env_is_set "$setting"; then
            pasturestack_require_size "$setting" 'MmGg' || return 1
        fi
    done
    if pasturestack_env_is_set PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX &&
       ! pasturestack_env_is_set PASTURESTACK_MARIADB_BUFFER_POOL_SIZE; then
        pasturestack_performance_error \
            PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX \
            '設定上限時也必須設定目前大小 / requires PASTURESTACK_MARIADB_BUFFER_POOL_SIZE'
        return 1
    fi
    if pasturestack_env_is_set PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX; then
        pool_bytes=$(pasturestack_size_bytes "$PASTURESTACK_MARIADB_BUFFER_POOL_SIZE")
        pool_max_bytes=$(pasturestack_size_bytes "$PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX")
        if [ "$pool_bytes" -gt "$pool_max_bytes" ]; then
            pasturestack_performance_error \
                PASTURESTACK_MARIADB_BUFFER_POOL_SIZE \
                '不可大於 PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX / cannot exceed PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX'
            return 1
        fi
    fi

    if pasturestack_env_is_set PASTURESTACK_MARIADB_QUERY_CACHE_TYPE; then
        pasturestack_require_nonempty PASTURESTACK_MARIADB_QUERY_CACHE_TYPE || return 1
        case "${PASTURESTACK_MARIADB_QUERY_CACHE_TYPE^^}" in
            OFF|ON|DEMAND) ;;
            *)
                pasturestack_performance_error \
                    PASTURESTACK_MARIADB_QUERY_CACHE_TYPE \
                    '只接受 OFF、ON 或 DEMAND / must be OFF, ON, or DEMAND'
                return 1
                ;;
        esac
    fi
    if pasturestack_env_is_set PASTURESTACK_MARIADB_QUERY_CACHE_SIZE; then
        if [ "$PASTURESTACK_MARIADB_QUERY_CACHE_SIZE" != 0 ]; then
            pasturestack_require_size PASTURESTACK_MARIADB_QUERY_CACHE_SIZE 'MmGg' || return 1
        fi
    fi
    if pasturestack_env_is_set PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT; then
        pasturestack_require_integer_range PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT 0 2 || return 1
    fi
    if pasturestack_env_is_set PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE; then
        pasturestack_require_nonempty PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE || return 1
        case "${PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE^^}" in
            ON|OFF) ;;
            *)
                pasturestack_performance_error \
                    PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE \
                    '只接受 ON 或 OFF / must be ON or OFF'
                return 1
                ;;
        esac
    fi
    if pasturestack_env_is_set PASTURESTACK_MARIADB_SYNC_BINLOG; then
        pasturestack_require_integer_range PASTURESTACK_MARIADB_SYNC_BINLOG 0 1000000 || return 1
    fi
}

pasturestack_java_common_opts()
{
    local automatic_max="$1"
    local initial="${PASTURESTACK_JAVA_INITIAL_HEAP:-128m}"
    local maximum="${PASTURESTACK_JAVA_MAX_HEAP:-$automatic_max}"
    local initial_bytes
    local maximum_bytes
    local opts
    local pretouch="${PASTURESTACK_JAVA_ALWAYS_PRETOUCH:-false}"
    local gc_log_enabled="${PASTURESTACK_JAVA_GC_LOG_ENABLED:-false}"

    PASTURESTACK_JAVA_INITIAL_HEAP="$initial" pasturestack_require_size PASTURESTACK_JAVA_INITIAL_HEAP 'KkMmGg' || return 1
    PASTURESTACK_JAVA_MAX_HEAP="$maximum" pasturestack_require_size PASTURESTACK_JAVA_MAX_HEAP 'KkMmGg' || return 1
    initial_bytes=$(pasturestack_size_bytes "$initial")
    maximum_bytes=$(pasturestack_size_bytes "$maximum")
    if [ "$initial_bytes" -gt "$maximum_bytes" ]; then
        pasturestack_performance_error \
            PASTURESTACK_JAVA_INITIAL_HEAP \
            '不可大於實際 Java heap 上限 / cannot exceed the effective Java maximum heap'
        return 1
    fi

    initial=$(pasturestack_normalize_java_size "$initial")
    maximum=$(pasturestack_normalize_java_size "$maximum")
    opts="-Xms${initial} -Xmx${maximum} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/lib/cattle/logs"

    if [ "${pretouch,,}" = true ]; then
        opts="${opts} -XX:+AlwaysPreTouch"
    fi
    if [ "${gc_log_enabled,,}" = true ]; then
        local count="${PASTURESTACK_JAVA_GC_LOG_FILE_COUNT:-5}"
        local size="${PASTURESTACK_JAVA_GC_LOG_FILE_SIZE:-20m}"
        size=$(pasturestack_normalize_java_size "$size")
        opts="${opts} -Xlog:gc*,safepoint:file=/var/lib/cattle/logs/gc.log:time,uptime,level,tags:filecount=${count},filesize=${size}"
    fi

    printf '%s\n' "$opts"
}

pasturestack_write_mariadb_config()
{
    local target="$1"
    local temporary="${target}.tmp.$$"
    local value

    pasturestack_validate_performance_env || return 1
    umask 022
    {
        cat << 'EOF'
[mysqld]
bind-address = 0.0.0.0
max_connections = 1000
expire_logs_days = 2
innodb_file_per_table = 1
innodb_snapshot_isolation = OFF
sql_mode = ONLY_FULL_GROUP_BY
EOF
        if pasturestack_env_is_set PASTURESTACK_MARIADB_BUFFER_POOL_SIZE; then
            value=$(pasturestack_normalize_mariadb_size "$PASTURESTACK_MARIADB_BUFFER_POOL_SIZE")
            printf 'innodb_buffer_pool_size = %s\n' "$value"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX; then
            value=$(pasturestack_normalize_mariadb_size "$PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX")
            printf 'innodb_buffer_pool_size_max = %s\n' "$value"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_REDO_LOG_SIZE; then
            value=$(pasturestack_normalize_mariadb_size "$PASTURESTACK_MARIADB_REDO_LOG_SIZE")
            printf 'innodb_log_file_size = %s\n' "$value"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_QUERY_CACHE_TYPE; then
            printf 'query_cache_type = %s\n' "${PASTURESTACK_MARIADB_QUERY_CACHE_TYPE^^}"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_QUERY_CACHE_SIZE; then
            value=$(pasturestack_normalize_mariadb_size "$PASTURESTACK_MARIADB_QUERY_CACHE_SIZE")
            printf 'query_cache_size = %s\n' "$value"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT; then
            printf 'innodb_flush_log_at_trx_commit = %s\n' "$PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE; then
            printf 'innodb_doublewrite = %s\n' "${PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE^^}"
        fi
        if pasturestack_env_is_set PASTURESTACK_MARIADB_SYNC_BINLOG; then
            printf 'sync_binlog = %s\n' "$PASTURESTACK_MARIADB_SYNC_BINLOG"
        fi
    } >"$temporary"
    chmod 0644 "$temporary"
    mv -f "$temporary" "$target"
}
