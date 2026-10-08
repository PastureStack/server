#!/usr/bin/env bash
set -euo pipefail

[[ $# == 5 ]] || { echo 'usage: fetch-server-component MODE URL NAME SHA256 OUTPUT' >&2; exit 2; }
mode=$1 url=$2 name=$3 expected=$4 output=$5
[[ "$name" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$expected" =~ ^[0-9a-f]{64}$ ]]
case "$mode" in
    local)
        input="/tmp/pasturestack-component-input/$name"
        test -f "$input" && test ! -L "$input"
        cp -- "$input" "$output"
        ;;
    remote)
        case "$url" in
            https://*) ;;
            http://127.0.0.1:*|http://localhost:*) [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]] ;;
            *) echo 'Component source must use HTTPS' >&2; exit 1 ;;
        esac
        curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
            --connect-timeout 10 --max-time 300 -o "$output" "$url"
        ;;
    *) echo 'Unknown component artifact mode' >&2; exit 2 ;;
esac
printf '%s  %s\n' "$expected" "$output" | sha256sum -c -
