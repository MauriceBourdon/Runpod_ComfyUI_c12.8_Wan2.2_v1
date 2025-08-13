#!/usr/bin/env bash
set -euo pipefail
export COMFY_DIR=${COMFY_DIR:-/opt/ComfyUI}
export DATA_DIR=${DATA_DIR:-/workspace}
export MODELS_DIR=${MODELS_DIR:-/workspace/models}
export COMFY_PORT=${COMFY_PORT:-8188}
export ENABLE_JUPYTER=${ENABLE_JUPYTER:-true}
export JUPYTER_PORT=${JUPYTER_PORT:-8888}
export JUPYTER_DIR=${JUPYTER_DIR:-/workspace}
export JUPYTER_TOKEN=${JUPYTER_TOKEN:-}
export COMFY_AUTOSTART=${COMFY_AUTOSTART:-true}
export COMFY_ARGS=${COMFY_ARGS:-"--listen 0.0.0.0 --port ${COMFY_PORT}"}
export COMFY_WORKFLOWS_SRC=${COMFY_WORKFLOWS_SRC:-/workspace/workflows}
export COMFY_WORKFLOWS_MODE=${COMFY_WORKFLOWS_MODE:-symlink}
echo "==> ENV Summary"; env | sort || true
echo "==> GPU Info"; nvidia-smi || true
mkdir -p "${MODELS_DIR}" "${COMFY_DIR}/user/default/workflows" "${COMFY_WORKFLOWS_SRC}"
cat > "${COMFY_DIR}/extra_model_paths.yaml" <<'YAML'
models:
  diffusion_models: /workspace/models/diffusion_models
  vae: /workspace/models/vae
  loras: /workspace/models/loras
  clip: /workspace/models/clip
  controlnet: /workspace/models/controlnet
YAML
/scripts/install_nodes.sh || echo "[WARN] install_nodes failed"
/scripts/download_models_async.sh || echo "[WARN] async download launcher failed"
case "${COMFY_WORKFLOWS_MODE}" in
  symlink)
    echo "[workflows] symlink mode from ${COMFY_WORKFLOWS_SRC}"
    rm -rf "${COMFY_DIR}/user/default/workflows"
    ln -s "${COMFY_WORKFLOWS_SRC}" "${COMFY_DIR}/user/default/workflows"
    ;;
  sync)
    echo "[workflows] sync mode (no overwrite) from ${COMFY_WORKFLOWS_SRC}"
    rsync -a --ignore-existing "${COMFY_WORKFLOWS_SRC}/" "${COMFY_DIR}/user/default/workflows/"
    ;;
  sync-force)
    echo "[workflows] sync-force mode (overwrite) from ${COMFY_WORKFLOWS_SRC}"
    rsync -a --delete "${COMFY_WORKFLOWS_SRC}/" "${COMFY_DIR}/user/default/workflows/"
    ;;
  *)
    echo "[workflows] unknown mode '${COMFY_WORKFLOWS_MODE}', defaulting to 'symlink'"
    rm -rf "${COMFY_DIR}/user/default/workflows"
    ln -s "${COMFY_WORKFLOWS_SRC}" "${COMFY_DIR}/user/default/workflows"
    ;;
esac
ln -sf "${COMFY_DIR}" "${DATA_DIR}/ComfyUI"
if [ "${ENABLE_JUPYTER}" = "true" ]; then
  echo "==> Starting JupyterLab on 0.0.0.0:${JUPYTER_PORT} (dir: ${JUPYTER_DIR})"
  /venv/bin/jupyter lab --ServerApp.ip=0.0.0.0 --ServerApp.port="${JUPYTER_PORT}" --ServerApp.open_browser=False --ServerApp.token="${JUPYTER_TOKEN}" --ServerApp.password='' --ServerApp.allow_origin='*' --ServerApp.root_dir="${JUPYTER_DIR}" --ServerApp.allow_root=True > "${DATA_DIR}/jupyter.log" 2>&1 &
fi
cd "${COMFY_DIR}"
if [ "${COMFY_AUTOSTART}" = "true" ]; then
  echo "==> Starting ComfyUI with: ${COMFY_ARGS}"
  exec /venv/bin/python main.py ${COMFY_ARGS}
else
  echo "==> COMFY_AUTOSTART=false : not starting ComfyUI automatically."
  echo "    Launch manually via: start-comfyui <args>"
  tail -f /workspace/jupyter.log
fi
