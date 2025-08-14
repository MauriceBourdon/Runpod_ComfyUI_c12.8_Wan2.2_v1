#!/usr/bin/env bash
set -euo pipefail

src="${COMFY_WORKFLOWS_SRC:-/workspace/workflows}"
dst="${COMFY_DIR:-/opt/ComfyUI}/user/default/workflows"
mode="${COMFY_WORKFLOWS_MODE:-symlink}"

mkdir -p "${src}" "${dst}"

if [[ -n "${WORKFLOWS_MANIFEST:-}" && -f "${WORKFLOWS_MANIFEST}" ]]; then
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    [[ "$url" =~ ^# ]] && continue
    fname=$(basename "$url")
    echo "[workflows] fetch $fname"
    curl -fsSL "$url" -o "${src}/${fname}" || true
  done
fi

if [[ "${mode}" == "symlink" ]]; then
  for f in "${src}"/*.json; do
    [[ -e "$f" ]] || continue
    ln -sf "$f" "${dst}/$(basename "$f")"
  done
else
  rsync -a --delete "${src}/" "${dst}/"
fi
