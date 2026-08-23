#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"
journalctl --user -u "$NINFER_SERVICE_NAME" -f
