#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

if systemctl --user is-active --quiet "$SERVICE_NAME"; then
  systemctl --user stop "$SERVICE_NAME"
  printf 'Stopped %s; model unloaded from vLLM.\n' "$SERVICE_NAME"
else
  printf '%s is not running.\n' "$SERVICE_NAME"
fi
