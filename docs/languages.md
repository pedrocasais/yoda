# Supporting new languages

YodaC compiles and runs each submission inside a container. A language is therefore just a configuration entry that tells YodaC which container image to use and which commands to run. Adding a language does not require changing or rebuilding Yoda.

## Language entry

Each entry has the following fields:

| Field | Required | Description |
|-------|----------|-------------|
| `language` | yes | Unique name that submissions use to select the language. |
| `ext` | yes | Source file extension, without the dot. A single-file submission must have a filename with this extension and is saved as `main.<ext>`. |
| `image` | yes | Container image used to compile and run the code. |
| `tag` | yes | Image tag. |
| `compile` | no | Command that compiles the code. Omit it for interpreted languages. |
| `run` | yes | Command that runs the program. Each test case's input is sent to its standard input. |

A language configuration is a JSON array of entries:

```json
[
  {
    "language": "c",
    "ext": "c",
    "image": "gcc",
    "tag": "latest",
    "compile": "gcc -o /work/main /work/main.c -lm",
    "run": "/work/main"
  },
  {
    "language": "cpp",
    "ext": "cpp",
    "image": "gcc",
    "tag": "latest",
    "compile": "gcc -o /work/main /work/main.cpp",
    "run": "/work/main"
  },
  {
    "language": "ocaml",
    "ext": "ml",
    "image": "ocaml/opam",
    "tag": "debian-12-ocaml-5.2",
    "compile": "opam exec -- ocamlc -o main main.ml",
    "run": "/work/main"
  },
  {
    "language": "java",
    "ext": "java",
    "image": "eclipse-temurin",
    "tag": "21",
    "compile": "javac -d /work /work/Main.java",
    "run": "java -cp /work Main"
  },
  {
    "language": "python",
    "ext": "py",
    "image": "python",
    "tag": "3.12-slim",
    "run": "python3 /work/main.py"
  },
  {
    "language": "javascript",
    "ext": "js",
    "image": "node",
    "tag": "22-slim",
    "run": "node /work/main.js"
  },
  {
    "language": "bypass-yml",
    "ext": "yml",
    "image": "python",
    "tag": "3.12-slim",
    "run": "cat /work/main.yml"
  },
  {
    "language": "ocaml-5.2-yojson",
    "ext": "ml",
    "image": "yodac.azurecr.io/yoda-images/ocaml-5.2-yojson",
    "tag": "latest",
    "compile": "opam exec -- ocamlfind ocamlopt -package yojson,ppx_deriving_yojson -linkpkg -o main main.ml",
    "run": "/work/main"
  },
  {
    "language": "python-3.12-slim-lark",
    "ext": "py",
    "image": "yodac.azurecr.io/yoda-images/python-3.12-slim-lark",
    "tag": "latest",
    "run": "python /work/main.py"
  }
]
```

The last two entries show how to offer a language with extra libraries: build an image containing them, publish it to a registry that YodaC can pull from, and reference it as the `image`.

## How commands are executed

- The submission's working directory is mounted at `/work` in the container, and commands start in `/work`.
- Commands run through `bash -c`, so shell syntax is available.
- Compilation runs with networking disabled and a 60-second timeout.
- The `compile` command must produce whatever the `run` command needs. Use absolute `/work/...` paths for the source and output files to avoid depending on the working directory.
- A non-zero exit status from `compile` is reported as a compilation error, and the test cases are not run.
- The `run` command is executed once per test case, with the test case input provided on standard input.
- The image must be available to YodaC. YodaC pulls it automatically when it is first used, so the container engine needs access to the registry.

## Adding a language

1. Choose or build a container image that has the compiler or interpreter you need.
2. Test the commands locally, with a source file mounted at `/work`:

   ```bash
   docker run --rm -v "$PWD:/work" -w /work <image>:<tag> bash -c "<compile command>"
   docker run --rm -i -v "$PWD:/work" -w /work <image>:<tag> bash -c "<run command>" < input.txt
   ```

   Use `podman` in place of `docker` if you prefer.
3. Add the entry to the configuration, as described below.
4. Create a test submission in the new language and check its results.

## Applying the configuration

### Default configuration

[`languages.yaml`](../languages.yaml) holds the default languages. YodaC reads it, or the file named by the `YODAC_LANG_CONFIG` environment variable, and seeds Valkey with its contents the first time it starts with an empty database. It is not read again once the configuration exists in Valkey, so editing it later has no effect on a running installation. Use it to change the defaults for new installations. It maps each language name to its settings:

```yaml
rust:
  ext: rs
  image: rust
  tag: "1.80"
  compile: rustc -o /work/main /work/main.rs
  run: /work/main
```

### Updating a running installation

Administrators change the active configuration through the API. YodaC reloads it before processing the next submission, with no restart needed.

1. Read the current configuration with `GET /admin/yodac/config` and copy the `config` array.
2. Add the new entry to the array.
3. Send the complete array back with `PUT /admin/yodac/config`:

   ```json
   {
     "config": [
       {
         "language": "rust",
         "ext": "rs",
         "image": "rust",
         "tag": "1.80",
         "compile": "rustc -o /work/main /work/main.rs",
         "run": "/work/main"
       }
     ]
   }
   ```

   The request replaces the whole configuration, so include every language that should stay available, not only the new one.

Requests fail with `400` if a language name is empty or duplicated, or if the configuration is identical to the current one. Each successful update increments the configuration `version` and is recorded in the history returned by `GET /admin/yodac/config/history`, which also lets you check what changed and who made the change.

See the [OpenAPI specification](../schemas/openapi.yaml) for the complete request and response formats.
