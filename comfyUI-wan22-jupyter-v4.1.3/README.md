# ComfyUI Wan 2.2 + Jupyter (V4.1.3, CUDA 12.8)
## Nouveautés
- COMFY_AUTOSTART (true/false) + COMFY_ARGS (flags launch).
- start-comfyui helper.
- Workflows persistants via /workspace/workflows (symlink|sync|sync-force).
- extra_model_paths.yaml -> /workspace/models/*
- Async models download in /workspace/models.
- ComfyUI-Manager, VideoHelperSuite, SageAttention, Triton.

## Build & push
docker buildx use mbuilder || (docker buildx create --name mbuilder --use && docker run --privileged --rm tonistiigi/binfmt --install all)
docker buildx build --platform linux/amd64 -t docker.io/mauricebourdondock/comfyui-wan-v4.1.3-cu128:latest --push .
