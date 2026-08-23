#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"

if command -v hf >/dev/null; then
  NINFER_HF_BIN=$(command -v hf)
fi

[[ -x "$NINFER_HF_BIN" ]] || {
  printf 'Hugging Face CLI not found at %s.\n' "$NINFER_HF_BIN" >&2
  exit 1
}

mkdir -p "$(dirname -- "$NINFER_MODEL_PATH")"
HF_XET_HIGH_PERFORMANCE=1 "$NINFER_HF_BIN" download "$NINFER_MODEL_REPO" \
  qwen3_8_27b_nvfp4.ninfer SHA256SUMS \
  --local-dir "$(dirname -- "$NINFER_MODEL_PATH")"

printf '%s  %s\n' "$NINFER_MODEL_SHA256" "$NINFER_MODEL_PATH" | \
  sha256sum --check
