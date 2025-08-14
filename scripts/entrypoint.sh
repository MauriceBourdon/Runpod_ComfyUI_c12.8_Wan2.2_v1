#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -u +'%F %T')] $*"; }

# Optional runtime update of ComfyUI
if [[ -n "${COMFY_UPDATE_AT_START:-}" && "${COMFY_UPDATE_AT_START}" == "true" && -n "${COMFY_REF_RUNTIME:-}" ]]; then
  log "Updating ComfyUI to ${COMFY_REF_RUNTIME} ..."
  git -C "${COMFY_DIR:-/opt/ComfyUI}" fetch --all --tags || true
  git -C "${COMFY_DIR:-/opt/ComfyUI}" reset --hard "${COMFY_REF_RUNTIME}" || true
fi

# Map extra models path
EXTRA_CFG="${COMFY_DIR:-/opt/ComfyUI}/extra_model_paths.yaml"
cat > "${EXTRA_CFG}" <<YAML
models_dir: ${MODELS_DIR:-/workspace/models}
YAML

# Start Jupyter (background) if requested
if [[ "${ENABLE_JUPYTER:-true}" == "true" ]]; then
  log "Launching JupyterLab on ${JUPYTER_PORT:-8888} ..."
  nohup /venv/bin/jupyter lab \
    --ServerApp.ip=0.0.0.0 \
    --ServerApp.port="${JUPYTER_PORT:-8888}" \
    --ServerApp.open_browser=False \
    --ServerApp.token="${JUPYTER_TOKEN:-}" \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.root_dir="${JUPYTER_DIR:-/workspace}" \
    --ServerApp.allow_root=True \
    > "${JUPYTER_DIR:-/workspace}"/jupyter.log 2>&1 &
fi

# --- Torch auto-install at runtime if missing ---
if ! /venv/bin/python -c "import torch" >/dev/null 2>&1; then
  log "[torch] not found → installing at runtime..."
  # Try CUDA wheels first from TORCH_INDEX_URL; else fallback to CPU wheels
  if ! /venv/bin/pip install --no-cache-dir \
        --index-url "${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu128}" \
        "${TORCH_SPEC_TORCH:-torch}" "${TORCH_SPEC_VISION:-torchvision}" "${TORCH_SPEC_AUDIO:-torchaudio}"; then
    log "[torch] CUDA wheels unavailable → falling back to CPU wheels"
    /venv/bin/pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio
  fi
else
  log "[torch] already installed."
fi

# Install custom nodes from manifest
if [[ -f "${CUSTOM_NODES_MANIFEST:-}" ]]; then
  if [[ "${NODES_INSTALL_MODE:-sync}" == "sync" ]]; then
    log "Installing custom nodes (sync) from ${CUSTOM_NODES_MANIFEST} ..."
    /scripts/install_nodes.sh "${CUSTOM_NODES_MANIFEST}"
  else
    log "Installing custom nodes (async) from ${CUSTOM_NODES_MANIFEST} ..."
    nohup /scripts/install_nodes.sh "${CUSTOM_NODES_MANIFEST}" >/workspace/nodes_install.log 2>&1 &
  fi
fi

# Manage workflows (copy/symlink + optional download from manifest)
/scripts/manage_workflows.sh

# Download models (async)
if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  log "Downloading models from ${MODELS_MANIFEST} (async) ..."
  nohup /venv/bin/python /scripts/download_models.py "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}" >/workspace/models_download.log 2>&1 &
fi

# Launch ComfyUI if requested
if [[ "${COMFY_AUTOSTART:-true}" == "true" ]]; then
  log "Starting ComfyUI ..."
  exec /usr/local/bin/start-comfyui
else
  log "COMFY_AUTOSTART=false; container is up, not launching ComfyUI."
  tail -f /dev/null
fi
