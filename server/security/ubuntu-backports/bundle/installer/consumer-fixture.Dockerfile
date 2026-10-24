# syntax=docker/dockerfile:1.7
# Disposable prepublication consumer acceptance; never used as a product image.
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
set -- \
    libpcre2-8-0=10.46-1build1 libpcre2-posix3=10.46-1build1 \
    libc6=2.43-2ubuntu2.4 libc-bin=2.43-2ubuntu2.4 libc-gconv-modules-extra=2.43-2ubuntu2.4 \
    jq=1.8.1-4ubuntu2 libjq1=1.8.1-4ubuntu2 \
    p11-kit=0.26.2-2 p11-kit-modules=0.26.2-2 libp11-kit0=0.26.2-2 \
    'libxrender1=1:0.9.12-1build1' gnu-coreutils=9.7-3ubuntu2 ca-certificates grep
case "$PROVIDER" in
    gnu) set -- "$@" 'coreutils-from-gnu=0.0.0~ubuntu25' ;;
    uutils) set -- "$@" 'coreutils-from-uutils=0.0.0~ubuntu25' 'rust-coreutils=0.10.0-1ubuntu2~26.04.1' ;;
esac
# Baseline construction uses the official provider transition without force or
# protected-package overrides. A refused transition fails the fixture.
apt-get install --no-install-recommends --reinstall -y "$@"
if [[ "$PROVIDER" == gnu ]]; then
    apt-get remove -y rust-coreutils
fi
rm -rf /var/lib/apt/lists/* /tmp/ca-bootstrap /tmp/ca-certificates.deb
SH
COPY consumer-smoke.sh /consumer-smoke.sh
RUN --mount=from=qualified,source=/out,target=/opt/pasturestack/ubuntu-security-backports,ro \
    /bin/bash /consumer-smoke.sh "$PROVIDER"

FROM scratch AS evidence
COPY --from=consumer /evidence/ /
