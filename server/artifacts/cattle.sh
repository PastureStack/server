#!/bin/bash
set -e

cd /var/lib/cattle

JAR=/usr/share/cattle/cattle.jar
DEBUG_JAR=/var/lib/cattle/lib/cattle-debug.jar
LOG_DIR=/var/lib/cattle/logs
export S6_SERVICE_DIR=${S6_SERVICE_DIR:-$S6_SERVICE_DIR}

if [ "${URL:-}" != "" ]
then
    echo "Downloading $URL"
    DOWNLOADED_JAR=cattle-download.jar
    TMP_JAR="${DOWNLOADED_JAR}.tmp"
    rm -f "$TMP_JAR"
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "$TMP_JAR" "$URL"
    mv "$TMP_JAR" "$DOWNLOADED_JAR"
    JAR="$DOWNLOADED_JAR"
fi

if [ -e "$DEBUG_JAR" ]; then
    JAR="$DEBUG_JAR"
fi

HASH=$(sha256sum "$JAR" | awk '{print $1}')

setup_local_agents()
{
    if [ "${CATTLE_USE_LOCAL_ARTIFACTS}" == "true" ]; then
        if [ -f /usr/share/cattle/env_vars ]; then
            source /usr/share/cattle/env_vars
        fi
    fi
}

setup_graphite()
{
    # Setup Graphite
    export CATTLE_GRAPHITE_HOST=${CATTLE_GRAPHITE_HOST:-$GRAPHITE_PORT_2003_TCP_ADDR}
    export CATTLE_GRAPHITE_PORT=${CATTLE_GRAPHITE_PORT:-$GRAPHITE_PORT_2003_TCP_PORT}
}

setup_prometheus()
{
    # Setup Prometheus Graphite exporter
    if [ "${CATTLE_PROMETHEUS_EXPORTER}" == "true" ]; then
        s6-svc -u ${S6_SERVICE_DIR}/graphite_exporter
        export DEFAULT_CATTLE_GRAPHITE_HOST=127.0.0.1
        export DEFAULT_CATTLE_GRAPHITE_PORT=9109
    fi
}

setup_gelf()
{
    # Setup GELF
    export CATTLE_LOGBACK_OUTPUT_GELF_HOST=${CATTLE_LOGBACK_OUTPUT_GELF_HOST:-$GELF_PORT_12201_UDP_ADDR}
    export CATTLE_LOGBACK_OUTPUT_GELF_PORT=${CATTLE_LOGBACK_OUTPUT_GELF_PORT:-$GELF_PORT_12201_UDP_PORT}
    if [ -n "$CATTLE_LOGBACK_OUTPUT_GELF_HOST" ]; then
        export CATTLE_LOGBACK_OUTPUT_GELF=${CATTLE_LOGBACK_OUTPUT_GELF:-true}
    fi
}

setup_mysql()
{
    # Set in the Dockerfile by default... overriden by runtime.
    if [ ${CATTLE_DB_CATTLE_DATABASE} == "mysql" ]; then
        export CATTLE_DB_CATTLE_MYSQL_HOST=${CATTLE_DB_CATTLE_MYSQL_HOST:-$MYSQL_PORT_3306_TCP_ADDR}
        export CATTLE_DB_CATTLE_MYSQL_PORT=${CATTLE_DB_CATTLE_MYSQL_PORT:-$MYSQL_PORT_3306_TCP_PORT}
        export CATTLE_DB_CATTLE_USERNAME=${CATTLE_DB_CATTLE_USERNAME:-cattle}
        export CATTLE_DB_CATTLE_PASSWORD=${CATTLE_DB_CATTLE_PASSWORD:-cattle}
        export CATTLE_DB_CATTLE_MYSQL_NAME=${CATTLE_DB_CATTLE_MYSQL_NAME:-cattle}

        if [ -z "$CATTLE_DB_CATTLE_MYSQL_HOST" ]; then
            export CATTLE_DB_CATTLE_MYSQL_HOST="localhost"
            /usr/share/cattle/mysql.sh
        fi

        if [ -z "$CATTLE_DB_CATTLE_MYSQL_PORT" ]; then
            CATTLE_DB_CATTLE_MYSQL_PORT=3306
        fi

        if [ -z "${CATTLE_DB_CATTLE_MYSQL_URL:-}" ]; then
            export CATTLE_DB_CATTLE_MYSQL_URL="jdbc:mysql://${CATTLE_DB_CATTLE_MYSQL_HOST}:${CATTLE_DB_CATTLE_MYSQL_PORT}/${CATTLE_DB_CATTLE_MYSQL_NAME}?useUnicode=true&characterEncoding=UTF-8&characterSetResults=UTF-8&prepStmtCacheSize=517&cachePrepStmts=true&prepStmtCacheSqlLimit=4096&permitMysqlScheme&useMysqlMetadata=true"
        fi
    fi
}

linked_env_value()
{
    local name="$1"
    printf '%s' "${!name:-}"
}

setup_redis()
{
    local hosts=""
    local i=1

    while [ -n "$(linked_env_value "REDIS${i}_PORT_6379_TCP_ADDR")" ]; do
        local addr="$(linked_env_value "REDIS${i}_PORT_6379_TCP_ADDR")"
        local port="$(linked_env_value "REDIS${i}_PORT_6379_TCP_PORT")"
        local host="${addr}:${port}"

        if [ -n "$hosts" ]; then
            hosts="$hosts,$host"
        else
            hosts="$host"
        fi

        i=$((i+1))
    done

    if [ -n "$hosts" ]; then
        export CATTLE_REDIS_HOSTS=${CATTLE_REDIS_HOSTS:-$hosts}
    fi

    if [ -n "$CATTLE_REDIS_HOSTS" ]; then
        export CATTLE_MODULE_PROFILE_REDIS=true
    fi
}

setup_zk()
{
    local hosts=""
    local i=1

    while [ -n "$(linked_env_value "ZK${i}_PORT_2181_TCP_ADDR")" ]; do
        local addr="$(linked_env_value "ZK${i}_PORT_2181_TCP_ADDR")"
        local port="$(linked_env_value "ZK${i}_PORT_2181_TCP_PORT")"
        local host="${addr}:${port}"

        if [ -n "$hosts" ]; then
            hosts="$hosts,$host"
        else
            hosts="$host"
        fi

        i=$((i+1))
    done

    if [ -n "$hosts" ]; then
        export CATTLE_ZOOKEEPER_CONNECTION_STRING=${CATTLE_ZOOKEEPER_CONNECTION_STRING:-$hosts}
    fi

    if [ -n "$CATTLE_ZOOKEEPER_CONNECTION_STRING" ]; then
        export CATTLE_MODULE_PROFILE_ZOOKEEPER=true
    fi

    if [ -n "$CATTLE_ZOOKEEPER_CONNECTION_STRING" ]; then
        local ok=false
        for ((i=0; i<=30; i++)); do
            local host="$(echo $CATTLE_ZOOKEEPER_CONNECTION_STRING | cut -f1 -d, | cut -f1 -d:)"
            local port="$(echo $CATTLE_ZOOKEEPER_CONNECTION_STRING | cut -f1 -d, | cut -f2 -d:)"
            echo Waiting for Zookeeper at ${host}:${port}
            if [ "$(echo ruok | nc $host $port)" == "imok" ]; then
                ok=true
                break
            fi
            sleep 2
        done
        if [ "$ok" != "true" ]; then
            echo Failed waiting for Zookeeper at ${host}:${port}
            return 1
        fi
    fi
}

setup_proxy()
{
    if [ -n "$http_proxy" ]; then
        local host=$(echo $http_proxy | sed 's!.*//!!' | cut -f1 -d:)
        local port=$(echo $http_proxy | sed 's!.*//!!' | cut -f2 -d:)

        PROXY_ARGS="-Dhttp.proxyHost=${host}"
        if [ "$host" != "$port" ]; then
            PROXY_ARGS="$PROXY_ARGS -Dhttp.proxyPort=${port}"
        fi
    fi

    if [ -n "$https_proxy" ]; then
        local host=$(echo $https_proxy | sed 's!.*//!!' | cut -f1 -d:)
        local port=$(echo $https_proxy | sed 's!.*//!!' | cut -f2 -d:)

        PROXY_ARGS="$PROXY_ARGS -Dhttps.proxyHost=${host}"
        if [ "$host" != "$port" ]; then
            PROXY_ARGS="$PROXY_ARGS -Dhttps.proxyPort=${port}"
        fi
    fi
}

json_escape()
{
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

artifact_base_url()
{
	local base="${RC16_ARTIFACT_BASE_URL:-${PASTURESTACK_RELEASE_BASE_URL:-}}"
    echo "${base%/}"
}

setup_catalog_overrides()
{
    if [ -n "$RC16_CATALOG_URL" ]; then
        export DEFAULT_CATTLE_CATALOG_URL="$RC16_CATALOG_URL"
        export CATTLE_CATALOG_URL="${CATTLE_CATALOG_URL:-$RC16_CATALOG_URL}"
    fi

    if [ -n "$RC16_LIBRARY_CATALOG_URL" ] || [ -n "$RC16_LIBRARY_CATALOG_BRANCH" ] || \
       [ -n "$RC16_COMMUNITY_CATALOG_URL" ] || [ -n "$RC16_COMMUNITY_CATALOG_BRANCH" ] || \
       [ -n "$RC16_DISABLE_COMMUNITY_CATALOG" ]; then
        local default_library_branch=$(echo "${CATTLE_RANCHER_SERVER_VERSION:-v1.6.30}" | sed -E 's/(v[0-9]+\.[0-9]+).*/\1-release/')
        local library_url="${RC16_LIBRARY_CATALOG_URL:-${RC16_DEFAULT_LIBRARY_CATALOG_URL:-}}"
        local library_branch=$(json_escape "${RC16_LIBRARY_CATALOG_BRANCH:-$default_library_branch}")
        local catalog_json='{"catalogs":{'
        local sep=""

        if [ "$RC16_DISABLE_COMMUNITY_CATALOG" != "true" ] && [ -n "$RC16_COMMUNITY_CATALOG_URL" ]; then
            local community_url=$(json_escape "$RC16_COMMUNITY_CATALOG_URL")
            local community_branch=$(json_escape "${RC16_COMMUNITY_CATALOG_BRANCH:-master}")
            catalog_json="${catalog_json}${sep}\"community\":{\"url\":\"${community_url}\",\"branch\":\"${community_branch}\"}"
            sep=","
        fi

        if [ -n "$library_url" ]; then
            library_url=$(json_escape "$library_url")
            catalog_json="${catalog_json}${sep}\"library\":{\"url\":\"${library_url}\",\"branch\":\"${library_branch}\"}"
        fi

        catalog_json="${catalog_json}}}"
        export DEFAULT_CATTLE_CATALOG_URL="$catalog_json"
        export CATTLE_CATALOG_URL="${CATTLE_CATALOG_URL:-$catalog_json}"
    fi

    if [ -n "$RC16_SERVICE_PACKAGE_CATALOG_URL" ]; then
        export DEFAULT_CATTLE_SERVICE_PACKAGE_CATALOG_URL="$RC16_SERVICE_PACKAGE_CATALOG_URL"
        export CATTLE_SERVICE_PACKAGE_CATALOG_URL="${CATTLE_SERVICE_PACKAGE_CATALOG_URL:-$RC16_SERVICE_PACKAGE_CATALOG_URL}"
    fi
}

setup_system_image_overrides()
{
    if [ -n "$RC16_AGENT_IMAGE" ]; then
        export DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE="$RC16_AGENT_IMAGE"
        export CATTLE_BOOTSTRAP_REQUIRED_IMAGE="${CATTLE_BOOTSTRAP_REQUIRED_IMAGE:-$RC16_AGENT_IMAGE}"
    fi

    local lb_image_uuid="$RC16_LB_INSTANCE_IMAGE_UUID"

    if [ -n "$RC16_LB_INSTANCE_IMAGE" ]; then
        export DEFAULT_CATTLE_LB_INSTANCE_IMAGE="$RC16_LB_INSTANCE_IMAGE"
        export CATTLE_LB_INSTANCE_IMAGE="${CATTLE_LB_INSTANCE_IMAGE:-$RC16_LB_INSTANCE_IMAGE}"

        if [ -z "$lb_image_uuid" ]; then
            lb_image_uuid="docker:$RC16_LB_INSTANCE_IMAGE"
        fi
    fi

    if [ -n "$lb_image_uuid" ]; then
        export DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID="$lb_image_uuid"
        export CATTLE_LB_INSTANCE_IMAGE_UUID="${CATTLE_LB_INSTANCE_IMAGE_UUID:-$lb_image_uuid}"
    fi
}

setup_agent_artifact_overrides()
{
    local artifact_base="${RC16_ARTIFACT_BASE_URL%/}"
    local agent_package_url="${RC16_AGENT_PACKAGE_URL:-$RC16_GO_AGENT_URL}"
    local host_api_url="$RC16_HOST_API_URL"
    local go_agent_version="${RC16_GO_AGENT_VERSION:-0.13.21}"
    local host_api_version="${RC16_HOST_API_VERSION:-0.38.4}"

    if [ -z "$agent_package_url" ] && [ -n "$artifact_base" ]; then
        agent_package_url="${artifact_base}/node-agent-${go_agent_version}.tar.gz"
    fi

    if [ -n "$agent_package_url" ]; then
        export DEFAULT_CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL="$agent_package_url"
        export CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL="${CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL:-$agent_package_url}"
    fi

    if [ -z "$host_api_url" ] && [ -n "$artifact_base" ]; then
        host_api_url="${artifact_base}/host-api-${host_api_version}.tar.gz"
    fi

    if [ -n "$host_api_url" ]; then
        export DEFAULT_CATTLE_AGENT_PACKAGE_HOST_API_URL="$host_api_url"
        export CATTLE_AGENT_PACKAGE_HOST_API_URL="${CATTLE_AGENT_PACKAGE_HOST_API_URL:-$host_api_url}"
    fi
}

setup_cli_artifact_overrides()
{
    local artifact_base="${RC16_ARTIFACT_BASE_URL%/}"
    if [ -z "$artifact_base" ]; then
        return 0
    fi

    local compose_version="${CATTLE_RANCHER_COMPOSE_VERSION:-v0.14.30}"
    local cli_version="${CATTLE_RANCHER_CLI_VERSION:-v0.6.14}"
    local compose_asset_version="${compose_version#v}"
    local cli_asset_version="${cli_version#v}"

    export CATTLE_RANCHER_COMPOSE_VERSION="$compose_version"
    export DEFAULT_CATTLE_RANCHER_COMPOSE_LINUX_URL="${DEFAULT_CATTLE_RANCHER_COMPOSE_LINUX_URL:-${artifact_base}/compose-cli-${compose_asset_version}-linux-amd64.tar.gz}"
    export DEFAULT_CATTLE_RANCHER_COMPOSE_DARWIN_URL="${DEFAULT_CATTLE_RANCHER_COMPOSE_DARWIN_URL:-${artifact_base}/compose-cli-${compose_asset_version}-darwin-amd64.tar.gz}"
    export DEFAULT_CATTLE_RANCHER_COMPOSE_WINDOWS_URL="${DEFAULT_CATTLE_RANCHER_COMPOSE_WINDOWS_URL:-${artifact_base}/compose-cli-${compose_asset_version}-windows-amd64.zip}"

    export CATTLE_RANCHER_CLI_VERSION="$cli_version"
    export DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL="${DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL:-${artifact_base}/pasturestack-cli-${cli_asset_version}-linux-amd64.tar.gz}"
    export DEFAULT_CATTLE_RANCHER_CLI_DARWIN_URL="${DEFAULT_CATTLE_RANCHER_CLI_DARWIN_URL:-${artifact_base}/pasturestack-cli-${cli_asset_version}-darwin-amd64.tar.gz}"
    export DEFAULT_CATTLE_RANCHER_CLI_WINDOWS_URL="${DEFAULT_CATTLE_RANCHER_CLI_WINDOWS_URL:-${artifact_base}/pasturestack-cli-${cli_asset_version}-windows-amd64.zip}"
}

setup_default_service_flags()
{
    export DEFAULT_CATTLE_AUTH_SERVICE_EXECUTE=${DEFAULT_CATTLE_AUTH_SERVICE_EXECUTE:-true}
}

setup_jdk_http_client()
{
    local opts="${JAVA_OPTS:-} ${CATTLE_JAVA_OPTS:-}"
    if [[ "$opts" != *"jdk.httpclient.allowRestrictedHeaders"* ]]; then
        export JAVA_OPTS="${JAVA_OPTS:-} -Djdk.httpclient.allowRestrictedHeaders=host"
    fi
}

prepare_cattle_runtime_user()
{
    if [ "$(id -u)" != "0" ]; then
        return 0
    fi

    local uid="${RC16_CATTLE_UID:-10001}"
    local gid="${RC16_CATTLE_GID:-10001}"
    mkdir -p "${CATTLE_HOME}" "${LOG_DIR}"

    if [ "${RC16_CHOWN_CATTLE_HOME_ON_START:-true}" = "true" ]; then
        chown -Rh "${uid}:${gid}" "${CATTLE_HOME}"
    fi
}

exec_cattle_java()
{
    if [ "$(id -u)" = "0" ] && [ "${RC16_CATTLE_JAVA_RUN_AS_ROOT:-false}" != "true" ]; then
        local uid="${RC16_CATTLE_UID:-10001}"
        local gid="${RC16_CATTLE_GID:-10001}"
        exec setpriv --reuid="${uid}" --regid="${gid}" --init-groups "$@"
    fi

    exec "$@"
}

java_major_version()
{
    java -version 2>&1 | awk -F'[\".]' '/version/ { print ($2 == "1" ? $3 : $2); exit }'
}

default_cattle_java_opts()
{
    local mx="$1"
    local major="$(java_major_version)"
    local common="-Xms128m -Xmx${mx} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOG_DIR}"

    if [ -n "$major" ] && [ "$major" -ge 9 ] 2>/dev/null; then
        echo "-XX:+UseG1GC ${common} --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
    else
        echo "-XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled ${common}"
    fi
}

run() {
    setup_local_agents
    setup_graphite
    setup_prometheus
    setup_gelf
    setup_mysql
    setup_redis
    setup_zk
    setup_proxy
    setup_catalog_overrides
    setup_system_image_overrides
    setup_agent_artifact_overrides
    setup_cli_artifact_overrides
    setup_default_service_flags
    setup_jdk_http_client
    prepare_cattle_runtime_user

    env | grep CATTLE | grep -v PASS | sort

    local ram=$(free -g --si | awk '/^Mem:/{print $2}')
    if [ ${ram} -gt 6 ]; then
        MX="4g"
    elif [ ${ram} -gt 2 ]; then
        MX="2g"
    else
        MX="1g"
    fi

    local default_java_opts="$(default_cattle_java_opts "$MX")"

    HASH_PATH=$(dirname "$JAR")/$HASH
    if [ -e $HASH_PATH ]; then
        if [ -e $HASH_PATH/index.html ]; then
            export DEFAULT_CATTLE_API_UI_INDEX=local
        fi
        exec_cattle_java java ${CATTLE_JAVA_OPTS:-$default_java_opts} -Dlogback.bootstrap.level=WARN $PROXY_ARGS $JAVA_OPTS -cp ${HASH_PATH}:${HASH_PATH}/etc/cattle io.cattle.platform.launcher.Main "$@" $ARGS
    else
        unset DEFAULT_CATTLE_API_UI_JS_URL
        unset DEFAULT_CATTLE_API_UI_CSS_URL
        exec_cattle_java java ${CATTLE_JAVA_OPTS:-$default_java_opts} $PROXY_ARGS $JAVA_OPTS -jar $JAR "$@" $ARGS
    fi
}

extract()
{
    cd $(dirname $JAR)
    rm -rf $HASH war
    mkdir $HASH
    ln -s $HASH war
    cd war
    unzip -q $JAR
    if [ -f resources.jar ]; then
        unzip -oq resources.jar
        rm -f resources.jar
    fi
    test -d WEB-INF/lib
    test -f io/cattle/platform/launcher/Main.class
}

master()
{
    local artifact_base="$(artifact_base_url)"
    if [ -z "$artifact_base" ]; then
        echo "RC16_ARTIFACT_BASE_URL is required when CATTLE_MASTER=true" >&2
        exit 1
    fi

    unset CATTLE_API_UI_URL
    unset CATTLE_CATTLE_VERSION
    unset CATTLE_RANCHER_SERVER_VERSION
    unset CATTLE_RANCHER_SERVER_VERSION
    unset CATTLE_USE_LOCAL_ARTIFACTS
    unset DEFAULT_CATTLE_API_UI_CSS_URL
    unset DEFAULT_CATTLE_API_UI_INDEX
    unset DEFAULT_CATTLE_API_UI_JS_URL

    export HASH=none
    export CATTLE_IDEMPOTENT_CHECKS=false
    export CATTLE_RANCHER_COMPOSE_VERSION ${CATTLE_RANCHER_COMPOSE_VERSION:-v0.14.30}
    export DEFAULT_CATTLE_RANCHER_COMPOSE_LINUX_URL=${artifact_base}/compose-cli-${CATTLE_RANCHER_COMPOSE_VERSION#v}-linux-amd64.tar.gz
    export DEFAULT_CATTLE_RANCHER_COMPOSE_DARWIN_URL=${artifact_base}/compose-cli-${CATTLE_RANCHER_COMPOSE_VERSION#v}-darwin-amd64.tar.gz
    export DEFAULT_CATTLE_RANCHER_COMPOSE_WINDOWS_URL=${artifact_base}/compose-cli-${CATTLE_RANCHER_COMPOSE_VERSION#v}-windows-amd64.zip
    export CATTLE_RANCHER_CLI_VERSION ${CATTLE_RANCHER_CLI_VERSION:-v0.6.14}
    export DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL=${artifact_base}/pasturestack-cli-${CATTLE_RANCHER_CLI_VERSION#v}-linux-amd64.tar.gz
    export DEFAULT_CATTLE_RANCHER_CLI_DARWIN_URL=${artifact_base}/pasturestack-cli-${CATTLE_RANCHER_CLI_VERSION#v}-darwin-amd64.tar.gz
    export DEFAULT_CATTLE_RANCHER_CLI_WINDOWS_URL=${artifact_base}/pasturestack-cli-${CATTLE_RANCHER_CLI_VERSION#v}-windows-amd64.zip

    mkdir -p /source
    cd /source
    get_source

    cd cattle
    cattle-binary-pull ./resources/content/cattle-global.properties /usr/bin >/tmp/download.log 2>&1 &
    cd ..

    build_source

    cd cattle
    ./mvnw package
    wait || {
        cat /tmp/download.log
        exit 1
    }
    JAR=$(readlink -f code/packaging/app/target/cattle-app-*.war)
    run
}

get_source()
{
    if [[ ! -e cattle || -e .cattle.default ]] && ! echo "$REPOS" | grep -q cattle; then
        REPOS="$REPOS cattle"
        touch .cattle.default
    fi
    for r in $REPOS; do
        d=""
        if ! [[ $r =~ ^http || $r =~ ^git ]]; then
            case "$r" in
                cattle)
                    r="https://github.com/PastureStack/orchestration-engine.git"
                    d="cattle"
                    ;;
                node-agent)
                    r="https://github.com/PastureStack/node-agent.git"
                    d="node-agent"
                    ;;
                host-api)
                    r="https://github.com/PastureStack/host-api.git"
                    d="host-api"
                    ;;
                compose-cli)
                    r="https://github.com/PastureStack/compose-cli.git"
                    d="compose-cli"
                    ;;
                mount-propagation)
                    r="https://github.com/PastureStack/mount-propagation.git"
                    d="mount-propagation"
                    ;;
                catalog-service)
                    r="https://github.com/PastureStack/catalog-service.git"
                    d="catalog-service"
                    ;;
                authentication-service)
                    r="https://github.com/PastureStack/authentication-service.git"
                    d="authentication-service"
                    ;;
                host-provisioner)
                    r="https://github.com/PastureStack/host-provisioner.git"
                    d="host-provisioner"
                    ;;
                *)
                    echo "Unknown repository shorthand: $r. Use a full Git URL or a documented PastureStack shorthand." >&2
                    return 1
                    ;;
            esac
        fi
        tag=$(echo $r | cut -f2 -d,)
        r=$(echo $r | cut -f1 -d,)
        if [ -z "$d" ]; then
            d=$(echo $r | awk -F/ '{print $NF}' | cut -f1 -d.)
        fi
        if [[ -z "$tag" || "$tag" = "$r" ]]; then
            tag=origin/master
        fi
        if [ -e $d ]; then
            git -C $d fetch origin
            git -C $d reset --hard $tag
        else
            git clone $r $d
            git -C $d checkout --detach $tag
        fi
    done
}

build_source()
{
    for i in *; do
        if [[ ! -d $i || $i == cattle ]]; then
            continue
        fi

        if [ ! -x "$(which make)" ]; then
            apt-get update
            apt-get install -y make
        fi

        if [ ! -x "$(which docker)" ]; then
            local docker_tgz=/tmp/rc16-docker-29.4.0.tgz
            rm -f "$docker_tgz"
            curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
                -o "$docker_tgz" https://download.docker.com/linux/static/stable/x86_64/docker-29.4.0.tgz
            tar xzf "$docker_tgz" -C /usr/bin --strip-components=1 docker/docker
            rm -f "$docker_tgz"
            chmod +x /usr/bin/docker
        fi

        cd $i
        make build 2>&1 | while IFS= read -r line; do
            printf '%s | %s\n' "$i" "$line"
        done
        ln -sf $(pwd)/bin/* /usr/local/bin/
        if [ "$i" = "node-agent" ]; then
            export CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL=$(pwd)
        fi
        cd ..
    done
}

update-platform-ssl

if [ "$1" = "extract" ]; then
    extract
elif [ "$CATTLE_MASTER" = true ]; then
    master
else
    run
fi
