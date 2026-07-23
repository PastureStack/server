import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import io.github.ibuildthecloud.gdapi.model.Schema;

public class PatchV1GlobalSubscribe {
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
        Schema subscribe = find(read("schema/v1/project.ser"), "subscribe");
        if (subscribe == null) {
            throw new IllegalStateException("project schema has no subscribe");
        }
        patch("admin", subscribe);
        patch("service", subscribe);
    }
}
