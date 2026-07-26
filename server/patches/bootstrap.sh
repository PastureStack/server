#!/bin/bash
set -e

trap cleanup EXIT SIGINT SIGTERM

# This is copied from common/scripts.sh, if there is a change here
# make it in common and then copy here
check_debug()
{
    if [ -n "$CATTLE_SCRIPT_DEBUG" ] || echo "${@}" | grep -q -- --debug; then
        export CATTLE_SCRIPT_DEBUG=true
        export PS4='[${BASH_SOURCE##*/}:${LINENO}] '
        set -x
    fi
}

info()
{
    echo "INFO:" "${@}"
}

error()
{
    echo "ERROR:" "${@}" 1>&2
}

apply_read_env_line()
{
    local line="$1"
    local key
    local value

    if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        return 0
    fi

    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        key="${BASH_REMATCH[2]}"
        value="${BASH_REMATCH[3]}"
    else
        error "Unsupported --read-env assignment: ${line}"
        exit 1
    fi

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
        value="${value#\"}"
        value="${value%\"}"
        value="${value//\\\"/\"}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
        value="${value#\'}"
        value="${value%\'}"
    fi

    export "$key=$value"
}

export CATTLE_HOME=${CATTLE_HOME:-/var/lib/cattle}
export PASTURESTACK_AGENT_CONTAINER_NAME=${PASTURESTACK_AGENT_CONTAINER_NAME:-pasturestack-node-agent}
export PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME=${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME:-pasturestack-node-agent-upgrade}
LEGACY_AGENT_CONTAINER_NAME=${LEGACY_AGENT_CONTAINER_NAME:-rancher-agent}
LEGACY_AGENT_UPGRADE_CONTAINER_NAME=${LEGACY_AGENT_UPGRADE_CONTAINER_NAME:-rancher-agent-upgrade}

check_debug
# End copy

CONF=(/etc/cattle/agent/bootstrap.conf
      ${CATTLE_HOME}/etc/cattle/agent/bootstrap.conf
      /var/lib/rancher/etc/agent.conf)
CONTENT_URL=/configcontent/configscripts
INSTALL_ITEMS="configscripts pyagent"
REQUIRED_IMAGE=
DETECTED_CATTLE_AGENT_IP=

export CATTLE_AGENT_IP=${CATTLE_AGENT_IP:-${DETECTED_CATTLE_AGENT_IP}}

cleanup()
{
    local exit=$?

    if [ -n "${TEMP_DOWNLOAD:-}" ] && [ -e "$TEMP_DOWNLOAD" ]; then
        rm -rf "$TEMP_DOWNLOAD"
    fi

    if [ -e "$0" ] && echo "$0" | grep -q ^/tmp
    then
        rm "$0" 2>/dev/null || true
    fi

    return $exit
}

ca_cert()
{
    mkdir -p /usr/share/ca-certificates/rancher
    cat > /usr/share/ca-certificates/rancher/agent-ca.crt << EOF
%CERT%
EOF
    if ! grep -q rancher/agent-ca.crt /etc/ca-certificates.conf; then
        echo rancher/agent-ca.crt >> /etc/ca-certificates.conf
    fi

    update-ca-certificates
}

download_agent()
{
    cleanup

    TEMP_DOWNLOAD=$(mktemp -d bootstrap.XXXXXXX)
    local content="$TEMP_DOWNLOAD/content"
    local url="${CATTLE_CONFIG_URL}${CONTENT_URL}"
    local retry_all_errors=()
    if curl --retry-all-errors --version >/dev/null 2>&1; then
        retry_all_errors=(--retry-all-errors)
    fi

    info Downloading agent "$url"
    curl -fsS --retry 5 "${retry_all_errors[@]}" --retry-delay 2 \
        --connect-timeout "${RC16_BOOTSTRAP_CONNECT_TIMEOUT:-10}" \
        --max-time "${RC16_BOOTSTRAP_MAX_TIME:-300}" \
        -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
        -o "$content" "$url"
    tar xzf "$content" -C "$TEMP_DOWNLOAD" || ( cat "$content" 1>&2 && exit 1 )
    bash "$TEMP_DOWNLOAD"/*/config.sh --force $INSTALL_ITEMS
}

start_agent()
{
    local platform_home="${PASTURESTACK_HOME:-${CATTLE_HOME}}"
    local main="${platform_home}/node-agent/apply.sh"
    if [ ! -x "$main" ]; then
        main="${CATTLE_HOME}/pyagent/apply.sh"
    fi
    if [ ! -x "$main" ]; then
        error "No installed node-agent entrypoint was found"
        exit 1
    fi
    export AGENT_PARENT_PID=$PPID
    info Starting agent $main
    exec "$main" start
}

print_config()
{
    info Access Key: $CATTLE_ACCESS_KEY
    info Config URL: $CATTLE_CONFIG_URL
    info Storage URL: $CATTLE_STORAGE_URL
    info API URL: $CATTLE_URL
    info IP: $CATTLE_AGENT_IP
    info Port: $CATTLE_AGENT_PORT
    info Required Image: ${REQUIRED_IMAGE}
    info Current Image: ${RANCHER_AGENT_IMAGE}
}

upgrade()
{
    if [[ -n "${REQUIRED_IMAGE}" && "${RANCHER_AGENT_IMAGE}" != "${REQUIRED_IMAGE}" ]]; then
        case "${RANCHER_AGENT_IMAGE}" in
        rancher/agent:*|docker.io/rancher/agent:*)
            info Preserving legacy node-agent image ${RANCHER_AGENT_IMAGE}
            info Required image is ${REQUIRED_IMAGE}
            info Legacy agents require cgroup v1 hosts. Register modern cgroup v2 hosts with the maintained rc16 agent image.
            return 0
            ;;
        esac

        if [ -e /host/var/run/docker.sock ]; then
            # Upgrading from old image
            export DOCKER_HOST="unix:///host/var/run/docker.sock"
        fi

        info Upgrading to image ${REQUIRED_IMAGE}

        for upgrade_container in "${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME}" "${LEGACY_AGENT_UPGRADE_CONTAINER_NAME}"; do
            while docker inspect "${upgrade_container}" >/dev/null 2>&1; do
                docker rm -f "${upgrade_container}"
                sleep 1
            done
        done

        timeout 300 docker run --privileged --name "${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME}" -v /var/run/docker.sock:/var/run/docker.sock "${REQUIRED_IMAGE}" upgrade
        exit 0
    elif [ -n "${REQUIRED_IMAGE}" ]; then
        info Using image ${REQUIRED_IMAGE}
    fi
}

get_running_image()
{
    if docker inspect "${PASTURESTACK_AGENT_CONTAINER_NAME}" >/dev/null 2>&1; then
        docker inspect -f '{{.Config.Image}}' "${PASTURESTACK_AGENT_CONTAINER_NAME}"
    else
        docker inspect -f '{{.Config.Image}}' "${LEGACY_AGENT_CONTAINER_NAME}"
    fi
}

cd $(dirname $0)

for conf_file in "${CONF[@]}"; do
    if [ -e $conf_file ]
    then
        source $conf_file
    fi
done

while [ $# != 0 ]; do
    case $1 in
    --port)
        shift 1
        if [ -z "$CATTLE_AGENT_PORT" ];then
            export CATTLE_AGENT_PORT=$1
        fi
        ;;
    --ip)
        shift 1
        if [ -z "$CATTLE_AGENT_IP" ];then
            export CATTLE_AGENT_IP=$1
        fi
        ;;
    --read-env)
        read LINE
        apply_read_env_line "$LINE"
        ;;
    esac

    shift 1
done

check_debug
export RANCHER_AGENT_IMAGE="$(get_running_image)"
print_config

upgrade

ca_cert
download_agent
start_agent
