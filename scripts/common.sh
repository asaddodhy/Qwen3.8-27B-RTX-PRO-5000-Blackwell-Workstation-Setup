#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CONFIG_FILE=${CONFIG_FILE:-"$REPO_DIR/config.env"}

if [[ -f "$CONFIG_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  set +a
else
  # shellcheck disable=SC1091
  source "$REPO_DIR/config.env.example"
fi

SERVICE_NAME=${SERVICE_NAME:-qwen-vllm-mtp4}
RUNTIME_DIR=${RUNTIME_DIR:-/tmp/opencode/qwen-runtime}
WORK_DIR=${WORK_DIR:-/tmp/opencode/qwen-bench}
WORK_DIR_SOURCE=${WORK_DIR_SOURCE:-}
MODEL_PATH=${MODEL_PATH:-/tmp/opencode/qwen-bench/models/Inferact-Qwen3.8-27B-NVFP4}
SERVED_MODEL_NAME=${SERVED_MODEL_NAME:-qwen3.8-27b}
HOST=${HOST:-127.0.0.1}
PORT=${PORT:-8000}
API_KEY=${API_KEY:-}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-65536}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.92}
MAX_NUM_SEQS=${MAX_NUM_SEQS:-8}
MTP_TOKENS=${MTP_TOKENS:-4}
MAX_JOBS=${MAX_JOBS:-2}
ENGINE_READY_TIMEOUT=${ENGINE_READY_TIMEOUT:-1800}

PYTHON_VERSION=3.13
CUDA_HOME="$RUNTIME_DIR/lib/python${PYTHON_VERSION}/site-packages/nvidia/cu13"
VLLM_BIN="$RUNTIME_DIR/bin/vllm"
BASE_URL="http://${HOST}:${PORT}"

require_network_auth() {
  if [[ "$HOST" != "127.0.0.1" && "$HOST" != "localhost" && -z "$API_KEY" ]]; then
    printf 'API_KEY is required when HOST is %s. Refusing unauthenticated network exposure.\n' "$HOST" >&2
    exit 1
  fi
}

require_runtime() {
  if [[ ! -x "$VLLM_BIN" ]]; then
    printf 'vLLM runtime not found at %s\n' "$VLLM_BIN" >&2
    printf 'Run %s/scripts/install-runtime.sh first.\n' "$REPO_DIR" >&2
    exit 1
  fi
}

ensure_work_dir() {
  if [[ -e "$WORK_DIR" ]]; then
    return
  fi
  if [[ -z "$WORK_DIR_SOURCE" || ! -d "$WORK_DIR_SOURCE" ]]; then
    printf 'No-space work path %s does not exist.\n' "$WORK_DIR" >&2
    printf 'Set WORK_DIR_SOURCE in config.env to its persistent source directory.\n' >&2
    exit 1
  fi
  mkdir -p "$(dirname -- "$WORK_DIR")"
  ln -s "$WORK_DIR_SOURCE" "$WORK_DIR"
}

require_model() {
  if [[ ! -f "$MODEL_PATH/config.json" ]]; then
    printf 'Model not found at %s\n' "$MODEL_PATH" >&2
    printf 'Review config.env or run scripts/download-model.sh.\n' >&2
    exit 1
  fi
}
