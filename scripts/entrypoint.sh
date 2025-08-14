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

# --- Torch + HF stack install at runtime if missing ---
if ! /venv/bin/python -c "import torch" >/dev/null 2>&1; then
  log "[torch] not found → installing CUDA wheels (or CPU fallback) ..."
  if ! /venv/bin/pip install --no-cache-dir \
        --index-url "${TORCH_INDEX_URL:-https://download.pytorch.org/whl/cu128}" \
        "${TORCH_SPEC_TORCH:-torch}" "${TORCH_SPEC_VISION:-torchvision}" "${TORCH_SPEC_AUDIO:-torchaudio}"; then
    log "[torch] CUDA wheels unavailable → CPU fallback"
    /venv/bin/pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
      torch torchvision torchaudio
  fi
fi

# Ensure protobuf<5 for HF
/venv/bin/pip show protobuf >/dev/null 2>&1 || /venv/bin/pip install --no-cache-dir "protobuf<5,>=3.20.3"

# Install HF stack if missing (post-Torch)
/venv/bin/pip install --no-cache-dir \
  huggingface-hub==0.24.6 safetensors==0.4.5 ftfy==6.3.1 pyloudnorm==0.1.1 \
  diffusers==0.34.0 accelerate==1.10.0 transformers==4.44.2 \
  timm==1.0.9 peft==0.17.0 einops==0.8.0 \
  sentencepiece==0.2.0 opencv-python==4.10.0.84 imageio-ffmpeg==0.4.9 aiohttp==3.9.5 gguf==0.17.1 || true

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
