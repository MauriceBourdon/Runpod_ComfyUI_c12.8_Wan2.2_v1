#!/usr/bin/env bash
set -euo pipefail
if ss -lnt | grep -q ":${COMFY_PORT:-8188}"; then exit 0; fi
if ss -lnt | grep -q ":${JUPYTER_PORT:-8888}"; then exit 0; fi
exit 1
