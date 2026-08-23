#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"

AUTH_ARGS=()
[[ -n "$NINFER_API_KEY" ]] && AUTH_ARGS=(-H "Authorization: Bearer $NINFER_API_KEY")

if [[ ${1:-} != --wait ]]; then
  curl --fail --silent --show-error "${AUTH_ARGS[@]}" "$NINFER_BASE_URL/v1/models"
  printf '\n'
  exit 0
fi

for _ in $(seq 1 180); do
  if curl --fail --silent "${AUTH_ARGS[@]}" "$NINFER_BASE_URL/v1/models" >/dev/null; then
    printf 'NInfer is healthy: %s/v1\n' "$NINFER_BASE_URL"
    exit 0
  fi
  if ! systemctl --user is-active --quiet "$NINFER_SERVICE_NAME"; then
    printf 'NInfer service stopped before becoming healthy.\n' >&2
    exit 1
  fi
  sleep 2
done

printf 'Timed out waiting for NInfer.\n' >&2
exit 1
