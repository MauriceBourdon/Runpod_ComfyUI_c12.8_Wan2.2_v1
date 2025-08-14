#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -u +'%F %T')] $*"; }

# Optionally update ComfyUI to a runtime ref (branch/tag/SHA)
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
  nohup /venv/bin/jupyter lab     --ServerApp.ip=0.0.0.0     --ServerApp.port="${JUPYTER_PORT:-8888}"     --ServerApp.open_browser=False     --ServerApp.token="${JUPYTER_TOKEN:-}"     --ServerApp.password=''     --ServerApp.allow_origin='*'     --ServerApp.root_dir="${JUPYTER_DIR:-/workspace}"     --ServerApp.allow_root=True     > "${JUPYTER_DIR:-/workspace}"/jupyter.log 2>&1 &
fi

# Install custom nodes
if [[ -f "${CUSTOM_NODES_MANIFEST:-}" ]]; then
  if [[ "${NODES_INSTALL_MODE:-sync}" == "sync" ]]; then
    log "Installing custom nodes (sync) from ${CUSTOM_NODES_MANIFEST} ..."
    /scripts/install_nodes.sh "${CUSTOM_NODES_MANIFEST}"
  else
    log "Installing custom nodes (async) from ${CUSTOM_NODES_MANIFEST} ..."
    nohup /scripts/install_nodes.sh "${CUSTOM_NODES_MANIFEST}" >/workspace/nodes_install.log 2>&1 &
  fi
fi

# Manage workflows (copy/symlink + from manifest)
/scripts/manage_workflows.sh

# Download models (async by default to not block too long)
if [[ -f "${MODELS_MANIFEST:-}" ]]; then
  log "Downloading models from ${MODELS_MANIFEST} (async) ..."
  nohup /venv/bin/python /scripts/download_models.py "${MODELS_MANIFEST}" "${MODELS_DIR:-/workspace/models}" "${HF_TOKEN:-}" >/workspace/models_download.log 2>&1 &
fi

# Finally, launch ComfyUI if requested
if [[ "${COMFY_AUTOSTART:-true}" == "true" ]]; then
  log "Starting ComfyUI ..."
  exec /usr/local/bin/start-comfyui
else
  log "COMFY_AUTOSTART=false; container is up, not launching ComfyUI."
  tail -f /dev/null
fi
