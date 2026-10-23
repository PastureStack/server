#!/bin/sh
# Offline same-series micro-updates; never add packages or downgrade a newer base.
set -eu
test "$#" -eq 2 || { echo 'usage: security-updates LOCK VERIFIED_DEB_DIRECTORY' >&2; exit 2; }
lock=$1 bundle=$2
. /etc/os-release
test "$ID:$VERSION_ID" = ubuntu:26.04
test -s "$lock"
test -s "$bundle/manifest.tsv"
test ! -L "$bundle/manifest.tsv"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# Bind this bundle to the complete source lock, not just selected packages.
tab=$(printf '\t')
exec 3< "$bundle/manifest.tsv"
IFS="$tab" read -r kind lock_sha extra <&3
test "$kind" = lock-sha256
test -z "$extra"
test "$lock_sha" = "$(sha256sum "$lock" | cut -d ' ' -f 1)"
while IFS= read -r entry || test -n "$entry"; do
    case "$entry" in ''|'#'*) continue;; esac
    package=${entry%%=*}; version=${entry#*=}
    printf '%s\n' "$package" | grep -Eq '^[a-z0-9][a-z0-9+.-]*$'
    case "$version" in ''|*[!a-zA-Z0-9.:+~_-]*) exit 1;; esac
    test "$package" != "$version"
    printf '%s=%s\n' "$package" "$version"
done < "$lock" > "$tmp/locked"
test -s "$tmp/locked"
cut -d= -f1 "$tmp/locked" | sort | uniq -d > "$tmp/duplicates"
test ! -s "$tmp/duplicates"
architecture=$(dpkg --print-architecture)
: > "$tmp/verified"
: > "$tmp/expected-debs"
# Verify all supplied bytes and metadata before any package transaction.
while IFS="$tab" read -r package version arch digest filename extra <&3; do
    test -n "$package"
    test -z "$extra"
    printf '%s\n' "$package" | grep -Eq '^[a-z0-9][a-z0-9+.-]*$'
    test "$filename" = "$package.deb"
    case "$arch" in "$architecture"|all) ;; *) exit 1;; esac
    printf '%s\n' "$digest" | grep -Eq '^[0-9a-f]{64}$'
    test -f "$bundle/$filename"
    test ! -L "$bundle/$filename"
    printf '%s  %s\n' "$digest" "$bundle/$filename" | sha256sum -c -
    test "$(dpkg-deb -f "$bundle/$filename" Package)" = "$package"
    test "$(dpkg-deb -f "$bundle/$filename" Version)" = "$version"
    test "$(dpkg-deb -f "$bundle/$filename" Architecture)" = "$arch"
    printf '%s=%s\n' "$package" "$version" >> "$tmp/verified"
    printf '%s\n' "$filename" >> "$tmp/expected-debs"
done
exec 3<&-
sort "$tmp/locked" > "$tmp/locked.sorted"
sort "$tmp/verified" > "$tmp/verified.sorted"
cmp "$tmp/locked.sorted" "$tmp/verified.sorted"
find "$bundle" -maxdepth 1 -name '*.deb' -printf '%f\n' | sort > "$tmp/actual-debs"
sort "$tmp/expected-debs" > "$tmp/expected-debs.sorted"
cmp "$tmp/expected-debs.sorted" "$tmp/actual-debs"

dpkg-query -W -f='${binary:Package}\t${db:Status-Status}\n' > "$tmp/inventory"
LC_ALL=C sort "$tmp/inventory" > "$tmp/before"
set --
while IFS='=' read -r package version; do
    status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
    test "$status" = installed || continue
    installed=$(dpkg-query -W -f='${Version}' "$package")
    if dpkg --compare-versions "$installed" ge "$version"; then continue; else
        test "$?" -eq 1
    fi
    set -- "$@" "$bundle/$package.deb"
done < "$tmp/verified"
if test "$#" -gt 0; then
    DEBIAN_FRONTEND=noninteractive dpkg --install "$@"
fi
dpkg-query -W -f='${binary:Package}\t${db:Status-Status}\n' > "$tmp/inventory"
LC_ALL=C sort "$tmp/inventory" > "$tmp/after"
cmp "$tmp/before" "$tmp/after"
while IFS='=' read -r package version; do
    status=$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)
    test "$status" = installed || continue
    dpkg --compare-versions "$(dpkg-query -W -f='${Version}' "$package")" ge "$version"
done < "$tmp/verified"
printf 'UBUNTU_SECURITY_MICRO_UPDATES_OK offline=1 package_set=unchanged\n'
