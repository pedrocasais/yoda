#!/bin/sh
set -eu

out_file=${1:-build_info.ml}

escape_ocaml() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

api_version='1.0'
openapi_path=''
if [ -f ../schemas/openapi.yaml ]; then
  openapi_path='../schemas/openapi.yaml'
elif [ -f schemas/openapi.yaml ]; then
  openapi_path='schemas/openapi.yaml'
fi

if [ -n "$openapi_path" ]; then
  raw_version=$(sed -n 's/^[[:space:]]*version:[[:space:]]*//p' "$openapi_path" | head -n 1)
  if [ -n "$raw_version" ]; then
    api_version=$(printf '%s' "$raw_version" \
      | sed -e 's/"//g' -e "s/'//g" -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
  fi
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  short=$(git rev-parse --short HEAD 2>/dev/null || true)
  if [ -n "$short" ]; then
    dirty=$(git status --porcelain 2>/dev/null || true)
    if [ -n "$dirty" ]; then
      yoda_version="dirty-$short"
    else
      yoda_version="sha-$short"
    fi
  else
    yoda_version='sha-unknown'
  fi

  contributors=$(git log --format=%aN 2>/dev/null \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | awk 'NF' \
    | sort -u)
else
  yoda_version='sha-unknown'
  contributors=''
fi

api_version_escaped=$(escape_ocaml "$api_version")
yoda_version_escaped=$(escape_ocaml "$yoda_version")

{
  printf 'let api_version = "%s"\n' "$api_version_escaped"
  printf 'let yoda_version = "%s"\n\n' "$yoda_version_escaped"
  printf 'let contributors = [\n'
  if [ -n "$contributors" ]; then
    printf '%s\n' "$contributors" | while IFS= read -r name; do
      escaped=$(escape_ocaml "$name")
      printf '  "%s";\n' "$escaped"
    done
  else
    printf '  "unknown";\n'
  fi
  printf ']\n'
} > "$out_file"
