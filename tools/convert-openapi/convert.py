import json
import re
from pathlib import Path

from prance import BaseParser


HTTP_METHODS = {"get", "post", "put", "patch", "delete", "options", "head", "trace"}


def sanitize_part(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value)
    return "".join(part.capitalize() for part in parts if part)


def component_name_for_request(path: str, method: str, media_type: str) -> str:
    return f"{sanitize_part(path)}{method.capitalize()}Request"


def component_name_for_response(path: str, method: str, status_code: str, media_type: str) -> str:
    return (
        f"{sanitize_part(path)}{method.capitalize()}Response{status_code}"
    )


def schema_ref(component_name: str) -> dict:
    return {"$ref": f"#/components/schemas/{component_name}"}


def extract_inline_schemas(specification: dict) -> None:
    components = specification.setdefault("components", {})
    schemas = components.setdefault("schemas", {})

    paths = specification.get("paths", {})
    for path, path_item in paths.items():
        if not isinstance(path_item, dict):
            continue

        for method, operation in path_item.items():
            print(f"Processing {method.upper()} {path}")
            if method not in HTTP_METHODS or not isinstance(operation, dict):
                continue

            request_body = operation.get("requestBody", {})
            request_content = request_body.get("content", {})
            for media_type, media in request_content.items():
                schema = media.get("schema")
                if not isinstance(schema, dict) or "$ref" in schema:
                    continue

                component_name = component_name_for_request(path, method, media_type)
                schemas.setdefault(component_name, schema)
                media["schema"] = schema_ref(component_name)

            responses = operation.get("responses", {})
            for status_code, response in responses.items():
                print(f"Processing {method.upper()} {path} response {status_code}")
                if not isinstance(response, dict):
                    continue

                response_content = response.get("content", {})
                for media_type, media in response_content.items():
                    schema = media.get("schema")
                    if not isinstance(schema, dict) or "$ref" in schema:
                        continue

                    component_name = component_name_for_response(path, method, status_code, media_type)
                    schemas.setdefault(component_name, schema)
                    media["schema"] = schema_ref(component_name)


def build_schema_aliases(schemas: dict) -> dict:
    canonical_by_content = {}
    alias_to_canonical = {}

    for schema_name, schema_value in schemas.items():
        content_key = json.dumps(schema_value, sort_keys=True, separators=(",", ":"))
        canonical_name = canonical_by_content.setdefault(content_key, schema_name)
        alias_to_canonical[schema_name] = canonical_name

    return alias_to_canonical


def rewrite_refs_in_place(value, alias_to_canonical: dict) -> None:
    if isinstance(value, dict):
        ref_value = value.get("$ref")
        if isinstance(ref_value, str) and ref_value.startswith("#/components/schemas/"):
            schema_name = ref_value.rsplit("/", 1)[-1]
            canonical_name = alias_to_canonical.get(schema_name, schema_name)
            if canonical_name != schema_name:
                value["$ref"] = f"#/components/schemas/{canonical_name}"

        for child in value.values():
            rewrite_refs_in_place(child, alias_to_canonical)
    elif isinstance(value, list):
        for item in value:
            rewrite_refs_in_place(item, alias_to_canonical)


def deduplicate_component_schemas(specification: dict) -> None:
    components = specification.get("components", {})
    schemas = components.get("schemas", {})
    if not isinstance(schemas, dict) or not schemas:
        return

    alias_to_canonical = build_schema_aliases(schemas)
    rewrite_refs_in_place(specification, alias_to_canonical)

    deduped_schemas = {}
    for schema_name, schema_value in schemas.items():
        if alias_to_canonical[schema_name] == schema_name:
            deduped_schemas[schema_name] = schema_value

    components["schemas"] = deduped_schemas


repo_root = Path(__file__).resolve().parents[2]
openapi_path = repo_root / "schemas" / "openapi.yaml"
output_path = repo_root / "schemas" / "json" / "openapi.json"

parser = BaseParser(str(openapi_path))
specification = parser.specification
extract_inline_schemas(specification)
deduplicate_component_schemas(specification)

output_path.parent.mkdir(parents=True, exist_ok=True)
with output_path.open("w", encoding="utf-8") as f:
    json.dump(specification, f, indent=2)
    f.write("\n")
