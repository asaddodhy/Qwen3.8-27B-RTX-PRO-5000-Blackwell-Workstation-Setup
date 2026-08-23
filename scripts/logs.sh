#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"
journalctl --user -u "$SERVICE_NAME" -f
