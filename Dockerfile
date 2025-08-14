# ComfyUI Wan 2.2 + Jupyter (light) - V4.1.4c
# CUDA 12.8, Ubuntu 22.04
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive         PYTHONUNBUFFERED=1         PIP_NO_CACHE_DIR=1         TZ=UTC

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends         python3 python3-venv python3-pip git git-lfs curl ca-certificates ffmpeg         tini aria2 jq rsync net-tools iproute2 &&         git lfs install &&         rm -rf /var/lib/apt/lists/*

# Python venv
RUN python3 -m venv /venv && /venv/bin/pip install --upgrade pip wheel setuptools

# JupyterLab (minimal)
RUN /venv/bin/pip install jupyterlab==4.2.5 jupyterlab-lsp==5.1.0 jupyter-lsp==2.2.5

# --- ComfyUI (rolling at build time)
ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=main
RUN git clone --depth=1 --branch ${COMFY_REF} ${COMFY_REPO} /opt/ComfyUI

# Pre-install ComfyUI-Manager
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager &&         if [ -f /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then           /venv/bin/pip install -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt;         fi

# Deps for Kijai/WanWrapper + VHS (anti "Import failed")
RUN /venv/bin/pip install --no-cache-dir -U         "diffusers>=0.34.0" "accelerate>=1.2.1" "transformers>=4.41"         safetensors sentencepiece huggingface-hub einops timm peft         ftfy protobuf pyloudnorm "gguf>=0.14.0" opencv-python imageio-ffmpeg         aiohttp uv

# Copy scripts/binaries
COPY scripts/ /scripts/
COPY bin/start-comfyui /usr/local/bin/start-comfyui
RUN chmod +x /scripts/*.sh /usr/local/bin/start-comfyui

# Runtime defaults
ENV COMFY_DIR=/opt/ComfyUI         DATA_DIR=/workspace         MODELS_DIR=/workspace/models         ENABLE_JUPYTER=true JUPYTER_PORT=8888 JUPYTER_DIR=/workspace         COMFY_AUTOSTART=true COMFY_PORT=8188         NODES_INSTALL_MODE=sync         COMFY_WORKFLOWS_SRC=/workspace/workflows         COMFY_WORKFLOWS_MODE=symlink

EXPOSE 8188 8888

WORKDIR /
ENTRYPOINT ["/usr/bin/tini","--","/scripts/entrypoint.sh"]
