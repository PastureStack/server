#!/bin/sh
# Read-only candidate-container verification; fixture files stay in /tmp.
set -eu
test "$#" -eq 0
export LC_ALL=C
cd /
expected_version=10.46-1build1+pasturestack.1
manifest=/usr/share/pasturestack/security/pcre2-runtime.sha256
temporary=$(mktemp -d /tmp/pcre2-runtime.XXXXXXXX)
trap 'rm -f -- "$temporary/"*; rmdir -- "$temporary"' EXIT HUP INT TERM

for package in libpcre2-8-0 libpcre2-posix3; do
    actual=$(dpkg-query --show --showformat='${db:Status-Status}\t${Version}\n' "$package")
    test "$actual" = "$(printf 'installed\t%s' "$expected_version")"
done
if ! dpkg --verify libpcre2-8-0 libpcre2-posix3 > "$temporary/dpkg-verify" 2>&1; then
    cat "$temporary/dpkg-verify" >&2
    exit 1
fi
if test -s "$temporary/dpkg-verify"; then
    cat "$temporary/dpkg-verify" >&2
    exit 1
fi

pcre2=$(readlink -f /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0)
posix=$(readlink -f /usr/lib/x86_64-linux-gnu/libpcre2-posix.so.3)
test -f "$pcre2" && test -f "$posix" && test "$pcre2" != "$posix"
test -s "$manifest"
awk 'NF != 2 || length($1) != 64 || $1 ~ /[^0-9a-f]/ {exit 1}
     END {if (NR != 2) exit 1}' "$manifest"
count_pcre2=0 count_posix=0
while read -r expected_sha file; do
    resolved=$(readlink -f -- "$file")
    case "$resolved" in
        "$pcre2") count_pcre2=$((count_pcre2 + 1));;
        "$posix") count_posix=$((count_posix + 1));;
        *) echo 'Unexpected file in PCRE2 runtime hash manifest' >&2; exit 1;;
    esac
done < "$manifest"
test "$count_pcre2:$count_posix" = 1:1
sha256sum --check "$manifest"

for consumer in /usr/bin/grep /usr/bin/git /usr/sbin/mariadbd \
    /usr/lib/x86_64-linux-gnu/libselinux.so.1 \
    /usr/lib/x86_64-linux-gnu/libpcre2-posix.so.3; do
    test -f "$consumer"
    if ! ldd -r "$consumer" > "$temporary/ldd" 2>&1; then
        cat "$temporary/ldd" >&2
        exit 1
    fi
    if grep -Eiq 'not found|undefined symbol' "$temporary/ldd"; then
        cat "$temporary/ldd" >&2
        exit 1
    fi
    linked=$(awk '$1 == "libpcre2-8.so.0" && $2 == "=>" {print $3; count++}
                   END {if (count != 1) exit 1}' "$temporary/ldd")
    test "$(readlink -f -- "$linked")" = "$pcre2"
    printf 'PCRE2_CONSUMER_LINK_OK consumer=%s resolved=%s\n' "$consumer" "$pcre2"
done

locale -a > "$temporary/locales"
grep -Fx C "$temporary/locales" > /dev/null
grep -Fx C.utf8 "$temporary/locales" > /dev/null
printf 'ASCII\n漢字\nCRLF\r\n' > "$temporary/input"
printf 'ASCII\n' > "$temporary/ascii"
printf '漢字\n' > "$temporary/han"
printf 'CRLF\r\n' > "$temporary/crlf"
printf 'os-release:ID=ubuntu\n' > "$temporary/os-release"
for test_locale in C C.utf8; do
    for prefix in '' '(*NO_JIT)'; do
        LC_ALL="$test_locale" /usr/bin/grep -P -- "${prefix}^ASCII$" "$temporary/input" > "$temporary/actual"
        cmp "$temporary/ascii" "$temporary/actual"
        LC_ALL="$test_locale" /usr/bin/grep -P -- "${prefix}(*UTF)^漢字$" "$temporary/input" > "$temporary/actual"
        cmp "$temporary/han" "$temporary/actual"
        LC_ALL="$test_locale" /usr/bin/grep -P -- "${prefix}^CRLF\r$" "$temporary/input" > "$temporary/actual"
        cmp "$temporary/crlf" "$temporary/actual"
    done
    LC_ALL="$test_locale" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
        /usr/bin/git -C /usr/lib grep --no-index -P '^ID=ubuntu$' -- os-release > "$temporary/actual"
    cmp "$temporary/os-release" "$temporary/actual"
done
echo PCRE2_RUNTIME_BACKPORT_OK
