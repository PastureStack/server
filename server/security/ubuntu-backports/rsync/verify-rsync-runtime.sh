#!/bin/sh
set -eu

expected_version=3.4.1+ds1-7ubuntu0.3+pasturestack.1
test "$(dpkg-query -W -f='${Version}' rsync)" = "$expected_version"
test "$(dpkg-query -W -f='${Architecture}' rsync)" = amd64
# Ubuntu's container dpkg profile excludes docs and manpages.
integrity="$(dpkg --verify rsync)"
unexpected="$(printf '%s\n' "$integrity" | sed -E \
  '/^missing[[:space:]]+\/usr\/share\/doc\/rsync\//d; /^missing[[:space:]]+\/usr\/share\/man\/man[15]\/(rrsync|rsync|rsync-ssl|rsyncd\.conf)\.[15]\.gz$/d')"
if [ -n "$unexpected" ]; then
  printf '%s\n' "$unexpected" >&2
  exit 1
fi
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
