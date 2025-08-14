# Runpod ComfyUI Wan2.2 + Jupyter — V4.1.4c (SLIM: Torch at runtime)
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive         PYTHONUNBUFFERED=1         PIP_NO_CACHE_DIR=1         TZ=UTC

# Base tools + minimal build deps for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends         python3 python3-venv python3-pip git git-lfs curl ca-certificates ffmpeg         tini aria2 jq rsync net-tools iproute2 wget unzip         build-essential python3-dev pkg-config cmake libgl1 libglib2.0-0      && git lfs install      && rm -rf /var/lib/apt/lists/*

# Python venv
RUN python3 -m venv /venv && /venv/bin/pip install --no-cache-dir -U pip setuptools wheel

# JupyterLab minimal
RUN /venv/bin/pip install --no-cache-dir jupyterlab==4.2.5 jupyterlab-lsp==5.1.0 jupyter-lsp==2.2.5

# --- ComfyUI (auto-detect default branch + robust fetch) ---
ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=auto   # auto | branch | tag | 40-char SHA
ENV COMFY_REPO=${COMFY_REPO} COMFY_REF=${COMFY_REF}

RUN set -eux;       echo "Fetching ComfyUI from: ${COMFY_REPO} @ ${COMFY_REF}";       if [ "${COMFY_REF}" = "auto" ] || [ -z "${COMFY_REF}" ]; then         DEF_BRANCH="$(git ls-remote --symref "${COMFY_REPO}" HEAD | awk '/^ref:/ {print $2}' | sed 's|refs/heads/||')";         echo "Auto-detected default branch: ${DEF_BRANCH}";         REF_TO_USE="${DEF_BRANCH}";       else         REF_TO_USE="${COMFY_REF}";       fi;       echo "Using ref: ${REF_TO_USE}";       (git ls-remote --heads --tags "${COMFY_REPO}" "${REF_TO_USE}" || true);       for i in 1 2 3; do         if [ "${REF_TO_USE#refs/}" != "${REF_TO_USE}" ] || [ ${#REF_TO_USE} -eq 40 ]; then           git clone --depth=1 "${COMFY_REPO}" /opt/ComfyUI &&           git -C /opt/ComfyUI checkout -q "${REF_TO_USE}" && break;         else           git clone --depth=1 --branch "${REF_TO_USE}" "${COMFY_REPO}" /opt/ComfyUI && break;         fi;         echo "clone failed (attempt $i), retrying in 10s..."; sleep 10; rm -rf /opt/ComfyUI || true;       done;       if [ ! -d /opt/ComfyUI ]; then         echo "Falling back to tarball download…";         mkdir -p /opt/ComfyUI && cd /opt/ComfyUI;         case "${REF_TO_USE}" in           ????????????????????????????????????????) REF_DL="master" ;;           *) REF_DL="${REF_TO_USE}" ;;         esac;         curl -fL "https://codeload.github.com/comfyanonymous/ComfyUI/tar.gz/${REF_DL}" | tar -xz --strip-components=1;       fi;       test -f /opt/ComfyUI/main.py

# ComfyUI-Manager preinstall
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager /opt/ComfyUI/custom_nodes/ComfyUI-Manager      && if [ -f /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then           /venv/bin/pip install --no-cache-dir -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt;         fi

# -------- Python deps (no torch here; torch is installed at runtime) --------
RUN /venv/bin/pip install --no-cache-dir -U pip setuptools wheel

# Protobuf compatible first
RUN /venv/bin/pip install --no-cache-dir "protobuf<5,>=3.20.3"

# HF core / util
RUN /venv/bin/pip install --no-cache-dir         huggingface-hub==0.24.6 safetensors==0.4.5 ftfy==6.3.1 pyloudnorm==0.1.1

# Diffusers / Accelerate / Transformers
RUN /venv/bin/pip install --no-cache-dir         diffusers==0.34.0 accelerate==1.10.0 transformers==4.44.2

# timm / peft / einops
RUN /venv/bin/pip install --no-cache-dir         timm==1.0.9 peft==0.17.0 einops==0.8.0

# sentencepiece + vidéo / IO / réseau
RUN /venv/bin/pip install --no-cache-dir         sentencepiece==0.2.0 opencv-python==4.10.0.84 imageio-ffmpeg==0.4.9 aiohttp==3.9.5 gguf==0.17.1

# Dirs + copy scripts/manifests
RUN mkdir -p /workspace /manifests /scripts /opt/ComfyUI/user/default/workflows /usr/local/bin /workspace/models
COPY scripts/ /scripts/
COPY bin/start-comfyui /usr/local/bin/start-comfyui
COPY manifests/ /manifests/
RUN chmod +x /usr/local/bin/start-comfyui /scripts/*.sh

# Default ENV
ENV ENABLE_JUPYTER=true         JUPYTER_PORT=8888         JUPYTER_DIR=/workspace         JUPYTER_TOKEN=         COMFY_AUTOSTART=true         COMFY_PORT=8188         COMFY_ARGS="--listen 0.0.0.0 --port 8188 --use-sage-attention"         DATA_DIR=/workspace         COMFY_DIR=/opt/ComfyUI         MODELS_DIR=/workspace/models         COMFY_WORKFLOWS_SRC=/workspace/workflows         COMFY_WORKFLOWS_MODE=symlink         CUSTOM_NODES_MANIFEST=/manifests/nodes_manifest.txt         MODELS_MANIFEST=/manifests/models_manifest.txt         WORKFLOWS_MANIFEST=/manifests/workflows_manifest.txt         NODES_INSTALL_MODE=sync         HF_TOKEN=         COMFY_UPDATE_AT_START=false         COMFY_REF_RUNTIME=         TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128         TORCH_SPEC_TORCH=torch         TORCH_SPEC_VISION=torchvision         TORCH_SPEC_AUDIO=torchaudio

WORKDIR /opt/ComfyUI
ENTRYPOINT ["/usr/bin/tini", "--", "/scripts/entrypoint.sh"]
