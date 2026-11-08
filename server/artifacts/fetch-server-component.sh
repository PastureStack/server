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
        proto='=https'
        case "$url" in
            https://*) ;;
            http://127.0.0.1:*|http://localhost:*) [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]]; proto='=http,https' ;;
            *) echo 'Component source must use HTTPS' >&2; exit 1 ;;
        esac
        headers=$(mktemp "${output}.headers.XXXXXX")
        trap 'rm -f -- "$headers"' EXIT
        curl --disable -fsSL --retry 5 --retry-all-errors --retry-delay 2 \
            --proto "$proto" --proto-redir "$proto" \
            --header 'Accept: application/octet-stream' --header 'Range: bytes=0-' \
            --max-filesize 1073741824 --dump-header "$headers" \
            --connect-timeout 10 --max-time 300 "$url" | head -c 1073741825 > "$output"
        test "$(wc -c < "$headers")" -le 65536
        bytes=$(wc -c < "$output")
        test "$bytes" -le 1073741824
        # curl follows redirects; validate only the last response header block.
        # A206 must cover byte0 through the end, never an arbitrary partial.
        awk -v actual="$bytes" '
            { gsub(/\r/, "") }
            /^HTTP\// { code=$2; span=""; content_length="" }
            tolower($0) ~ /^content-range:/ { span=$0; sub(/^[^:]+:[ \t]*/, "", span) }
            tolower($0) ~ /^content-length:/ { content_length=$0; sub(/^[^:]+:[ \t]*/, "", content_length) }
            END {
                if (code != 200 && code != 206) exit 1
                if (content_length != "" && (content_length !~ /^[0-9]+$/ || content_length != actual)) exit 1
                if (code == 206) {
                    if (span !~ /^bytes 0-[0-9]+\/[0-9]+$/) exit 1
                    split(substr(span, 7), parts, "/"); split(parts[1], bounds, "-")
                    if (bounds[2]+1 != parts[2] || parts[2] != actual) exit 1
                }
            }
        ' "$headers" || { echo 'Component response must contain the complete asset' >&2; exit 1; }
        ;;
    *) echo 'Unknown component artifact mode' >&2; exit 2 ;;
esac
printf '%s  %s\n' "$expected" "$output" | sha256sum -c -
