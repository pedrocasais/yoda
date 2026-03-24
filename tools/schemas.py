import yaml
import json
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE = os.path.join(BASE_DIR, "..", "schemas", "api.yaml")
OUTPUT_DIR = os.path.join(BASE_DIR, "..", "schemas")

os.makedirs(OUTPUT_DIR, exist_ok=True)

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

schemas = data.get("components", {}).get("schemas", {})

for name, schema in schemas.items():
    output_path = os.path.join(OUTPUT_DIR, f"{name}.json")

    # adicionar $schema no topo
    schema_with_meta = {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        **schema
    }

    with open(output_path, "w", encoding="utf-8") as out:
        json.dump(schema_with_meta, out, indent=2)

    print(f"Gerado: {output_path}")

print("Todos os schemas foram convertidos com $schema.")