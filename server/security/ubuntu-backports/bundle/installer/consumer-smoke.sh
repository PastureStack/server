#!/bin/bash
# Only run by consumer-fixture.Dockerfile in an isolated image build.
set -euo pipefail
export LC_ALL=C
provider="${1:?provider required}"
case "$provider" in gnu|uutils) ;; *) exit 2 ;; esac
test "$#" -eq 1
readonly data=/opt/pasturestack/ubuntu-security-backports
readonly evidence=/evidence
mkdir -p "$evidence"
exec > >(tee "$evidence/console.log") 2>&1

installed() {
    test "$(dpkg-query --show --showformat='${db:Status-Status}' "$1" 2>/dev/null)" = installed
}
absent() {
    if installed "$1"; then
        printf 'Unexpected installed package: %s\n' "$1" >&2
        return 1
    fi
}
package_set() {
    dpkg-query --show --showformat='${binary:Package}\t${Architecture}\t${db:Status-Status}\n' |
        awk -F '\t' '$3 == "installed" { print $1 "\t" $2 }' | sort
}
provider_state() {
    dpkg-query --show --showformat='${binary:Package}\t${Version}\t${Architecture}\t${db:Status-Status}\n' \
        "coreutils-from-$provider" gnu-coreutils
    stat --format='%F:%a:%u:%g' /usr/bin/ls /usr/bin/id
    for command in /usr/bin/ls /usr/bin/id; do
        if test -L "$command"; then readlink "$command"; else sha256sum "$command"; fi
    done
}
installed "coreutils-from-$provider"
installed gnu-coreutils
if [[ "$provider" == gnu ]]; then
    absent rust-coreutils
    absent coreutils-from-uutils
    expected=11
else
    installed rust-coreutils
    absent coreutils-from-gnu
    expected=12
fi
for package in libc6-dev libc-dev-bin libpcre2-dev libjq-dev libp11-kit-dev libxrender-dev; do
    absent "$package"
done
input_manifest_sha="$(sha256sum "$data/manifest.json" | awk '{print $1}')"
package_set >"$evidence/packages-before.tsv"
provider_state >"$evidence/provider-before.tsv"
sha256sum /etc/ld.so.cache >"$evidence/ld-so-cache-before.sha256"

# The only installer invocation which mutates this disposable consumer rootfs.
"$data/install-existing-backports" --install-in-docker-build >"$evidence/install.json"
"$data/install-existing-backports" --verify-installed >"$evidence/verify.json"
cat "$evidence/install.json" "$evidence/verify.json"
jq -e --argjson expected "$expected" '.status == "installed-and-verified" and .providerPreserved and .configurationPreserved and (.packages | length) == $expected and (.beforeMissingDocumentation | length) > 0 and (.exactPathIncludes | length) > 0' "$evidence/install.json" >/dev/null
jq -e '.status == "verified"' "$evidence/verify.json" >/dev/null
cmp <(jq -c '.packages|sort' "$evidence/install.json") <(jq -c '.packages|sort' "$evidence/verify.json")
if [[ "$provider" == gnu ]]; then
    absent rust-coreutils
    jq -e '.packages | index("rust-coreutils") == null' "$evidence/install.json" >/dev/null
else
    installed rust-coreutils
    jq -e '.packages | index("rust-coreutils") != null' "$evidence/install.json" >/dev/null
fi
package_set >"$evidence/packages-after.tsv"
provider_state >"$evidence/provider-after.tsv"
cmp "$evidence/packages-before.tsv" "$evidence/packages-after.tsv"
cmp "$evidence/provider-before.tsv" "$evidence/provider-after.tsv"
while IFS= read -r path; do
    case "$path" in /usr/share/doc/*|/usr/share/man/*|/usr/share/info/*) ;; *) exit 1 ;; esac
    test -e "$path" || test -L "$path"
done < <(jq -r '.exactPathIncludes[]' "$evidence/install.json")
test -z "$(dpkg --audit)"

# Exercise the installed loader/cache and programs from the same qualified
# archives. This does not repeat the upstream compiler/owning suites.
test -s /etc/ld.so.cache
sha256sum /etc/ld.so.cache >"$evidence/ld-so-cache-after.sha256"
ldconfig -p >"$evidence/ldconfig.txt"
for soname in libc.so.6 libpcre2-8.so.0 libpcre2-posix.so.3 libjq.so.1 libp11-kit.so.0 libXrender.so.1; do
    grep -F "$soname " "$evidence/ldconfig.txt"
done
getconf GNU_LIBC_VERSION | tee "$evidence/glibc-version.txt" | grep -Fx 'glibc 2.43'
/lib64/ld-linux-x86-64.so.2 --verify /usr/bin/jq
ldd /usr/lib/x86_64-linux-gnu/libXrender.so.1 >"$evidence/libxrender-loader.txt"
if grep -F 'not found' "$evidence/libxrender-loader.txt"; then exit 1; fi
printf '%s\n' '{"numbers":[1,2,3]}' | jq -e '.numbers | add == 6'
test "$(id -u)" = 0
test "$(id -g)" = 0
id -G >"$evidence/id-groups.txt"
p11-kit list-modules >"$evidence/p11-kit-modules.txt"
printf 'a123\n' | grep -P '^a\d{3}$'
getent passwd root | tee "$evidence/getent-root.txt" | grep -E '^root:[^:]*:0:0:'
test "$input_manifest_sha" = "$(sha256sum "$data/manifest.json" | awk '{print $1}')"
jq -n --arg provider "$provider" --arg manifest "$input_manifest_sha" \
    --slurpfile receipt "$evidence/install.json" \
    '{schemaVersion:1,provider:$provider,status:"PASS",inputManifestSha256:$manifest,selectedPackages:$receipt[0].packages,checks:["batch-install","verify-installed","package-set","provider","docs-restored","glibc-loader","jq","id","p11-kit","grep","getent"]}' >"$evidence/result.json"
cat "$evidence/result.json"
