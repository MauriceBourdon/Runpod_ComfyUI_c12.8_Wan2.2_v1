#!/usr/bin/env bash
set -euo pipefail
source /scripts/util.sh
MODELS_DIR="${MODELS_DIR:-/workspace/models}"
REPO="${KIJAI_WAN_MODELS_HF_REPO:-Kijai/WanVideo_comfy}"
mkdir -p "${MODELS_DIR}/diffusion_models/wan" "${MODELS_DIR}/vae" "${MODELS_DIR}/clip" "${MODELS_DIR}/loras" "${MODELS_DIR}/controlnet"
echo "[worker] Start downloading models into ${MODELS_DIR} from ${REPO}"
if [ "${WAN22_ENABLE:-true}" = "true" ]; then
  WAN_MODEL="FastWan/Wan2_2-TI2V-5B-FastWanFullAttn_bf16.safetensors"
  hf_dl "$REPO" "$WAN_MODEL" "${MODELS_DIR}/diffusion_models/wan/$(basename "$WAN_MODEL")"
fi
if [ "${WAN22_VAE_ENABLE:-true}" = "true" ]; then
  hf_dl "$REPO" "Wan2_1_VAE_bf16.safetensors" "${MODELS_DIR}/vae/Wan2_1_VAE_bf16.safetensors"
  hf_dl "$REPO" "Wan2_2_VAE_bf16.safetensors" "${MODELS_DIR}/vae/Wan2_2_VAE_bf16.safetensors"
fi
if [ "${WAN22_UMT5_ENABLE:-true}" = "true" ] ; then
  hf_dl "$REPO" "umt5-xxl-enc-bf16.safetensors" "${MODELS_DIR}/clip/umt5-xxl-enc-bf16.safetensors" || true
  hf_dl "$REPO" "umt5-xxl-enc-fp8_e4m3fn.safetensors" "${MODELS_DIR}/clip/umt5-xxl-enc-fp8_e4m3fn.safetensors" || true
fi
if [ "${WAN22_LORA_ENABLE:-true}" = "true" ]; then
  hf_dl "$REPO" "FastWan/Wan2_2_5B_FastWanFullAttn_lora_rank_128_bf16.safetensors" "${MODELS_DIR}/loras/Wan2_2_5B_FastWanFullAttn_lora_rank_128_bf16.safetensors"
fi
if [ "${WAN22_LIGHTNING_ENABLE:-true}" = "true" ]; then
  for f in "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" "Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" "Wan2.2-Lightning_T2V-A14B-4steps-lora_HIGH_fp16.safetensors" "Wan2.2-Lightning_T2V-A14B-4steps-lora_LOW_fp16.safetensors" "Wan2.2-Lightning_T2V-v1.1-A14B-4steps-lora_HIGH_fp16.safetensors" "Wan2.2-Lightning_T2V-v1.1-A14B-4steps-lora_LOW_fp16.safetensors"; do
    hf_dl "$REPO" "$f" "${MODELS_DIR}/loras/$f" || true
  done
fi
echo "[worker] Downloads completed."
