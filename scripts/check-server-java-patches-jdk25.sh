#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

expected_patch="server/patches/PatchV1GlobalSubscribe.java"
image="${RC16_JDK25_CHECK_IMAGE:-eclipse-temurin:25-jdk}"
failures=0

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

if ! command -v docker >/dev/null 2>&1; then
  echo "DOCKER_MISSING"
  failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
  echo "failure_count=$failures"
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src/io/github/ibuildthecloud/gdapi/model" "$tmp/classes"

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
import java.util.HashMap;
import java.util.Map;

public class Schema implements Serializable {
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

cp "$expected_patch" "$tmp/src/PatchV1GlobalSubscribe.java"

cat > "$tmp/src/TestPatchV1GlobalSubscribe.java" <<'JAVA'
import java.io.FileOutputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import io.github.ibuildthecloud.gdapi.model.Filter;
import io.github.ibuildthecloud.gdapi.model.Schema;

public class TestPatchV1GlobalSubscribe {
    private static Schema schema(String id) {
        Schema schema = new Schema();
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
    }
}
JAVA

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
    javac -Xlint:deprecation -Werror -d classes \
      src/io/github/ibuildthecloud/gdapi/model/Filter.java \
      src/io/github/ibuildthecloud/gdapi/model/Schema.java \
      src/PatchV1GlobalSubscribe.java \
      src/TestPatchV1GlobalSubscribe.java
    javap -verbose classes/PatchV1GlobalSubscribe.class | grep -q "major version: 69"
    java -cp classes TestPatchV1GlobalSubscribe
  '

echo "SERVER_JAVA_PATCH_JDK25_OK file=$expected_patch image=$image class_major=69 suppresswarnings=0 runtime_smoke=1"
echo "failure_count=0"
