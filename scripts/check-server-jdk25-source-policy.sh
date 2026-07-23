#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_root=${RC16_SERVER_SOURCE_ROOT:-$repo_root}

resolve_python_cmd() {
  for candidate in "${PYTHON:-}" python3 python; do
    [ -n "$candidate" ] || continue
    if "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

python_cmd="$(resolve_python_cmd)" || {
  echo "python3 or python is required for the server JDK25 source policy gate" >&2
  exit 2
}

RC16_SERVER_SOURCE_ROOT="$source_root" "$python_cmd" - <<'PY'
import os
import re
import sys
from pathlib import Path

root = Path(os.environ["RC16_SERVER_SOURCE_ROOT"]).resolve()
failures = []


def emit(kind, code, detail=""):
    line = f"{kind} {code}"
    if detail:
        line += f" {detail}"
    print(line)


def fail(code, detail=""):
    failures.append(code)
    emit("FAIL", code, detail)


def pass_(code, detail=""):
    emit("PASS", code, detail)


def read_text(rel):
    path = root / rel
    if not path.is_file():
        fail("SERVER_JDK25_SOURCE_POLICY_FILE_MISSING", f"file={rel}")
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def require_marker(rel, marker, code):
    text = read_text(rel)
    if marker in text:
        pass_(code, f"file={rel}")
    else:
        fail(code.replace("_OK", "_MISSING"), f"file={rel} marker={marker}")
    return text


def require_regex(rel, pattern, code):
    text = read_text(rel)
    if re.search(pattern, text, re.MULTILINE):
        pass_(code, f"file={rel}")
    else:
        fail(code.replace("_OK", "_MISSING"), f"file={rel} pattern={pattern}")
    return text


dockerfile = read_text("server/Dockerfile")
auth_hotfix = read_text("server/Dockerfile.auth-hotfix")
patch = read_text("server/patches/PatchV1GlobalSubscribe.java")
java_patch_gate = read_text("scripts/check-server-java-patches-jdk25.sh")
release_evidence_gate = read_text("scripts/check-server-cattle-jdk25-release-evidence.sh")
source_gates = read_text("scripts/check-server-source-gates.sh")

if dockerfile.startswith("# syntax=docker/dockerfile:1.7"):
    pass_("SERVER_JDK25_SOURCE_POLICY_DOCKERFILE_SYNTAX_OK")
else:
    fail("SERVER_JDK25_SOURCE_POLICY_DOCKERFILE_SYNTAX_MISSING")

for marker, code in [
    ("FROM ubuntu:26.04", "SERVER_JDK25_SOURCE_POLICY_UBUNTU2604_BASE_OK"),
    ("apt-get update && apt-get upgrade -y", "SERVER_JDK25_SOURCE_POLICY_APT_SECURITY_UPGRADE_OK"),
    ('ARG TEMURIN_JDK25_URL="https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk"', "SERVER_JDK25_SOURCE_POLICY_TEMURIN25_URL_OK"),
    ("ENV JAVA_HOME=/opt/java/openjdk", "SERVER_JDK25_SOURCE_POLICY_JAVA_HOME_OK"),
    ("ENV PATH=${JAVA_HOME}/bin:${PATH}", "SERVER_JDK25_SOURCE_POLICY_JAVA_PATH_OK"),
    ("ln -s ${JAVA_HOME}/bin/java /usr/bin/java", "SERVER_JDK25_SOURCE_POLICY_JAVA_SYMLINK_OK"),
    ("ln -s ${JAVA_HOME}/bin/jar /usr/bin/jar", "SERVER_JDK25_SOURCE_POLICY_JAR_SYMLINK_OK"),
    ("ln -s ${JAVA_HOME}/bin/javac /usr/bin/javac", "SERVER_JDK25_SOURCE_POLICY_JAVAC_SYMLINK_OK"),
    ("java -version", "SERVER_JDK25_SOURCE_POLICY_JAVA_VERSION_SMOKE_OK"),
]:
    if marker in dockerfile:
        pass_(code)
    else:
        fail(code.replace("_OK", "_MISSING"), f"marker={marker}")

legacy_java_markers = [
    "openjdk-8",
    "openjdk-11",
    "openjdk-17",
    "openjdk-21",
    "temurin-8",
    "temurin-11",
    "temurin-17",
    "temurin-21",
    "eclipse-temurin:8",
    "eclipse-temurin:11",
    "eclipse-temurin:17",
    "eclipse-temurin:21",
    "java:8",
    "java:11",
    "java:17",
    "java:21",
]
legacy_hits = []
for rel in ("server/Dockerfile", "server/Dockerfile.auth-hotfix"):
    text = dockerfile if rel.endswith("Dockerfile") else auth_hotfix
    for marker in legacy_java_markers:
        if marker in text:
            legacy_hits.append((rel, marker))
for rel, marker in legacy_hits:
    fail("SERVER_JDK25_SOURCE_POLICY_LEGACY_JAVA_MARKER", f"file={rel} marker={marker}")
if not legacy_hits:
    pass_("SERVER_JDK25_SOURCE_POLICY_NO_LEGACY_JAVA_MARKERS_OK")

expected_javac = 'javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java'
for rel, text in (("server/Dockerfile", dockerfile), ("server/Dockerfile.auth-hotfix", auth_hotfix)):
    if expected_javac in text:
        pass_("SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_OK", f"file={rel}")
    else:
        fail("SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_MISSING", f"file={rel}")

    for command in text.splitlines():
        if not re.search(r"\bjavac\b", command):
            continue
        if re.search(r"(^|[=\s])(-source|-target|--release|--enable-preview|-proc:|-J)", command):
            fail("SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_DRIFT", f"file={rel} command={command.strip()}")
if not any("SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_DRIFT" == item for item in failures):
    pass_("SERVER_JDK25_SOURCE_POLICY_PATCH_JAVAC_NO_DRIFT_OK")

java_files = []
for path in sorted(root.rglob("*.java")):
    if ".git" in path.parts or "target" in path.parts:
        continue
    try:
        java_files.append(path.relative_to(root).as_posix())
    except ValueError:
        java_files.append(str(path))
expected_java_files = ["server/patches/PatchV1GlobalSubscribe.java"]
if java_files == expected_java_files:
    pass_("SERVER_JDK25_SOURCE_POLICY_JAVA_SURFACE_OK", "java_files=1")
else:
    fail("SERVER_JDK25_SOURCE_POLICY_JAVA_SURFACE_DRIFT", "files=" + ",".join(java_files))

if "@SuppressWarnings" in patch:
    fail("SERVER_JDK25_SOURCE_POLICY_PATCH_SUPPRESSWARNINGS_PRESENT", "file=server/patches/PatchV1GlobalSubscribe.java")
else:
    pass_("SERVER_JDK25_SOURCE_POLICY_PATCH_SUPPRESSWARNINGS_ABSENT_OK")

for marker, code in [
    ('image="${RC16_JDK25_CHECK_IMAGE:-eclipse-temurin:25-jdk}"', "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_IMAGE_OK"),
    ("javac -Xlint:deprecation -Werror -d classes", "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_WERROR_OK"),
    ('major version: 69', "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_CLASS_MAJOR_OK"),
    ("SERVER_JAVA_PATCH_JDK25_OK", "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_RESULT_OK"),
    ("suppresswarnings=0", "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_SUPPRESSION_MARKER_OK"),
    ("runtime_smoke=1", "SERVER_JDK25_SOURCE_POLICY_PATCH_GATE_RUNTIME_SMOKE_OK"),
]:
    if marker in java_patch_gate:
        pass_(code)
    else:
        fail(code.replace("_OK", "_MISSING"), f"marker={marker}")

for marker, code in [
    ("CATTLE_JDK25_FULL_PACKAGE_OK", "SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_FULL_PACKAGE_MARKER_OK"),
    ("bytecode major `69`", "SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_BYTECODE_MARKER_OK"),
    ("packaged-lib hygiene OK", "SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_PACKAGED_LIB_MARKER_OK"),
    ("standalone startup OK", "SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_STANDALONE_MARKER_OK"),
    ("failure_count=0", "SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_FAILURE_MARKER_OK"),
]:
    if marker in release_evidence_gate:
        pass_(code)
    else:
        fail(code.replace("_OK", "_MISSING"), f"marker={marker}")

if "run_gate server_jdk25_source_policy bash scripts/check-server-jdk25-source-policy.sh" in source_gates:
    pass_("SERVER_JDK25_SOURCE_POLICY_SOURCE_GATES_WIRED_OK")
else:
    fail("SERVER_JDK25_SOURCE_POLICY_SOURCE_GATES_NOT_WIRED")

if "run_gate jdk25_java_patches scripts/check-server-java-patches-jdk25.sh" in source_gates:
    fail("SERVER_JDK25_SOURCE_POLICY_JAVA_PATCH_GATE_MUST_REMAIN_MANUAL")
else:
    pass_("SERVER_JDK25_SOURCE_POLICY_JAVA_PATCH_GATE_MANUAL_ONLY_OK")

if "run_gate cattle_jdk25_release_evidence scripts/check-server-cattle-jdk25-release-evidence.sh" in source_gates:
    fail("SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_GATE_MUST_REMAIN_MANUAL")
else:
    pass_("SERVER_JDK25_SOURCE_POLICY_CATTLE_RELEASE_GATE_MANUAL_ONLY_OK")

print(f"failure_count={len(failures)}")
if failures:
    sys.exit(1)

print(f"SERVER_JDK25_SOURCE_POLICY_OK source_root={root} java_surface=server_patch docker_runtime=temurin25 class_major_gate=69")
PY
