#!/usr/bin/env bash

set -euo pipefail

cd /workspaces/yoda

# Ensure system dependency required by conf-libffi is present.
if ! dpkg -s libffi-dev >/dev/null 2>&1; then
	if command -v sudo >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y libffi-dev
	else
		apt-get update
		apt-get install -y libffi-dev
	fi
fi

opam update

# Pin the atdgen packages to the latest version in the ahrefs/atd repository, which includes support for OCaml 5.0.
opam pin add -y atdgen-runtime.dev https://github.com/ahrefs/atd.git
opam pin add -y atd.dev https://github.com/ahrefs/atd.git
opam pin add -y atdgen.dev https://github.com/ahrefs/atd.git
opam pin add -y docker-api.dev https://github.com/pedrodamiao18/ocaml-docker-api.git

opam install -y . --deps-only
opam install -y jsonschema2atd

opam install -y ocamlformat merlin ocamlformat-rpc ocaml-lsp-server
