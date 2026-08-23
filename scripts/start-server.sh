#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
require_runtime
ensure_work_dir
require_model

if systemctl --user is-active --quiet "$SERVICE_NAME"; then
  printf '%s is already running.\n' "$SERVICE_NAME"
  exit 0
fi

systemctl --user reset-failed "$SERVICE_NAME" 2>/dev/null || true

systemd-run --user --unit="$SERVICE_NAME" \
  --property="WorkingDirectory=$WORK_DIR" \
  --setenv="MAX_JOBS=$MAX_JOBS" \
  --setenv="VLLM_ENGINE_READY_TIMEOUT_S=$ENGINE_READY_TIMEOUT" \
  --setenv="CUDA_HOME=$CUDA_HOME" \
  --setenv="PATH=$RUNTIME_DIR/bin:$CUDA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  "$VLLM_BIN" serve "$MODEL_PATH" \
  --served-model-name "$SERVED_MODEL_NAME" \
  --max-model-len "$MAX_MODEL_LEN" \
  --kv-cache-dtype fp8 \
  --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
  --max-num-seqs "$MAX_NUM_SEQS" \
  --language-model-only \
  --reasoning-parser qwen3 \
  --speculative-config "{\"method\":\"mtp\",\"num_speculative_tokens\":$MTP_TOKENS}" \
  --host "$HOST" \
  --port "$PORT"

printf 'Starting %s. Follow logs with: %s/scripts/logs.sh\n' "$SERVICE_NAME" "$REPO_DIR"
