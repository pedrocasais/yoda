
# Tools

Utility scripts and generators used by this repository.

## Prerequisites

- `python3`
- `dune` (for OCaml generators)
- `jsonschema2atd` (for OpenAPI JSON -> ATD conversion)

## Available Commands

### Run OCaml tooling

From the repository root:

```bash
make atd-to-dream
```

This runs:
- `dune exec tools/generator.exe`

### Convert OpenAPI YAML to OpenAPI JSON

From the repository root:

```bash
make openapi-yaml-to-json
```

Equivalent direct script:

```bash
./tools/convert-openapi/run.sh
```

What it does:
- Creates a temporary Python virtual environment.
- Installs `prance[osv]`.
- Runs `tools/convert-openapi/convert.py`.
- Runs `tools/convert-openapi/schemas.py`.
- Writes OpenAPI JSON to `schemas/json/openapi.json`.

### Convert OpenAPI JSON to ATD

From the repository root:

```bash
make openapi-json-to-atd
```

This writes:
- `schemas/atd/openapi.atd`

### Run the full OpenAPI pipeline

From the repository root:

```bash
make openapi-all
```

This runs:
- `make openapi-yaml-to-json`
- `make openapi-json-to-atd`

## Notes

- Inline request/response schemas are extracted into `components.schemas` and replaced with `$ref` entries in generated OpenAPI JSON.
- Generated JSON is written with indentation for readability.

