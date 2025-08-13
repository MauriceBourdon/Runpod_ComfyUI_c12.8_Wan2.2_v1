#!/usr/bin/env bash
set -euo pipefail
nohup /scripts/download_models_worker.sh > /workspace/models_dl.log 2>&1 &
echo "[async] model download started in background -> /workspace/models_dl.log"
