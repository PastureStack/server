#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

expected_patch="server/patches/PatchV1GlobalSubscribe.java"
image="${RC16_JDK25_CHECK_IMAGE:-eclipse-temurin:25.0.4_7-jdk}"
jdk_home="${RC16_JDK25_HOME:-}"
commons_io_version=2.22.0
commons_io_sha256=2b9a7b1f726fb86216dbd2c8321eabe0221dbd5b1be81c18e1cb53811b104758
commons_io_url="https://repo.maven.apache.org/maven2/commons-io/commons-io/${commons_io_version}/commons-io-${commons_io_version}.jar"
failures=0
java_bin=""
javac_bin=""
javap_bin=""
classpath_separator=":"

resolve_jdk_tool() {
  local tool=$1
  if [ -x "$jdk_home/bin/$tool" ]; then
    printf '%s\n' "$jdk_home/bin/$tool"
  elif [ -x "$jdk_home/bin/$tool.exe" ]; then
    classpath_separator=";"
    printf '%s\n' "$jdk_home/bin/$tool.exe"
  else
    return 1
  fi
}

mapfile -t java_files < <(
  find . -path ./.git -prune -o -name '*.java' -print |
    sed 's#^\./##' |
    grep -v '^cattle/' |
    grep -v '^server/target/' |
    sort
)

if [ "${#java_files[@]}" -ne 1 ] || [ "${java_files[0]:-}" != "$expected_patch" ]; then
  echo "UNEXPECTED_NON_CATTLE_JAVA_FILES"
  printf '  %s\n' "${java_files[@]}"
  failures=$((failures + 1))
fi

if grep -q '@SuppressWarnings' "$expected_patch"; then
  echo "SERVER_JAVA_PATCH_SUPPRESSWARNINGS_PRESENT file=$expected_patch"
  failures=$((failures + 1))
fi

for file in server/Dockerfile server/Dockerfile.auth-hotfix; do
  if ! grep -q 'javac -cp "/usr/share/cattle/war/WEB-INF/lib/\*" PatchV1GlobalSubscribe.java' "$file"; then
    echo "MISSING_SERVER_PATCH_JAVAC file=$file"
    failures=$((failures + 1))
  fi
done

if [ -n "$jdk_home" ]; then
  java_bin=$(resolve_jdk_tool java) || true
  javac_bin=$(resolve_jdk_tool javac) || true
  javap_bin=$(resolve_jdk_tool javap) || true
  case "$java_bin" in
    *.exe) classpath_separator=";" ;;
  esac
  if [ -z "$java_bin" ] || [ -z "$javac_bin" ] || [ -z "$javap_bin" ]; then
    echo "JDK25_HOME_INVALID path=$jdk_home"
    failures=$((failures + 1))
  fi
fi

if [ -z "$jdk_home" ] && ! command -v docker >/dev/null 2>&1; then
  echo "DOCKER_MISSING"
  failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
  echo "failure_count=$failures"
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p \
  "$tmp/src/io/github/ibuildthecloud/gdapi/model/impl" \
  "$tmp/classes" \
  "$tmp/lib"

curl -fsSL \
  --retry 5 \
  --retry-all-errors \
  --retry-delay 2 \
  --connect-timeout 10 \
  --max-time 300 \
  -o "$tmp/lib/commons-io.jar" \
  "$commons_io_url"
printf '%s  %s\n' "$commons_io_sha256" "$tmp/lib/commons-io.jar" | sha256sum -c -

cat > "$tmp/src/io/github/ibuildthecloud/gdapi/model/Filter.java" <<'JAVA'
package io.github.ibuildthecloud.gdapi.model;

import java.io.Serializable;
import java.util.List;

public class Filter implements Serializable {
    private List<String> modifiers;

    public Filter(List<String> modifiers) {
        this.modifiers = modifiers;
    }

    public List<String> getModifiers() {
        return modifiers;
    }
}
JAVA

cat > "$tmp/src/io/github/ibuildthecloud/gdapi/model/Schema.java" <<'JAVA'
package io.github.ibuildthecloud.gdapi.model;

import java.io.Serializable;
import java.util.Map;

public interface Schema extends Serializable {
    String getId();
    void setId(String id);
    Map<String, Filter> getCollectionFilters();
}
JAVA

cat > "$tmp/src/io/github/ibuildthecloud/gdapi/model/impl/SchemaImpl.java" <<'JAVA'
package io.github.ibuildthecloud.gdapi.model.impl;

import java.util.HashMap;
import java.util.Map;

import io.github.ibuildthecloud.gdapi.model.Filter;
import io.github.ibuildthecloud.gdapi.model.Schema;

public class SchemaImpl implements Schema {
    private String id;
    private Map<String, Filter> collectionFilters = new HashMap<String, Filter>();

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Map<String, Filter> getCollectionFilters() {
        return collectionFilters;
    }
}
JAVA

cat > "$tmp/src/io/github/ibuildthecloud/gdapi/model/impl/UnexpectedModel.java" <<'JAVA'
package io.github.ibuildthecloud.gdapi.model.impl;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.Serializable;

public class UnexpectedModel implements Serializable {
    private static final long serialVersionUID = 1L;
    public static boolean readObjectCalled;

    private void readObject(ObjectInputStream in)
            throws IOException, ClassNotFoundException {
        readObjectCalled = true;
        in.defaultReadObject();
    }
}
JAVA

cp "$expected_patch" "$tmp/src/PatchV1GlobalSubscribe.java"

cat > "$tmp/src/TestPatchV1GlobalSubscribe.java" <<'JAVA'
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import io.github.ibuildthecloud.gdapi.model.Filter;
import io.github.ibuildthecloud.gdapi.model.Schema;
import io.github.ibuildthecloud.gdapi.model.impl.SchemaImpl;
import io.github.ibuildthecloud.gdapi.model.impl.UnexpectedModel;

public class TestPatchV1GlobalSubscribe {
    private static boolean forbiddenReadObjectCalled;

    private static final class ForbiddenPayload implements Serializable {
        private static final long serialVersionUID = 1L;

        private void readObject(ObjectInputStream in)
                throws IOException, ClassNotFoundException {
            forbiddenReadObjectCalled = true;
            in.defaultReadObject();
        }
    }

    private static Schema schema(String id) {
        Schema schema = new SchemaImpl();
        schema.setId(id);
        return schema;
    }

    private static Schema filteredSchema(String id) {
        Schema schema = schema(id);
        schema.getCollectionFilters().put(
                "accountId", new Filter(Arrays.asList("eq")));
        return schema;
    }

    private static void writeRole(String name, String... types) throws Exception {
        List<Schema> schemas = new ArrayList<Schema>();
        for (String type : types) {
            schemas.add(filteredSchema(type));
        }
        PatchV1GlobalSubscribe.write("schema/v1/" + name, schemas);
    }

    private static void writeRaw(String file, Object value) throws Exception {
        try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(file))) {
            out.writeObject(value);
        }
    }

    public static void main(String[] args) throws Exception {
        new java.io.File("schema/v1").mkdirs();

        List<Schema> project = new ArrayList<Schema>();
        project.add(schema("subscribe"));
        project.add(filteredSchema("mfaFactor"));
        project.add(filteredSchema("mfaStatus"));
        PatchV1GlobalSubscribe.write("schema/v1/project.ser", project);

        List<Schema> admin = new ArrayList<Schema>();
        admin.add(schema("alpha"));
        admin.add(filteredSchema("authIdentityLink"));
        admin.add(filteredSchema("mfaFactor"));
        admin.add(filteredSchema("mfaStatus"));
        PatchV1GlobalSubscribe.write("schema/v1/admin.ser", admin);

        List<Schema> service = new ArrayList<Schema>();
        service.add(filteredSchema("authIdentityLink"));
        service.add(filteredSchema("mfaFactor"));
        service.add(filteredSchema("mfaStatus"));
        PatchV1GlobalSubscribe.write("schema/v1/service.ser", service);

        writeRole("base.ser", "authIdentityLink", "mfaFactor", "mfaStatus");
        writeRole("member.ser", "mfaFactor", "mfaStatus");
        writeRole("owner.ser", "mfaFactor", "mfaStatus");
        writeRole("projectadmin.ser", "mfaFactor", "mfaStatus");
        writeRole("readAdmin.ser", "authIdentityLink", "mfaFactor", "mfaStatus");
        writeRole("readonly.ser", "mfaFactor", "mfaStatus");
        writeRole("restricted.ser", "mfaFactor", "mfaStatus");
        writeRole("superadmin.ser", "authIdentityLink", "mfaFactor", "mfaStatus");
        writeRole("user.ser", "mfaFactor", "mfaStatus");

        PatchV1GlobalSubscribe.main(new String[0]);
        PatchV1GlobalSubscribe.main(new String[]{"verify"});

        if (PatchV1GlobalSubscribe.find(PatchV1GlobalSubscribe.read("schema/v1/admin.ser"), "subscribe") == null) {
            throw new IllegalStateException("admin subscribe patch missing");
        }
        if (PatchV1GlobalSubscribe.find(PatchV1GlobalSubscribe.read("schema/v1/service.ser"), "subscribe") == null) {
            throw new IllegalStateException("service subscribe patch missing");
        }

        List<Object> invalid = new ArrayList<Object>();
        invalid.add("not-a-schema");
        writeRaw("schema/v1/invalid.ser", invalid);
        try {
            PatchV1GlobalSubscribe.read("schema/v1/invalid.ser");
            throw new IllegalStateException("invalid schema payload was accepted");
        } catch (IllegalStateException expected) {
            // Expected: read() must reject erased non-Schema payloads without unchecked casts.
        }

        writeRaw("schema/v1/forbidden.ser", new ForbiddenPayload());
        try {
            PatchV1GlobalSubscribe.read("schema/v1/forbidden.ser");
            throw new IllegalStateException("forbidden serialized class was accepted");
        } catch (java.io.InvalidClassException expected) {
            // Expected: the allowlist rejects the class before its readObject hook runs.
        }
        if (forbiddenReadObjectCalled) {
            throw new IllegalStateException("forbidden readObject hook was executed");
        }

        writeRaw("schema/v1/unexpected-model.ser", new UnexpectedModel());
        try {
            PatchV1GlobalSubscribe.read("schema/v1/unexpected-model.ser");
            throw new IllegalStateException("unexpected model class was accepted");
        } catch (java.io.InvalidClassException expected) {
            // Exact class acceptance must reject new classes even inside an allowed model package.
        }
        if (UnexpectedModel.readObjectCalled) {
            throw new IllegalStateException("unexpected model readObject hook was executed");
        }

        try {
            PatchV1GlobalSubscribe.read("schema/outside.ser");
            throw new IllegalStateException("schema path outside schema/v1 was accepted");
        } catch (IllegalArgumentException expected) {
            // Expected: only the fixed build-time schema directory is readable.
        }
    }
}
JAVA

run_checks() {
  local javac_cmd=$1
  local javap_cmd=$2
  local java_cmd=$3
  local cp_separator=$4

  "$javac_cmd" -Xlint:deprecation -Werror -cp lib/commons-io.jar -d classes \
    src/io/github/ibuildthecloud/gdapi/model/Filter.java \
    src/io/github/ibuildthecloud/gdapi/model/Schema.java \
    src/io/github/ibuildthecloud/gdapi/model/impl/SchemaImpl.java \
    src/io/github/ibuildthecloud/gdapi/model/impl/UnexpectedModel.java \
    src/PatchV1GlobalSubscribe.java \
    src/TestPatchV1GlobalSubscribe.java
  "$javap_cmd" -verbose classes/PatchV1GlobalSubscribe.class | grep -q "major version: 69"
  "$java_cmd" -cp "classes${cp_separator}lib/commons-io.jar" TestPatchV1GlobalSubscribe
}

if [ -n "$jdk_home" ]; then
  (
    cd "$tmp"
    run_checks "$javac_bin" "$javap_bin" "$java_bin" "$classpath_separator"
  )
else
  docker run --rm \
    --network host \
    -u "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$tmp":/work \
    -w /work \
    "$image" \
    bash -lc '
    set -euo pipefail
    javac -version
    javac -Xlint:deprecation -Werror -cp lib/commons-io.jar -d classes \
      src/io/github/ibuildthecloud/gdapi/model/Filter.java \
      src/io/github/ibuildthecloud/gdapi/model/Schema.java \
      src/io/github/ibuildthecloud/gdapi/model/impl/SchemaImpl.java \
      src/io/github/ibuildthecloud/gdapi/model/impl/UnexpectedModel.java \
      src/PatchV1GlobalSubscribe.java \
      src/TestPatchV1GlobalSubscribe.java
    javap -verbose classes/PatchV1GlobalSubscribe.class | grep -q "major version: 69"
    java -cp "classes:lib/commons-io.jar" TestPatchV1GlobalSubscribe
  '
fi

echo "SERVER_JAVA_PATCH_JDK25_OK file=$expected_patch image=$image jdk_home=${jdk_home:-container} commons_io=$commons_io_version class_major=69 suppresswarnings=0 runtime_smoke=1"
echo "failure_count=0"
