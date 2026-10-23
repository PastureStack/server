#!/bin/sh
# APT authenticates the snapshot only in the disposable Ubuntu build stage.
set -eu
test "$#" -eq 3 || { echo 'usage: download-security-updates LOCK TRUSTED_CA_BUNDLE OUTPUT' >&2; exit 2; }
lock=$1 trusted_ca=$2 output=$3
. /etc/os-release
test "$ID:$VERSION_ID" = ubuntu:26.04
test -s "$lock"
test -s "$trusted_ca"
test ! -e "$output"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/lists/partial" "$tmp/download" "$output"
printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/20261023T000000Z\nSuites: resolute-updates resolute-security\nComponents: main\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' > "$tmp/security.sources"
apt_security() {
    apt-get -o Dir::Etc::sourcelist="$tmp/security.sources" \
        -o Dir::State::lists="$tmp/lists" \
        -o Dir::Cache::pkgcache="$tmp/pkgcache.bin" -o Dir::Cache::srcpkgcache="$tmp/srcpkgcache.bin" \
        -o Dir::Etc::sourceparts=- -o Acquire::https::CaInfo="$trusted_ca" \
        -o Acquire::https::Verify-Peer=true -o Acquire::https::Verify-Host=true \
        -o Acquire::AllowInsecureRepositories=false -o APT::Get::AllowUnauthenticated=false \
        -o Acquire::ForceHash=sha256 \
        -o Acquire::Retries=5 "$@"
}
apt_security update
printf 'lock-sha256\t%s\n' "$(sha256sum "$lock" | cut -d ' ' -f 1)" > "$output/manifest.tsv"
: > "$tmp/names"
architecture=$(dpkg --print-architecture)
while IFS= read -r entry || test -n "$entry"; do
    case "$entry" in ''|'#'*) continue;; esac
    package=${entry%%=*}; version=${entry#*=}
    printf '%s\n' "$package" | grep -Eq '^[a-z0-9][a-z0-9+.-]*$'
    case "$version" in ''|*[!a-zA-Z0-9.:+~_-]*) exit 1;; esac
    test "$package" != "$version"
    if grep -Fxq "$package" "$tmp/names"; then echo 'Duplicate locked package' >&2; exit 1; fi
    printf '%s\n' "$package" >> "$tmp/names"
    # --print-uris exposes the SHA-256 from the authenticated Packages index.
    apt_security --print-uris download "$entry" > "$tmp/uri"
    test "$(wc -l < "$tmp/uri")" -eq 1
    grep -F "'https://snapshot.ubuntu.com/ubuntu/20261023T000000Z/" "$tmp/uri" >/dev/null
    digest=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^SHA256:/) print substr($i,8)}' "$tmp/uri")
    if printf '%s\n' "$digest" | grep -Eq '^[0-9a-f]{64}$'; then :; else
        echo "Authenticated index did not provide exactly one SHA256 for $entry" >&2
        exit 1
    fi
    (cd "$tmp/download" && apt_security download "$entry")
    set -- "$tmp/download/"*.deb
    test "$#" -eq 1
    test -f "$1"
    printf '%s  %s\n' "$digest" "$1" | sha256sum -c -
    test "$(dpkg-deb -f "$1" Package)" = "$package"
    test "$(dpkg-deb -f "$1" Version)" = "$version"
    arch=$(dpkg-deb -f "$1" Architecture)
    case "$arch" in "$architecture"|all) ;; *) exit 1;; esac
    mv "$1" "$output/$package.deb"
    printf '%s\t%s\t%s\t%s\t%s.deb\n' "$package" "$version" "$arch" "$digest" "$package" >> "$output/manifest.tsv"
done < "$lock"
test -s "$tmp/names"
printf 'UBUNTU_SECURITY_DEBS_VERIFIED packages=%s\n' "$(wc -l < "$tmp/names")"
