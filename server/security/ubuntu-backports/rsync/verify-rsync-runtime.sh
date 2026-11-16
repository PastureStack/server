#!/bin/sh
set -eu

expected_version=3.4.1+ds1-7ubuntu0.3+pasturestack.1
test "$(dpkg-query -W -f='${Version}' rsync)" = "$expected_version"
test "$(dpkg-query -W -f='${Architecture}' rsync)" = amd64
integrity="$(dpkg --verify rsync)"
test -z "$integrity"
rsync --version | grep -F 'version 3.4.1 ' >/dev/null
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir "$fixture/source" "$fixture/dest"
printf '%s\n' 'original content' >"$fixture/source/data"
chmod 640 "$fixture/source/data"
ln "$fixture/source/data" "$fixture/source/hardlink"
ln -s data "$fixture/source/link"
rsync -azH "$fixture/source/" "$fixture/dest/"
cmp "$fixture/source/data" "$fixture/dest/data"
test "$(readlink "$fixture/dest/link")" = data
test "$(stat -c '%a' "$fixture/dest/data")" = 640
test "$(stat -c '%i' "$fixture/dest/data")" = "$(stat -c '%i' "$fixture/dest/hardlink")"
printf '%s\n' 'valid incremental update' >>"$fixture/source/data"
printf '%s\n' 'outdated destination file' >"$fixture/dest/stale"
rsync -azHc --no-whole-file --delete --min-size=1 --max-size=1m "$fixture/source/" "$fixture/dest/"
cmp "$fixture/source/data" "$fixture/dest/data"
test ! -e "$fixture/dest/stale"
printf '%s\n' "PASS: rsync $expected_version Ubuntu package, local compressed copy and incremental sync"
