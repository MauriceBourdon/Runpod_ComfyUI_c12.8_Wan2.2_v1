#!/usr/bin/env bash
set -euo pipefail
source /scripts/util.sh
COMFY_DIR="${COMFY_DIR:-/opt/ComfyUI}"
NODES_DIR="${COMFY_DIR}/custom_nodes"
if [ "${COMFY_MANAGER_ENABLE:-true}" = "true" ]; then
  echo "[nodes] Installing ComfyUI-Manager"
  git_clone_or_update "${COMFY_MANAGER_REPO:-https://github.com/Comfy-Org/ComfyUI-Manager}" "${NODES_DIR}/ComfyUI-Manager" "${COMFY_MANAGER_REF:-}"
  if [ -f "${NODES_DIR}/ComfyUI-Manager/requirements.txt" ]; then pip install -r "${NODES_DIR}/ComfyUI-Manager/requirements.txt" || true; fi
fi
KIJAI_WAN_REPO="${KIJAI_WAN_REPO:-https://github.com/kijai/ComfyUI-WanVideoWrapper}"
KIJAI_WAN_REF="${KIJAI_WAN_REF:-}"
echo "[nodes] Installing Kijai ComfyUI-WanVideoWrapper"
git_clone_or_update "${KIJAI_WAN_REPO}" "${NODES_DIR}/ComfyUI-WanVideoWrapper" "${KIJAI_WAN_REF}"
if [ -f "${NODES_DIR}/ComfyUI-WanVideoWrapper/requirements.txt"] ; then pip install -r "${NODES_DIR}/ComfyUI-WanVideoWrapper/requirements.txt" || true; fi
VHS_REPO="${VHS_REPO:-https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite}"
echo "[nodes] Installing VideoHelperSuite -> ${VHS_REPO}"
git_clone_or_update "${VHS_REPO}" "${NODES_DIR}/ComfyUI-VideoHelperSuite" ""
if [ -f "${NODES_DIR}/ComfyUI-VideoHelperSuite/requirements.txt" ]; then pip install -r "${NODES_DIR}/ComfyUI-VideoHelperSuite/requirements.txt" || true; else pip install opencv-python imageio-ffmpeg || true; fi
if [ "${WAN_USE_SAGE_ATTN:-true}" = "true" ]; then
  echo "[opt] Ensuring SageAttention present (runtime fallback)"
  pip show sageattention >/dev/null 2>&1 || pip show sage-attention >/dev/null 2>&1 || (pip install --no-cache-dir sageattention || pip install --no-cache-dir sage-attention || true)
fi
