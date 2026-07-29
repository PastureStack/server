import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.github.ibuildthecloud.gdapi.model.Filter;
import io.github.ibuildthecloud.gdapi.model.Schema;

public class PatchV1GlobalSubscribe {
    private static final Set<String> ADMIN_TYPES = set(
            "authIdentityLink", "mfaFactor", "mfaStatus");
    private static final Set<String> USER_TYPES = set("mfaFactor", "mfaStatus");

    static List<Schema> read(String file) throws Exception {
        try (ObjectInputStream in = new ObjectInputStream(new FileInputStream(file))) {
            Object value = in.readObject();
            if (!(value instanceof List<?>)) {
                throw new IllegalStateException(file + " did not contain a schema list");
            }

            List<?> values = (List<?>) value;
            List<Schema> schemas = new ArrayList<Schema>(values.size());
            for (Object item : values) {
                if (!(item instanceof Schema)) {
                    throw new IllegalStateException(file + " contained a non-schema entry");
                }
                schemas.add((Schema) item);
            }
            return schemas;
        }
    }

    static void write(String file, List<Schema> schemas) throws Exception {
        try (ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream(file))) {
            out.writeObject(schemas);
        }
    }

    static Schema find(List<Schema> schemas, String id) {
        for (Schema schema : schemas) {
            if (id.equals(schema.getId())) {
                return schema;
            }
        }
        return null;
    }

    static void patch(String target, Schema subscribe) throws Exception {
        String path = "schema/v1/" + target + ".ser";
        List<Schema> schemas = read(path);
        if (find(schemas, "subscribe") != null) {
            System.out.println(target + " already has subscribe");
            return;
        }

        schemas.add(subscribe);
        Collections.sort(schemas, new Comparator<Schema>() {
            public int compare(Schema a, Schema b) {
                return a.getId().compareTo(b.getId());
            }
        });
        write(path, schemas);
        System.out.println("added subscribe to " + target);
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 1 && "verify".equals(args[0])) {
            verifyIdentitySecuritySchemas();
            return;
        }
        if (args.length != 0) {
            throw new IllegalArgumentException("Expected no arguments or verify");
        }

        Schema subscribe = find(read("schema/v1/project.ser"), "subscribe");
        if (subscribe == null) {
            throw new IllegalStateException("project schema has no subscribe");
        }
        patch("admin", subscribe);
        patch("service", subscribe);
    }

    static void verifyIdentitySecuritySchemas() throws Exception {
        Map<String, Set<String>> expected = new HashMap<String, Set<String>>();
        expected.put("admin.ser", ADMIN_TYPES);
        expected.put("base.ser", ADMIN_TYPES);
        expected.put("member.ser", USER_TYPES);
        expected.put("owner.ser", USER_TYPES);
        expected.put("project.ser", USER_TYPES);
        expected.put("projectadmin.ser", USER_TYPES);
        expected.put("readAdmin.ser", ADMIN_TYPES);
        expected.put("readonly.ser", USER_TYPES);
        expected.put("restricted.ser", USER_TYPES);
        expected.put("service.ser", ADMIN_TYPES);
        expected.put("superadmin.ser", ADMIN_TYPES);
        expected.put("user.ser", USER_TYPES);

        for (Map.Entry<String, Set<String>> entry : expected.entrySet()) {
            verify("schema/v1/" + entry.getKey(), entry.getValue());
        }
        System.out.println("FROZEN_IDENTITY_SECURITY_SCHEMAS_OK roles=" + expected.size());
    }

    private static void verify(String file, Set<String> expected) throws Exception {
        Set<String> found = new HashSet<String>();
        for (Schema schema : read(file)) {
            if (!ADMIN_TYPES.contains(schema.getId())) {
                continue;
            }

            Map<String, Filter> filters = schema.getCollectionFilters();
            Filter accountId = filters == null ? null : filters.get("accountId");
            if (accountId == null || accountId.getModifiers() == null
                    || !accountId.getModifiers().contains("eq")) {
                throw new IllegalStateException(
                        file + " " + schema.getId() + " lacks accountId eq");
            }
            found.add(schema.getId());
        }

        if (!expected.equals(found)) {
            throw new IllegalStateException(
                    file + " identity-security types " + found + " != " + expected);
        }
    }

    private static Set<String> set(String... values) {
        return new HashSet<String>(Arrays.asList(values));
    }
}
