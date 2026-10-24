# syntax=docker/dockerfile:1.7
# Disposable prepublication consumer acceptance; never used as a product image.
FROM golang:1.27.3-bookworm@sha256:972b4110ba0f47539a975c31e52c64765e1ff19f2d74469ae4a595c6676e80a5 AS embedding_probe
# The public API headers come from the same immutable official release as the
# qualified package. The probe dynamically loads libjq in the Ubuntu consumer;
# neither libjq nor libm is linked into the executable at build time.
ADD --checksum=sha256:71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz /tmp/jq.tar.gz
COPY testdata/consumer-libjq-probe.c /src/consumer-libjq-probe.c
RUN set -eux; \
    mkdir /tmp/headers; \
    tar --extract --gzip --file /tmp/jq.tar.gz --directory /tmp/headers --strip-components=2 jq-1.8.2/src/jq.h jq-1.8.2/src/jv.h; \
    cc -std=gnu11 -Wall -Wextra -Werror -O2 -pthread -isystem /tmp/headers \
      /src/consumer-libjq-probe.c -ldl -o /consumer-libjq-probe; \
    readelf --dynamic /consumer-libjq-probe >/tmp/probe-dynamic.txt; \
    if grep -E 'NEEDED.*\[(libjq|libm)\.' /tmp/probe-dynamic.txt; then exit 1; fi

FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS consumer
ARG PROVIDER=gnu
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
ADD --checksum=sha256:5b6326f1932cfd7be57130561dc78192f09ed9f58bfbe6606ed0c50510c3b6cd https://archive.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260816ubuntu0.26.04.1_all.deb /tmp/ca-certificates.deb
RUN <<'SH'
set -euo pipefail
case "$PROVIDER" in gnu|uutils) ;; *) exit 2 ;; esac
mkdir -p /tmp/ca-bootstrap /etc/ssl/certs
dpkg-deb --extract /tmp/ca-certificates.deb /tmp/ca-bootstrap
while IFS= read -r certificate; do
    cat "$certificate"
    printf '\n'
done < <(find /tmp/ca-bootstrap/usr/share/ca-certificates -type f -name '*.crt' | LC_ALL=C sort) >/etc/ssl/certs/ca-certificates.crt
rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources
cat >/etc/apt/sources.list.d/pasturestack-snapshot.sources <<'SOURCES'
Types: deb
URIs: https://snapshot.ubuntu.com/ubuntu/20261023T000000Z
Suites: resolute resolute-updates resolute-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
Snapshot: no
Check-Valid-Until: no
SOURCES
cat >/etc/apt/apt.conf.d/80pasturestack <<'APT'
Acquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";
Acquire::https::Verify-Peer "true";
Acquire::https::Verify-Host "true";
Acquire::Retries "3";
APT
# Exercise an ordinary minimal-image doc filter, without suppressing runtime
# files. The installer must enumerate missing docs and restore exact paths.
printf 'path-exclude=/usr/share/doc/*\n' >/etc/dpkg/dpkg.cfg.d/01fixture-doc-exclusions
apt-get update
# Construct the explicitly selected GNU fixture using Ubuntu's documented
# provider transition. This is baseline setup, before the backport installer;
# the installer itself must preserve whichever provider was selected here.
# https://ubuntu.com/server/docs/reference/other-tools/sudo-rs/
if [[ "$PROVIDER" == gnu ]]; then
    apt-get install -y --no-install-recommends --allow-remove-essential \
        coreutils-from-gnu=0.0.0~ubuntu25 coreutils-from-uutils- rust-coreutils-
fi
set -- \
    libpcre2-8-0=10.46-1build1 libpcre2-posix3=10.46-1build1 \
    libc6=2.43-2ubuntu2.4 libc-bin=2.43-2ubuntu2.4 libc-gconv-modules-extra=2.43-2ubuntu2.4 \
    jq=1.8.1-4ubuntu2 libjq1=1.8.1-4ubuntu2 \
    p11-kit=0.26.2-2 p11-kit-modules=0.26.2-2 libp11-kit0=0.26.2-2 \
    'libxrender1=1:0.9.12-1build1' gnu-coreutils=9.7-3ubuntu2.1 ca-certificates grep
case "$PROVIDER" in
    gnu) set -- "$@" 'coreutils-from-gnu=0.0.0~ubuntu25' ;;
    uutils) set -- "$@" 'coreutils-from-uutils=0.0.0~ubuntu25' 'rust-coreutils=0.10.0-1ubuntu2~26.04.1' ;;
esac
# All baseline runtime versions are explicit; no dependency force is used.
apt-get install --no-install-recommends --reinstall -y "$@"
rm -rf /var/lib/apt/lists/* /tmp/ca-bootstrap /tmp/ca-certificates.deb
SH
COPY consumer-smoke.sh /consumer-smoke.sh
COPY --from=embedding_probe /consumer-libjq-probe /consumer-libjq-probe
RUN --mount=from=qualified,source=/out,target=/opt/pasturestack/ubuntu-security-backports,ro \
    /bin/bash /consumer-smoke.sh "$PROVIDER"

FROM scratch AS evidence
COPY --from=consumer /evidence/ /
