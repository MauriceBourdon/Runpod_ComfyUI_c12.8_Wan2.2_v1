FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

RUN apt-get update && apt-get install -y     git wget curl python3 python3-pip python3-venv     && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu128     torch torchvision torchaudio

RUN pip install --no-cache-dir     diffusers==0.34.0 accelerate==1.10.0 transformers==4.44.2     huggingface-hub==0.24.6 safetensors==0.4.5     einops==0.8.0 timm==1.0.9 peft==0.17.0     ftfy==6.3.1 protobuf==6.31.1 pyloudnorm==0.1.1 sentencepiece==0.2.0     aiohttp uvloop opencv-python imageio imageio-ffmpeg

ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=master
RUN git clone --depth=1 --branch ${COMFY_REF} ${COMFY_REPO} /opt/ComfyUI

RUN git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager.git /opt/ComfyUI/custom_nodes/ComfyUI-Manager

COPY scripts/ /scripts/
COPY manifests/ /manifests/

ENTRYPOINT ["/scripts/entrypoint.sh"]
