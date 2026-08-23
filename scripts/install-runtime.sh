#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(dirname -- "$0")/common.sh"

command -v uv >/dev/null || {
  printf 'uv is required: https://docs.astral.sh/uv/getting-started/installation/\n' >&2
  exit 1
}

mkdir -p "$(dirname -- "$RUNTIME_DIR")"
uv venv "$RUNTIME_DIR" --python "$PYTHON_VERSION"

uv pip install --python "$RUNTIME_DIR/bin/python" \
  'vllm==0.27.1' \
  'flashinfer-python==0.6.16.post3' \
  'nvidia-cutlass-dsl==4.6.0' \
  --torch-backend=auto

# Keep every CUDA compiler component aligned with PyTorch's CUDA 13.2 runtime.
uv pip install --python "$RUNTIME_DIR/bin/python" --force-reinstall --no-deps \
  'nvidia-cuda-nvcc==13.2.78' \
  'nvidia-cuda-runtime==13.2.75' \
  'nvidia-cuda-crt==13.2.78' \
  'nvidia-nvvm==13.2.78' \
  'nvidia-cuda-cccl==13.2.75'

[[ -e "$CUDA_HOME/lib64" ]] || ln -s lib "$CUDA_HOME/lib64"
[[ -e "$CUDA_HOME/lib/libcudart.so" ]] || \
  ln -s libcudart.so.13 "$CUDA_HOME/lib/libcudart.so"

"$RUNTIME_DIR/bin/python" - <<'PY'
import importlib.metadata as metadata
import torch

packages = (
    "vllm",
    "torch",
    "flashinfer-python",
    "nvidia-cutlass-dsl",
    "nvidia-cuda-nvcc",
    "nvidia-cuda-runtime",
    "nvidia-cuda-crt",
    "nvidia-nvvm",
    "nvidia-cuda-cccl",
)
for package in packages:
    print(f"{package}: {metadata.version(package)}")
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"Compute capability: {torch.cuda.get_device_capability(0)}")
PY
