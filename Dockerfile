# --- PATCHED Dockerfile ---
ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=main

# Clone ComfyUI robustement (retry + fallback tarball)
RUN set -eux;     for i in 1 2 3; do         git clone --depth=1 --branch ${COMFY_REF} ${COMFY_REPO} /opt/ComfyUI && break || sleep 5;     done;     if [ ! -d /opt/ComfyUI ]; then         echo "⚠️ git clone failed, fallback tarball...";         wget -O /tmp/comfyui.tar.gz ${COMFY_REPO}/archive/${COMFY_REF}.tar.gz;         mkdir -p /opt/ComfyUI;         tar -xzf /tmp/comfyui.tar.gz -C /opt/ComfyUI --strip-components=1;         rm /tmp/comfyui.tar.gz;     fi
