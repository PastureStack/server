#!/usr/bin/env bash
set -euo pipefail

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Refusing to build a release image from an uncommitted worktree" >&2
    exit 1
fi

revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid PastureStack Server revision: ${revision}" >&2
    exit 1
fi

web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.13}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.13.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}
image=${IMAGE:-pasturestack-validation/server:v1.6.301}

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.console-workspace-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.301
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.297
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.digest"}}')" = \
    sha256:e36c3af6924c879b2ce3744adc39b2b2e8d59bbb6379515252b6df1e8eb8f7a1

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.301 \
    CATTLE_HTTP_PORT=8080 \
    PASTURESTACK_CONSOLE_LISTEN_ADDRESS=:8080 \
    PASTURESTACK_CONSOLE_UPSTREAM_URL=http://127.0.0.1:8083 \
    PASTURESTACK_CONSOLE_PROXY_LISTEN_ADDRESS=:8083 \
    PASTURESTACK_CONSOLE_APPLICATION_ADDRESS=127.0.0.1:8081 \
    PASTURESTACK_CONSOLE_SESSION_DIAL_URL=http://127.0.0.1:8080 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.13 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}"; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    test -x /usr/bin/pasturestack-console-broker
    test -x /usr/bin/websocket-proxy
    test -x /service/console-broker/run
    test -x /service/console-broker/finish
    grep -F "/usr/bin/pasturestack-console-broker" /usr/bin/websocket-proxy >/dev/null
    test -f /usr/share/licenses/pasturestack-console-broker/gorilla-websocket-LICENSE
    test -f /usr/share/licenses/pasturestack-console-broker/THIRD-PARTY-NOTICES.md
    grep -F "\"childSidekicks\":\"相關容器\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
'

printf 'SERVER_CONSOLE_WORKSPACE_PATCH_IMAGE_OK image=%s revision=%s web_console_commit=%s\n' \
    "$image" "$revision" "$web_console_commit"
