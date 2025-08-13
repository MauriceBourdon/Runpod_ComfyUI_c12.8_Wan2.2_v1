FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 COMFY_DIR=/opt/ComfyUI MODELS_DIR=/workspace/models DATA_DIR=/workspace COMFY_PORT=8188 ENABLE_JUPYTER=true JUPYTER_PORT=8888 WAN22_ENABLE=true WAN22_LORA_ENABLE=true WAN22_LIGHTNING_ENABLE=true WAN22_VAE_ENABLE=true WAN22_UMT5_ENABLE=true WAN_USE_TRITON=true WAN_USE_SAGE_ATTN=true COMFY_WORKFLOWS_SRC=/workspace/workflows COMFY_WORKFLOWS_MODE=symlink COMFY_AUTOSTART=true COMFY_ARGS="--listen 0.0.0.0 --port 8188" KIJAI_WAN_MODELS_HF_REPO=Kijai/WanVideo_comfy COMFY_MANAGER_ENABLE=true COMFY_MANAGER_REPO=https://github.com/Comfy-Org/ComfyUI-Manager VHS_REPO=https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite CC=gcc
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip python3-venv git git-lfs curl ca-certificates ffmpeg tini aria2 jq parallel net-tools iproute2 build-essential python3-dev ninja-build rsync && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install --upgrade pip && pip install --extra-index-url https://download.pytorch.org/whl/cu128 torch torchvision torchaudio && pip install jupyterlab jupyter_server triton
RUN pip install --no-cache-dir sageattention || pip install --no-cache-dir sage-attention || true
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ${COMFY_DIR}
WORKDIR ${COMFY_DIR}
RUN pip install -r requirements.txt
WORKDIR /
COPY scripts/ /scripts/
COPY bin/start-comfyui /usr/local/bin/start-comfyui
RUN chmod +x /scripts/*.sh /usr/local/bin/start-comfyui
RUN mkdir -p /opt/ComfyUI/models /opt/ComfyUI/user/default/workflows /workspace/models /workspace/workflows
VOLUME ["/workspace", "/root/.cache/huggingface"]
EXPOSE 8188 8888
HEALTHCHECK --interval=30s --timeout=5s --retries=20 CMD /scripts/healthcheck.sh
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/scripts/entrypoint.sh"]