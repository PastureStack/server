#!/bin/bash

set -eo pipefail

DATADIR='/var/lib/mysql'
MYSQL_SOCKET='/var/run/mysqld/mysqld.sock'

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
    cat > /etc/mysql/mariadb.conf.d/99-pasturestack.cnf << EOF
[mysqld]
bind-address = 0.0.0.0
max_connections = 1000
expire_logs_days = 2
innodb_file_per_table = 1
innodb_snapshot_isolation = OFF
sql_mode = ONLY_FULL_GROUP_BY
EOF
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
setup_cattle_db
