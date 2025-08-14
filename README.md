# ComfyUI Wan2.2 + Jupyter (Light) — V4.1.4c

- CUDA 12.8 (Ubuntu 22.04)
- ComfyUI (rolling at build) + ComfyUI-Manager preinstalled
- Deps anti-rouge pour Kijai/WanWrapper, VHS, etc.
- Manifests pour nodes/models/workflows (gérés dans /workspace)
- Ordre de boot : Jupyter (bg) → nodes (sync) → workflows → models (async) → ComfyUI (fg)

## RunPod ENV (exemples)
ENABLE_JUPYTER=true
JUPYTER_PORT=8888
JUPYTER_TOKEN=<ton_token>

COMFY_AUTOSTART=true
COMFY_ARGS=--listen 0.0.0.0 --port 8188 --use-sage-attention

NODES_INSTALL_MODE=sync
CUSTOM_NODES_MANIFEST=https://raw.githubusercontent.com/<toi>/Runpod_ComfyUI_c12.8_Wan2.2_v1/main/manifests/nodes_manifest.txt

COMFY_WORKFLOWS_SRC=/workspace/workflows
COMFY_WORKFLOWS_MODE=symlink
WORKFLOWS_MANIFEST=https://raw.githubusercontent.com/<toi>/Runpod_ComfyUI_c12.8_Wan2.2_v1/main/manifests/workflows_manifest.txt

MODELS_MANIFEST=https://raw.githubusercontent.com/<toi>/Runpod_ComfyUI_c12.8_Wan2.2_v1/main/manifests/models_manifest.txt
# HF_TOKEN=<si nécessaire pour des dépôts restreints>

## Ports
- ComfyUI: 8188
- Jupyter: 8888
