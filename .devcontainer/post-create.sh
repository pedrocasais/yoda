#!/usr/bin/env bash

set -euo pipefail

cd /workspaces/yoda

opam update
opam install -y . --deps-only

# Pin the atdgen packages to the latest version in the ahrefs/atd repository, which includes support for OCaml 5.0.
opam pin add atdgen-runtime.dev https://github.com/ahrefs/atd.git
opam pin add atdgen.dev https://github.com/ahrefs/atd.git
opam pin add https://github.com/pedrodamiao18/ocaml-docker-api.git
opam install jsonschema2atd

opam install ocamlformat ocaml-lsp-server
