#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

MODEL_REPO=${MODEL_REPO:-Inferact/Qwen3.8-27B-NVFP4}
MODEL_DOWNLOAD_DIR=${MODEL_DOWNLOAD_DIR:-$MODEL_PATH}

if [[ ! -x "$RUNTIME_DIR/bin/hf" ]]; then
  printf 'Hugging Face CLI not found. Run scripts/install-runtime.sh first.\n' >&2
  exit 1
fi

mkdir -p "$(dirname -- "$MODEL_DOWNLOAD_DIR")"
HF_XET_HIGH_PERFORMANCE=1 "$RUNTIME_DIR/bin/hf" download "$MODEL_REPO" \
  --local-dir "$MODEL_DOWNLOAD_DIR"
