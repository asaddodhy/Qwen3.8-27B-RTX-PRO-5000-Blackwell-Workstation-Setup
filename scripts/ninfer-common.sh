#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_FILE=${NINFER_CONFIG_FILE:-"$REPO_DIR/config.ninfer.env"}

if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  set +a
else
  # shellcheck disable=SC1091
  source "$REPO_DIR/config.ninfer.env.example"
fi

NINFER_SERVICE_NAME=${NINFER_SERVICE_NAME:-qwen-ninfer-mtp5}
NINFER_INSTALL_DIR=${NINFER_INSTALL_DIR:-$HOME/.local/lib/ninfer}
NINFER_SOURCE_DIR=${NINFER_SOURCE_DIR:-/tmp/opencode/ninfer}
NINFER_SOURCE_REF=${NINFER_SOURCE_REF:-feaf4dd0983fdaeb2ba4c06eec6da350e644fb3a}
NINFER_CUDA_ROOT=${NINFER_CUDA_ROOT:-/tmp/opencode/qwen-runtime/lib/python3.13/site-packages/nvidia/cu13}
NINFER_HF_BIN=${NINFER_HF_BIN:-/tmp/opencode/qwen-runtime/bin/hf}
NINFER_MODEL_PATH=${NINFER_MODEL_PATH:-}
NINFER_MODEL_REPO=${NINFER_MODEL_REPO:-neroued/Qwen3.8-27B-nvfp4-NInfer}
NINFER_MODEL_SHA256=${NINFER_MODEL_SHA256:-bb3360522a06e136e0367f5703414d26272b7285c8a6ab6194135c17dbd81b32}
NINFER_MODEL_ID=${NINFER_MODEL_ID:-qwen3.8-27b-ninfer}
NINFER_HOST=${NINFER_HOST:-127.0.0.1}
NINFER_PORT=${NINFER_PORT:-8080}
NINFER_API_KEY=${NINFER_API_KEY:-}
NINFER_MAX_CONTEXT=${NINFER_MAX_CONTEXT:-65536}
NINFER_KV_CAPACITY=${NINFER_KV_CAPACITY:-65536}
NINFER_MAX_CONCURRENCY=${NINFER_MAX_CONCURRENCY:-1}
NINFER_PREFILL_CHUNK=${NINFER_PREFILL_CHUNK:-1024}
NINFER_DRAFT_TOKENS=${NINFER_DRAFT_TOKENS:-5}
NINFER_SERVER="$NINFER_INSTALL_DIR/bin/ninfer-serve"
NINFER_BASE_URL="http://${NINFER_HOST}:${NINFER_PORT}"

require_ninfer_network_auth() {
  if [[ "$NINFER_HOST" != "127.0.0.1" && "$NINFER_HOST" != "localhost" && -z "$NINFER_API_KEY" ]]; then
    printf 'NINFER_API_KEY is required when NINFER_HOST is %s. Refusing unauthenticated network exposure.\n' "$NINFER_HOST" >&2
    exit 1
  fi
}

require_ninfer() {
  [[ -x "$NINFER_SERVER" ]] || {
    printf 'NInfer server not found at %s\n' "$NINFER_SERVER" >&2
    printf 'See docs/NINFER.md for build and installation instructions.\n' >&2
    exit 1
  }
  [[ -f "$NINFER_MODEL_PATH" ]] || {
    printf 'NInfer model not found at %s\n' "$NINFER_MODEL_PATH" >&2
    printf 'Run scripts/download-ninfer-model.sh.\n' >&2
    exit 1
  }
}
