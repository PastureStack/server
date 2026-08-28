#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

required_files=(
  server/Dockerfile.console-workspace-patch
  server/build-console-workspace-patch-image.sh
  server/console-broker/broker.go
  server/console-broker/broker_test.go
  server/console-broker/main.go
  server/console-broker/go.mod
  server/console-broker/go.sum
  server/console-broker/THIRD-PARTY-NOTICES.md
  server/console-broker/service/run
  server/console-broker/service/finish
  server/patches/websocket-proxy-wrapper.sh
)

for path in "${required_files[@]}"; do
  test -f "$path"
done

grep -F 'ARG GO_IMAGE=golang:1.27.0-bookworm@sha256:484ef6066fa69acb059fdfeda7ba2b8f7391f2ef6abc6f9b8411e669ebd56466' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.297' \
  server/Dockerfile.console-workspace-patch >/dev/null
test "$(grep -n '^ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.297$' \
  server/Dockerfile.console-workspace-patch | cut -d: -f1)" -lt \
  "$(grep -n '^FROM ' server/Dockerfile.console-workspace-patch | head -1 | cut -d: -f1)"
grep -F 'org.opencontainers.image.version="v1.6.304"' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'org.opencontainers.image.base.digest="sha256:e36c3af6924c879b2ce3744adc39b2b2e8d59bbb6379515252b6df1e8eb8f7a1"' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.304' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F '"pinnedCommit":"c3a8e9876a74dbf98ce16ae504b947c5d80582c1"' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.16' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_CONSOLE_LISTEN_ADDRESS=:8080' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_CONSOLE_UPSTREAM_URL=http://127.0.0.1:8083' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_CONSOLE_PROXY_LISTEN_ADDRESS=:8083' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'ENV PASTURESTACK_CONSOLE_APPLICATION_ADDRESS=127.0.0.1:8081' \
  server/Dockerfile.console-workspace-patch >/dev/null
if grep -F 'CATTLE_HTTP_PROXIED_PORT=' server/Dockerfile.console-workspace-patch; then
  echo 'The application port must remain on the established internal 8081 listener' >&2
  exit 1
fi
grep -F 'PASTURESTACK_CONSOLE_ACTIVE_TTL=72h' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'PASTURESTACK_CONSOLE_REPLAY_BYTES=2097152' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'pasturestack.consoleWorkspace.client.v1'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'client-probe'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'catalogDisplayName'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'pasturestack.consoleWorkspace.logs.wrap.v1'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'console-workspace-dock-scroll'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F "grep -F 'data-column-role-resolved'" \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'th:last-child[^{]*\.table-column-resize-handle' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F '\.dropdown-menu[^}]*overflow-x:' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F '\.table-column-scroll-host[^}]*overflow-x:' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'table-column-scroll-host-overflowing' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F '"wrapLines":"自動換行"' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F '"confirmTerminateTitle":"要結束工作階段嗎？"' \
  server/Dockerfile.console-workspace-patch >/dev/null
grep -F 'catalog_commit=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
  server/build-console-workspace-patch-image.sh >/dev/null
grep -F 'console_broker="${PASTURESTACK_CONSOLE_BROKER_BIN:-/usr/bin/pasturestack-console-broker}"' \
  server/patches/websocket-proxy-wrapper.sh >/dev/null
grep -F 'exec /usr/bin/s6-setuidgid cattle /usr/bin/pasturestack-console-broker' \
  server/console-broker/service/run >/dev/null
grep -F 'github.com/gorilla/websocket v1.5.3' \
  server/console-broker/go.mod >/dev/null
grep -E '^[[:space:]]*maxUpstreamFrame[[:space:]]*=[[:space:]]*4 \* 1024 \* 1024$' \
  server/console-broker/broker.go >/dev/null
grep -F 'X-PastureStack-Session-Secret' \
  server/console-broker/broker.go >/dev/null
grep -F 'map[string]string{"status": "missing"}' \
  server/console-broker/broker.go >/dev/null
grep -F 'TestMissingSessionStatusIsARecoverableState' \
  server/console-broker/broker_test.go >/dev/null
grep -F 'pasturestack-secret.' \
  server/console-broker/broker.go >/dev/null

if grep -E '\?secret=|clientId=' \
  server/console-broker/broker.go \
  server/console-broker/broker_test.go; then
  echo 'Console workspace credentials must not appear in WebSocket URLs' >&2
  exit 1
fi

if grep -RInE 'C:\\Users\\' \
  server/console-broker \
  server/Dockerfile.console-workspace-patch \
  server/build-console-workspace-patch-image.sh; then
  echo 'Console workspace source contains a private workstation path' >&2
  exit 1
fi

if grep -RInF '@sha256:' \
  server/console-broker \
  server/Dockerfile.console-workspace-patch \
  server/build-console-workspace-patch-image.sh \
  | grep -vF 'ARG GO_IMAGE=golang:1.27.0-bookworm@sha256:484ef6066fa69acb059fdfeda7ba2b8f7391f2ef6abc6f9b8411e669ebd56466'; then
  echo 'Console workspace source contains an unapproved image digest coordinate' >&2
  exit 1
fi

if [[ -n ${PASTURESTACK_PRIVATE_MARKER:-} ]] && grep -RInF -- "$PASTURESTACK_PRIVATE_MARKER" \
  server/console-broker \
  server/Dockerfile.console-workspace-patch \
  server/build-console-workspace-patch-image.sh; then
  echo 'Console workspace source contains a configured private marker' >&2
  exit 1
fi

printf 'SERVER_CONSOLE_WORKSPACE_PATCH_OK version=%s base=%s web_console=%s\n' \
  v1.6.304 v1.6.297 1.6.56-pasturestack.16
