#!/usr/bin/env bash
# Rebuild the shop models from Tools/assetgen, or prove the shipped copies match.
set -euo pipefail
cd "$(dirname "$0")/.."

missing() {
  printf 'models.sh: %s missing — implement the 3D store card (plans/2026-10-17-3d-store-and-surroundings.md) first\n' "$1"
  exit 2
}

[[ -f docs/asset-brief.md ]] || missing docs/asset-brief.md
[[ -f Packages/StoreSimKit/Sources/StoreSimKit/Assets/AssetName.swift ]] || missing Packages/StoreSimKit/Sources/StoreSimKit/Assets/AssetName.swift
[[ -f Packages/StoreSimKit/Sources/StoreSimKit/Assets/AssetCatalogue.swift ]] || missing Packages/StoreSimKit/Sources/StoreSimKit/Assets/AssetCatalogue.swift
[[ -d App/Resources/Models ]] || missing App/Resources/Models

check=0
only=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) check=1; shift ;;
    --only)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        only+=("$1")
        shift
      done
      ;;
    *)
      echo "models.sh: unknown argument $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -d .venv-assetgen ]]; then
  python3 -m venv .venv-assetgen
fi

target="App/Resources/Models"
cleanup=""
if [[ "$check" -eq 1 ]]; then
  target="$(mktemp -d "${TMPDIR:-/tmp}/models-check.XXXXXX")"
  cleanup="$target"
fi

generate_cmd=(.venv-assetgen/bin/python Tools/assetgen/generate.py
  --brief docs/asset-brief.md
  --brand Packages/StoreSimKit/Sources/StoreSimKit/Brand/Brand.swift
  --out "$target")
check_cmd=(.venv-assetgen/bin/python Tools/assetgen/check.py
  --brief docs/asset-brief.md
  --models "$target"
  --shipped App/Resources/Models)
if [[ ${#only[@]} -gt 0 ]]; then
  generate_cmd+=(--only "${only[@]}")
  check_cmd+=(--only "${only[@]}")
fi

PIP_DISABLE_PIP_VERSION_CHECK=1 .venv-assetgen/bin/pip install --require-hashes -q -r Tools/assetgen/requirements.txt

"${generate_cmd[@]}"

if command -v usdchecker >/dev/null 2>&1; then
  shopt -s nullglob
  for model in "$target"/*.usdz; do
    usdchecker --arkit "$model"
  done
else
  echo "skip: usdchecker not on PATH"
fi

"${check_cmd[@]}"

if [[ "$check" -eq 1 ]]; then
  differ=0
  shopt -s nullglob
  for generated in "$target"/*; do
    base="$(basename "$generated")"
    [[ "$base" == "README.md" ]] && continue
    shipped="App/Resources/Models/$base"
    if [[ ! -f "$shipped" ]] || ! cmp -s "$generated" "$shipped"; then
      echo "differs: $base"
      differ=1
    fi
  done
  if [[ "$differ" -eq 1 ]]; then
    [[ -n "$cleanup" ]] && rm -rf "$cleanup"
    exit 1
  fi
fi

[[ -n "$cleanup" ]] && rm -rf "$cleanup"

if [[ ${#only[@]} -eq 0 ]]; then
  echo "29 assets generated, 24 models checked, 5 sourced"
fi
