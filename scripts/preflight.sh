#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

failures=0

check() {
  local description=$1
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$description"
  else
    printf 'FAIL: %s\n' "$description" >&2
    failures=$((failures + 1))
  fi
}

check 'NVIDIA management library is healthy' nvidia-smi
check 'uv is installed' command -v uv
check 'curl is installed' command -v curl
check 'systemd user manager is available' systemctl --user is-system-running
check 'validated runtime exists' test -x "$VLLM_BIN"

if [[ -e "$WORK_DIR" ]]; then
  check 'no-space work path is available' test -d "$WORK_DIR"
elif [[ -n "$WORK_DIR_SOURCE" ]]; then
  check 'persistent work path can recreate alias' test -d "$WORK_DIR_SOURCE"
else
  printf 'FAIL: no work path or WORK_DIR_SOURCE configured\n' >&2
  failures=$((failures + 1))
fi

if [[ -f "$MODEL_PATH/config.json" ]]; then
  printf 'PASS: model checkpoint exists\n'
elif [[ -n "$WORK_DIR_SOURCE" && -f "$WORK_DIR_SOURCE/models/Inferact-Qwen3.8-27B-NVFP4/config.json" ]]; then
  printf 'PASS: model checkpoint exists at persistent source\n'
else
  printf 'FAIL: model checkpoint is missing\n' >&2
  failures=$((failures + 1))
fi

if [[ -x "$RUNTIME_DIR/bin/python" ]]; then
  if "$RUNTIME_DIR/bin/python" - <<'PY' >/dev/null 2>&1
import importlib.metadata as metadata
import torch

expected = {
    "vllm": "0.27.1",
    "torch": "2.13.0+cu132",
    "flashinfer-python": "0.6.16.post3",
    "nvidia-cuda-nvcc": "13.2.78",
    "nvidia-cuda-runtime": "13.2.75",
    "nvidia-cuda-crt": "13.2.78",
    "nvidia-nvvm": "13.2.78",
    "nvidia-cuda-cccl": "13.2.75",
}
for package, version in expected.items():
    assert metadata.version(package) == version, (package, metadata.version(package))
assert torch.cuda.is_available()
assert torch.cuda.get_device_capability(0) == (12, 0)
PY
  then
    printf 'PASS: pinned runtime and CUDA capability match\n'
  else
    printf 'FAIL: runtime package pins or CUDA capability differ\n' >&2
    failures=$((failures + 1))
  fi
fi

if nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null | grep -q .; then
  printf 'WARN: a compute process is using the GPU; unload it before starting vLLM\n'
else
  printf 'PASS: no GPU compute process is active\n'
fi

if ((failures > 0)); then
  printf '%d required preflight check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf 'Preflight complete. The machine is ready to start the validated server.\n'
