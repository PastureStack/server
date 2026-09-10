#!/bin/bash

set -eo pipefail

DATADIR='/var/lib/mysql'
MYSQL_SOCKET='/var/run/mysqld/mysqld.sock'
source /usr/share/cattle/performance-env.sh

mysql_bin()
{
    command -v mariadb || command -v mysql
}

mysqladmin_bin()
{
    command -v mariadb-admin || command -v mysqladmin
}

mysqld_bin()
{
    command -v mariadbd || command -v mysqld
}

tzinfo_to_sql_bin()
{
    command -v mariadb-tzinfo-to-sql || command -v mysql_tzinfo_to_sql
}

check_mysql_action()
{
    local action=$1

    local cmd1="break"
    local cmd2="sleep 1"
    if [ "${action}" == "stop" ]; then
        cmd1="sleep 1"
        cmd2="break"
    fi

    set +e
    for ((i=0;i<60;i++))
    do
        if "$(mysqladmin_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" status 2> /dev/null; then
            ${cmd1}
        else
            if [ "$i" -eq "59" ]; then
                echo "Could not ${action} MySQL..." 1>&2
                exit 1
            fi
            ${cmd2}
        fi
    done
    set -e
}

init_new_data_dir()
{
    local pidfile="${DATADIR}/mysql.pid"
    local install_db
    local install_db_rpm=""

    mkdir -p /var/run/mysqld /var/log/mysql
    chown -R mysql:mysql /var/run/mysqld /var/log/mysql "${DATADIR}"

    # If a blank directory is bind mounted, configure it.
    echo "Running mysql_install_db..."
    install_db="$(command -v mariadb-install-db || command -v mysql_install_db)"
    if "${install_db}" --help 2>&1 | grep -q -- '--rpm'; then
        install_db_rpm="--rpm"
    fi
    "${install_db}" --user=mysql --datadir="${DATADIR}" ${install_db_rpm} --basedir=/usr

    echo "Starting MySQL to initialize..."
    "$(mysqld_bin)" --user=mysql --datadir="${DATADIR}" --skip-networking --basedir=/usr --socket="${MYSQL_SOCKET}" --pid-file="${pidfile}" &
    echo "Waiting for mysql to start"
    check_mysql_action start

    "$(tzinfo_to_sql_bin)" /usr/share/zoneinfo | "$(mysql_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" -uroot mysql

    kill $(<"${pidfile}")
    check_mysql_action stop
    echo "Exiting MySQL initialization"
}


config_mysql()
{
    mkdir -p /etc/mysql/mariadb.conf.d /var/run/mysqld /var/log/mysql
    chown -R mysql:mysql /var/run/mysqld /var/log/mysql
    pasturestack_write_mariadb_config \
        /etc/mysql/mariadb.conf.d/99-pasturestack.cnf embedded
}


mysql_global_variable()
{
    local variable="$1"
    "$(mysql_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" -uroot -NBe \
        "SELECT @@GLOBAL.${variable}"
}


verify_mariadb_size_setting()
{
    local setting="$1"
    local variable="$2"
    local expected
    local actual

    if ! pasturestack_env_is_set "$setting"; then
        return 0
    fi
    if [ "${!setting}" = 0 ]; then
        expected=0
    else
        expected=$(pasturestack_size_bytes "${!setting}")
    fi
    actual=$(mysql_global_variable "$variable")
    if [ "$actual" != "$expected" ]; then
        pasturestack_performance_error \
            "$setting" \
            "MariaDB 讀回 ${variable}=${actual}，預期 ${expected} / MariaDB readback did not match"
        return 1
    fi
}


verify_mariadb_text_setting()
{
    local setting="$1"
    local variable="$2"
    local expected="${!setting}"
    local actual

    if ! pasturestack_env_is_set "$setting"; then
        return 0
    fi
    case "$setting" in
        PASTURESTACK_MARIADB_QUERY_CACHE_TYPE|PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE)
            expected="${expected^^}"
            ;;
    esac
    actual=$(mysql_global_variable "$variable")
    if [ "$actual" != "$expected" ]; then
        pasturestack_performance_error \
            "$setting" \
            "MariaDB 讀回 ${variable}=${actual}，預期 ${expected} / MariaDB readback did not match"
        return 1
    fi
}


verify_mariadb_performance_settings()
{
    verify_mariadb_size_setting PASTURESTACK_MARIADB_BUFFER_POOL_SIZE innodb_buffer_pool_size
    verify_mariadb_size_setting PASTURESTACK_MARIADB_BUFFER_POOL_SIZE_MAX innodb_buffer_pool_size_max
    verify_mariadb_size_setting PASTURESTACK_MARIADB_REDO_LOG_SIZE innodb_log_file_size
    verify_mariadb_text_setting PASTURESTACK_MARIADB_QUERY_CACHE_TYPE query_cache_type
    verify_mariadb_size_setting PASTURESTACK_MARIADB_QUERY_CACHE_SIZE query_cache_size
    verify_mariadb_text_setting PASTURESTACK_MARIADB_INNODB_FLUSH_LOG_AT_TRX_COMMIT innodb_flush_log_at_trx_commit
    verify_mariadb_text_setting PASTURESTACK_MARIADB_INNODB_DOUBLEWRITE innodb_doublewrite
    verify_mariadb_text_setting PASTURESTACK_MARIADB_SYNC_BINLOG sync_binlog
}


start_mysql()
{
    s6-svc -u ${S6_SERVICE_DIR}/mysql
    check_mysql_action start
}


setup_cattle_db()
{
    local db_user=$CATTLE_DB_CATTLE_USERNAME
    local db_pass=$CATTLE_DB_CATTLE_PASSWORD
    local db_name=$CATTLE_DB_CATTLE_MYSQL_NAME

    echo "Setting up database"
    "$(mysql_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" -uroot<< EOF
CREATE DATABASE IF NOT EXISTS ${db_name} COLLATE = 'utf8_general_ci' CHARACTER SET = 'utf8';
GRANT ALL ON ${db_name}.* TO "${db_user}"@'%' IDENTIFIED BY "${db_pass}";
GRANT ALL ON ${db_name}.* TO "${db_user}"@'localhost' IDENTIFIED BY "${db_pass}";
EOF

    if ! echo 'show tables' | "$(mysql_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" -uroot $db_name | grep -iq account; then
        echo "Importing schema"
        "$(mysql_bin)" --protocol=socket --socket="${MYSQL_SOCKET}" -uroot $db_name < /usr/share/cattle/mysql-dump.sql
    fi

}

## Boot2docker hack
if [ "$(grep /var/lib/mysql /proc/mounts|cut -d' ' -f3)" = "vboxsf" ]; then
    echo "Running in VBox change mysql UID"
    uid=$(stat -c "%u" ${DATADIR})
    usermod -u ${uid} mysql
    chown -R mysql /var/run/mysqld
    chown -R mysql /var/log/mysql
fi

if [ ! -d "${DATADIR}/mysql" ]; then
    init_new_data_dir
fi

config_mysql
start_mysql
verify_mariadb_performance_settings
setup_cattle_db
