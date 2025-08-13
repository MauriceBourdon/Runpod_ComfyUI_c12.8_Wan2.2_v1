#!/usr/bin/env bash
set -euo pipefail
dl() {
  local url="$1" dst="$2"
  echo "[dl] $url -> $dst"
  mkdir -p "$(dirname "$dst")"
  aria2c -x 8 -s 8 -k 1M --file-allocation=none -o "$(basename "$dst")" -d "$(dirname "$dst")" "$url"
}
hf_resolve() { local repo="$1" path="$2"; echo "https://huggingface.co/${repo}/resolve/main/${path}"; }
hf_dl() {
  local repo="$1" path="$2" dst="$3"
  mkdir -p "$(dirname "$dst")"
  local url=$(hf_resolve "$repo" "$path")
  if [ -n "${HF_TOKEN:-}" ]; then
    echo "[hf] auth GET ${repo} :: ${path}"
    curl -L -H "Authorization: Bearer ${HF_TOKEN}" "$url" -o "$dst"
  else
    echo "[hf] GET ${repo} :: ${path}"
    curl -L "$url" -o "$dst"
  fi
}
git_clone_or_update() {
  local repo="$1" dst="$2" ref="${3:-}"
  if [ -d "$dst/.git" ]; then
    git -C "$dst" fetch --all --tags
    [ -n "$ref" ] && git -C "$dst" checkout "$ref"
    git -C "$dst" pull --ff-only || true
  else
    git clone --depth=1 "$repo" "$dst"
    [ -n "$ref" ] && git -C "$dst" checkout "$ref" || true
  fi
}
