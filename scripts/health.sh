#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

if [[ ${1:-} != --wait ]]; then
  curl --fail --silent --show-error "$BASE_URL/health"
  printf '\n'
  exit 0
fi

for _ in $(seq 1 360); do
  if curl --fail --silent "$BASE_URL/health" >/dev/null; then
    printf 'Server is healthy: %s/v1\n' "$BASE_URL"
    exit 0
  fi
  if ! systemctl --user is-active --quiet "$SERVICE_NAME"; then
    printf 'Server service stopped before becoming healthy.\n' >&2
    exit 1
  fi
  sleep 5
done

printf 'Timed out waiting for server health.\n' >&2
exit 1
