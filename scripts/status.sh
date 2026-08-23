#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

systemctl --user status "$SERVICE_NAME" --no-pager || true
printf '\nGPU status:\n'
nvidia-smi --query-gpu=name,memory.used,memory.free,utilization.gpu,temperature.gpu,power.draw \
  --format=csv
