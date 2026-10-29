#!/bin/sh
# One official Ubuntu package, after the immutable bundle has been verified.
set -eu
test "$#" -le 1
mode=${1:---verify}
case "$mode" in --install|--verify) ;; *) exit 2;; esac
version=1.2.0-3ubuntu0.1
archive_sha=bedeef1cf3268f90338c411cdb0a45b224d0660fd2240f310f380316c8244606
evidence=/usr/share/pasturestack/security/brotli-official
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
. /etc/os-release
test "$ID:$VERSION_ID" = ubuntu:26.04
test "$(dpkg --print-architecture)" = amd64
if test "$mode" = --install; then
    deb=/tmp/pasturestack-runtime-security/official-brotli/libbrotli1.deb
    test -f "$deb" && test ! -L "$deb"
    printf '%s  %s\n' "$archive_sha" "$deb" | sha256sum -c - >&2
    test "$(dpkg-deb -f "$deb" Package)" = libbrotli1
    test "$(dpkg-deb -f "$deb" Source)" = brotli
    test "$(dpkg-deb -f "$deb" Version)" = "$version"
    test "$(dpkg-deb -f "$deb" Architecture)" = amd64
    test "$(dpkg-deb -f "$deb" Depends)" = 'libc6 (>= 2.29)'
    before=$(dpkg-query -W -f='${Version}' libbrotli1)
    test "$before" = 1.2.0-3build1+pasturestack.1
    dpkg --compare-versions "$before" lt "$version"
    inventory() {
        dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Status}\n' |
            awk '$1 != "libbrotli1" && $1 != "libbrotli1:amd64"' | LC_ALL=C sort
    }
    configuration() {
        find /etc/dpkg -type f -print | LC_ALL=C sort | while IFS= read -r file; do sha256sum "$file"; done
    }
    inventory > "$tmp/before"
    configuration > "$tmp/config-before"
    # Exact package documentation only; do not change installed dpkg rules.
    DEBIAN_FRONTEND=noninteractive dpkg \
        --path-include=/usr/share/doc/libbrotli1 \
        '--path-include=/usr/share/doc/libbrotli1/*' \
        --path-include=/usr/share/lintian/overrides/libbrotli1 \
        -i "$deb" >&2
    inventory > "$tmp/after"
    configuration > "$tmp/config-after"
    cmp "$tmp/before" "$tmp/after"
    cmp "$tmp/config-before" "$tmp/config-after"
    mkdir -p "$evidence"
    printf '%s\n' '{"schemaVersion":1,"status":"installed-and-verified","beforeVersion":"1.2.0-3build1+pasturestack.1","version":"1.2.0-3ubuntu0.1","packageSetUnchanged":true,"dpkgConfigurationUnchanged":true}' > "$evidence/install.json"
fi
test "$(dpkg-query -W -f='${db:Status-Status}' libbrotli1)" = installed
test "$(dpkg-query -W -f='${Version}' libbrotli1)" = "$version"
test "$(dpkg-query -W -f='${Architecture}' libbrotli1)" = amd64
test "$(dpkg-query -W -f='${source:Package}' libbrotli1)" = brotli
test "$(dpkg-query -W -f='${Depends}' libbrotli1)" = 'libc6 (>= 2.29)'
integrity=$(dpkg --verify libbrotli1)
test -z "$integrity"
printf '%s  %s\n' 71595cf0ee66e012285edc233198e97d4a1a0fddbf64828566c9a9c4987637c6 /var/lib/dpkg/info/libbrotli1:amd64.md5sums | sha256sum -c - >&2
cd /
sha256sum -c <<'SHA' >&2
7f3acc17bffda6f12f7b022e9386514cfd83e77de67e71218bcbf19ec3577a99  usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1.2.0
470ed7f6b9053163b65b83efebc53bb98ca0d7a5a30ead2b545a4e5574da9c91  usr/lib/x86_64-linux-gnu/libbrotlidec.so.1.2.0
cc91392bf885be8bf1beecba292988686c7171f5f29ec5fece7bd92299f30365  usr/lib/x86_64-linux-gnu/libbrotlienc.so.1.2.0
SHA
for name in common dec enc; do
    library="libbrotli${name}.so.1"
    test "$(readlink "/usr/lib/x86_64-linux-gnu/$library")" = "$library.2.0"
    linkage=$(ldd -r "/usr/lib/x86_64-linux-gnu/$library" 2>&1)
    if printf '%s\n' "$linkage" | grep -E 'not found|undefined symbol'; then exit 1; fi
done
printf '%s\n' '{"schemaVersion":1,"status":"verified","package":"libbrotli1","source":"brotli","version":"1.2.0-3ubuntu0.1","architecture":"amd64","archiveSha256":"bedeef1cf3268f90338c411cdb0a45b224d0660fd2240f310f380316c8244606","dpkgVerify":"PASS","linkage":"PASS","sonames":{"libbrotlicommon.so.1":"7f3acc17bffda6f12f7b022e9386514cfd83e77de67e71218bcbf19ec3577a99","libbrotlidec.so.1":"470ed7f6b9053163b65b83efebc53bb98ca0d7a5a30ead2b545a4e5574da9c91","libbrotlienc.so.1":"cc91392bf885be8bf1beecba292988686c7171f5f29ec5fece7bd92299f30365"}}'
