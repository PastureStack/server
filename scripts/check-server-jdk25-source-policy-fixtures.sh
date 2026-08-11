#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

workdir=$(mktemp -d "${TMPDIR:-/tmp}/server-jdk25-source-policy.XXXXXX")
trap 'rm -rf "$workdir"' EXIT

write_fixture_tree() {
  local root=$1
  local docker_base=${2:-'FROM ubuntu:26.04'}
  local javac_command=${3:-'javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java'}
  local source_gate_line=${4:-'run_gate server_jdk25_source_policy bash scripts/check-server-jdk25-source-policy.sh'}
  local patch_gate_image=${5:-'image="${RC16_JDK25_CHECK_IMAGE:-eclipse-temurin:25.0.4_7-jdk}"'}

  mkdir -p "$root/server/patches" "$root/scripts"

  cat >"$root/server/Dockerfile" <<DOCKER
# syntax=docker/dockerfile:1.7
${docker_base}
ARG TEMURIN_JDK25_VERSION="25.0.4+7"
ARG TEMURIN_JDK25_URL="https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.4%2B7/OpenJDK25U-jdk_x64_linux_hotspot_25.0.4_7.tar.gz"
ARG TEMURIN_JDK25_SHA256="e58fcdcd637b25c03ca84cbbcefc70d11efb8f4b4cbd05decc9f661769d77f94"
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=\${JAVA_HOME}/bin:\${PATH}
RUN apt-get update && apt-get upgrade -y
RUN echo "\${TEMURIN_JDK25_SHA256}  /tmp/temurin-jdk25.tar.gz" | sha256sum -c -
RUN ln -s \${JAVA_HOME}/bin/java /usr/bin/java && \
    ln -s \${JAVA_HOME}/bin/jar /usr/bin/jar && \
    ln -s \${JAVA_HOME}/bin/javac /usr/bin/javac && \
    java -version
RUN ${javac_command}
DOCKER

  cat >"$root/server/Dockerfile.auth-hotfix" <<DOCKER
ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.266
FROM \${BASE_IMAGE}
RUN ${javac_command}
DOCKER

  cat >"$root/server/patches/PatchV1GlobalSubscribe.java" <<'JAVA'
import org.apache.commons.io.serialization.ValidatingObjectInputStream;

public class PatchV1GlobalSubscribe {
    private static final String[] ALLOWED_SERIALIZED_CLASSES = {"java.util.ArrayList"};
    private static void limitSchemaObjectGraph() {
        ValidatingObjectInputStream.builder()
                .accept(ALLOWED_SERIALIZED_CLASSES);
    }

    public static void main(String[] args) {
        String marker = "readObjectCast()";
    }
}
JAVA

  cat >"$root/scripts/check-server-java-patches-jdk25.sh" <<PATCHGATE
#!/usr/bin/env bash
${patch_gate_image}
commons_io_version=2.22.0
jdk_home="\${RC16_JDK25_HOME:-}"
javac -Xlint:deprecation -Werror -cp lib/commons-io.jar -d classes
javap -verbose classes/PatchV1GlobalSubscribe.class | grep -q "major version: 69"
echo "SERVER_JAVA_PATCH_JDK25_OK file=server/patches/PatchV1GlobalSubscribe.java image=\$image class_major=69 suppresswarnings=0 runtime_smoke=1"
PATCHGATE

  cat >"$root/scripts/check-server-cattle-jdk25-release-evidence.sh" <<'RELEASEGATE'
#!/usr/bin/env bash
require_marker 'CATTLE_JDK25_FULL_PACKAGE_OK' SERVER_CATTLE_RELEASE_FULL_PACKAGE_MARKER_MISSING
require_marker 'bytecode major `69`' SERVER_CATTLE_RELEASE_BYTECODE_MARKER_MISSING
require_marker 'packaged-lib hygiene OK' SERVER_CATTLE_RELEASE_PACKAGED_LIB_MARKER_MISSING
require_marker 'standalone startup OK' SERVER_CATTLE_RELEASE_STANDALONE_MARKER_MISSING
require_marker 'failure_count=0' SERVER_CATTLE_RELEASE_FAILURE_COUNT_MARKER_MISSING
RELEASEGATE

  cat >"$root/scripts/check-server-source-gates.sh" <<GATES
#!/usr/bin/env bash
${source_gate_line}
GATES
}

positive="$workdir/positive"
write_fixture_tree "$positive"
if ! RC16_SERVER_SOURCE_ROOT="$positive" scripts/check-server-jdk25-source-policy.sh >"$workdir/positive.out" 2>&1; then
  echo "expected positive fixture to pass" >&2
  cat "$workdir/positive.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_OK' "$workdir/positive.out"

legacy_base="$workdir/legacy-base"
write_fixture_tree "$legacy_base" 'FROM eclipse-temurin:17-jdk'
if RC16_SERVER_SOURCE_ROOT="$legacy_base" scripts/check-server-jdk25-source-policy.sh >"$workdir/legacy-base.out" 2>&1; then
  echo "expected legacy-base fixture to fail" >&2
  cat "$workdir/legacy-base.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_UBUNTU2604_BASE_MISSING' "$workdir/legacy-base.out"
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_LEGACY_JAVA_MARKER' "$workdir/legacy-base.out"

missing_security_upgrade="$workdir/missing-security-upgrade"
write_fixture_tree "$missing_security_upgrade"
perl -0pi -e 's/RUN apt-get update && apt-get upgrade -y\n//' "$missing_security_upgrade/server/Dockerfile"
if RC16_SERVER_SOURCE_ROOT="$missing_security_upgrade" scripts/check-server-jdk25-source-policy.sh >"$workdir/missing-security-upgrade.out" 2>&1; then
  echo "expected missing-security-upgrade fixture to fail" >&2
  cat "$workdir/missing-security-upgrade.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_APT_SECURITY_UPGRADE_MISSING' "$workdir/missing-security-upgrade.out"

missing_jdk_checksum="$workdir/missing-jdk-checksum"
write_fixture_tree "$missing_jdk_checksum"
sed -i '/TEMURIN_JDK25_SHA256.*sha256sum -c -/d' "$missing_jdk_checksum/server/Dockerfile"
if RC16_SERVER_SOURCE_ROOT="$missing_jdk_checksum" scripts/check-server-jdk25-source-policy.sh >"$workdir/missing-jdk-checksum.out" 2>&1; then
  echo "expected missing-jdk-checksum fixture to fail" >&2
  cat "$workdir/missing-jdk-checksum.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_TEMURIN25_CHECK_MISSING' "$workdir/missing-jdk-checksum.out"

source_flag="$workdir/source-flag"
write_fixture_tree "$source_flag" 'FROM ubuntu:26.04' 'javac -source 8 -target 8 -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java'
if RC16_SERVER_SOURCE_ROOT="$source_flag" scripts/check-server-jdk25-source-policy.sh >"$workdir/source-flag.out" 2>&1; then
  echo "expected source-flag fixture to fail" >&2
  cat "$workdir/source-flag.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_DRIFT' "$workdir/source-flag.out"

unwired="$workdir/unwired"
write_fixture_tree "$unwired" 'FROM ubuntu:26.04' 'javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java' '# missing server_jdk25_source_policy'
if RC16_SERVER_SOURCE_ROOT="$unwired" scripts/check-server-jdk25-source-policy.sh >"$workdir/unwired.out" 2>&1; then
  echo "expected unwired fixture to fail" >&2
  cat "$workdir/unwired.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_SOURCE_GATES_NOT_WIRED' "$workdir/unwired.out"

old_patch_gate="$workdir/old-patch-gate"
write_fixture_tree "$old_patch_gate" 'FROM ubuntu:26.04' 'javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java' 'run_gate server_jdk25_source_policy bash scripts/check-server-jdk25-source-policy.sh' 'image="${RC16_JDK25_CHECK_IMAGE:-eclipse-temurin:21-jdk}"'
if RC16_SERVER_SOURCE_ROOT="$old_patch_gate" scripts/check-server-jdk25-source-policy.sh >"$workdir/old-patch-gate.out" 2>&1; then
  echo "expected old-patch-gate fixture to fail" >&2
  cat "$workdir/old-patch-gate.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_IMAGE_MISSING' "$workdir/old-patch-gate.out"

extra_java="$workdir/extra-java"
write_fixture_tree "$extra_java"
cat >"$extra_java/server/patches/Unexpected.java" <<'JAVA'
public class Unexpected {
}
JAVA
if RC16_SERVER_SOURCE_ROOT="$extra_java" scripts/check-server-jdk25-source-policy.sh >"$workdir/extra-java.out" 2>&1; then
  echo "expected extra-java fixture to fail" >&2
  cat "$workdir/extra-java.out" >&2
  exit 1
fi
grep -Fq 'SERVER_JDK25_SOURCE_POLICY_JAVA_SURFACE_DRIFT' "$workdir/extra-java.out"

echo "SERVER_JDK25_SOURCE_POLICY_FIXTURES_OK"
