#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"
require_ninfer

if systemctl --user is-active --quiet "$NINFER_SERVICE_NAME"; then
  printf '%s is already running.\n' "$NINFER_SERVICE_NAME"
  exit 0
fi

if nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null | grep -q .; then
  printf 'A GPU compute process is already active. Unload it before starting NInfer.\n' >&2
  nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader >&2
  exit 1
fi

systemctl --user reset-failed "$NINFER_SERVICE_NAME" 2>/dev/null || true
systemd-run --user --unit="$NINFER_SERVICE_NAME" \
  --property="WorkingDirectory=$NINFER_INSTALL_DIR" \
  "$NINFER_SERVER" "$NINFER_MODEL_PATH" \
  --host "$NINFER_HOST" \
  --port "$NINFER_PORT" \
  --model-id "$NINFER_MODEL_ID" \
  --max-context "$NINFER_MAX_CONTEXT" \
  --kv-capacity "$NINFER_KV_CAPACITY" \
  --max-concurrency "$NINFER_MAX_CONCURRENCY" \
  --prefill-chunk "$NINFER_PREFILL_CHUNK" \
  --kv-dtype int8 \
  --spec mtp \
  --draft-tokens "$NINFER_DRAFT_TOKENS" \
  --lm-head-draft \
  --no-thinking

printf 'Starting %s. Follow logs with scripts/logs-ninfer.sh.\n' "$NINFER_SERVICE_NAME"
