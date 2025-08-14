#!/usr/bin/env bash
set -euo pipefail
manifest="${1:-}"
custom_dir="${COMFY_DIR:-/opt/ComfyUI}/custom_nodes"

if [[ -z "${manifest}" || ! -f "${manifest}" ]]; then
  echo "No nodes manifest provided or file not found: ${manifest}"; exit 0
fi

mkdir -p "${custom_dir}"
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  [[ "$repo" =~ ^# ]] && continue
  name=$(basename "$repo")
  dest="${custom_dir}/${name}"
  if [[ -d "$dest/.git" ]]; then
    echo "[nodes] update $name"
    git -C "$dest" pull --ff-only || true
  else
    echo "[nodes] clone $repo"
    git clone --depth=1 "$repo" "$dest" || true
  fi
  if [[ -f "$dest/requirements.txt" ]]; then
    /venv/bin/pip install -r "$dest/requirements.txt" || true
  fi
done < "${manifest}"
