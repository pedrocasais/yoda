import yaml
import json
import os

# Resolve paths relative to this script so execution works from any cwd.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ficheiro OpenAPI
INPUT_FILE = os.path.join(BASE_DIR, "..", "schemas", "api.yaml")

# pasta onde os json vão ser criados
OUTPUT_DIR = os.path.join(BASE_DIR, "..", "schemas")

os.makedirs(OUTPUT_DIR, exist_ok=True)

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

schemas = data.get("components", {}).get("schemas", {})

for name, schema in schemas.items():
    output_path = os.path.join(OUTPUT_DIR, f"{name}.json")

    with open(output_path, "w", encoding="utf-8") as out:
        json.dump(schema, out, indent=2)

    print(f"Gerado: {output_path}")

print("Todos os schemas foram convertidos para JSON.")