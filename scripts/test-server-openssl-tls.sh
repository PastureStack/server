#!/usr/bin/env bash
set -Eeuo pipefail

# Runs only inside an isolated image check container, without published ports.
work=$(mktemp -d /tmp/pasturestack-openssl-tls.XXXXXX)
server_pid=
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -subj /CN=localhost -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1' \
  -keyout "$work/key.pem" -out "$work/cert.pem" >/dev/null 2>&1
openssl s_server -accept 127.0.0.1:19443 -www \
  -key "$work/key.pem" -cert "$work/cert.pem" \
  >"$work/server.log" 2>&1 &
server_pid=$!
for version in 1.2 1.3; do
  status=$(curl --silent --show-error --fail --max-time 10 \
    --retry 5 --retry-connrefused --retry-delay 1 --retry-max-time 15 \
    --cacert "$work/cert.pem" --tlsv${version} --tls-max "$version" \
    --output "$work/response" --write-out '%{http_code}' \
    https://localhost:19443/)
  test "$status" = 200
  grep -F "Protocol  : TLSv${version}" "$work/response" >/dev/null
done
# The same endpoint must still reject an untrusted certificate.
set +e
curl --silent --show-error --max-time 5 --output /dev/null \
  https://localhost:19443/ >"$work/untrusted.log" 2>&1
status=$?
set -e
test "$status" -eq 60
printf 'SERVER_OPENSSL_TLS_OK tls12=200 tls13=200 untrusted_certificate=rejected\n'
