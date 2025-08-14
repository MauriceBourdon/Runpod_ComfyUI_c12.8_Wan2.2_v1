#!/usr/bin/env bash
set -e

echo "🚀 Entrypoint started..."

ENABLE_JUPYTER=${ENABLE_JUPYTER:-true}
JUPYTER_PORT=${JUPYTER_PORT:-8888}
COMFY_AUTOSTART=${COMFY_AUTOSTART:-true}
COMFY_ARGS=${COMFY_ARGS:---listen 0.0.0.0 --port 8188}

python3 /scripts/install_nodes.py /manifests/nodes_manifest.txt
python3 /scripts/install_models.py /manifests/models_manifest.txt
python3 /scripts/install_jupyter_exts.py /manifests/jupyter_manifest.txt

if [ "$ENABLE_JUPYTER" = "true" ]; then
    echo "📓 Lancement Jupyter..."
    nohup jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --NotebookApp.token="$JUPYTER_TOKEN" > /workspace/jupyter.log 2>&1 &
fi

if [ "$COMFY_AUTOSTART" = "true" ]; then
    echo "🎨 Lancement ComfyUI..."
    python3 /opt/ComfyUI/main.py $COMFY_ARGS > /workspace/comfyui.log 2>&1
else
    tail -f /dev/null
fi
