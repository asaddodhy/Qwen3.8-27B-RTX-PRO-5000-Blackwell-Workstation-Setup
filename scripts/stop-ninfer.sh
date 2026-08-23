#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"

if systemctl --user is-active --quiet "$NINFER_SERVICE_NAME"; then
  systemctl --user stop "$NINFER_SERVICE_NAME"
  printf 'Stopped %s; NInfer model unloaded.\n' "$NINFER_SERVICE_NAME"
else
  printf '%s is not running.\n' "$NINFER_SERVICE_NAME"
fi
