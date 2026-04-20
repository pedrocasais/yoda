#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
venv_dir="$(mktemp -d "${TMPDIR:-/tmp}/yoda-openapi-venv.XXXXXX")"

cleanup() {
  rm -rf "$venv_dir"
}
trap cleanup EXIT

cd "$repo_root"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but was not found in PATH" >&2
  exit 1
fi

python3 -m venv "$venv_dir"

source "$venv_dir/bin/activate"

python -m pip install --upgrade pip
python -m pip install 'prance[osv]'

python convert-openapi/convert.py

python convert-openapi/schemas.py