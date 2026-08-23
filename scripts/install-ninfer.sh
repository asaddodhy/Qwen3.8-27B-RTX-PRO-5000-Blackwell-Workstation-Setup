#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=ninfer-common.sh
source "$(dirname -- "$0")/ninfer-common.sh"

for command_name in git cmake ninja pkg-config; do
  command -v "$command_name" >/dev/null || {
    printf '%s is required. See docs/NINFER.md.\n' "$command_name" >&2
    exit 1
  }
done

pkg-config --atleast-version=60 libavformat
pkg-config --atleast-version=60 libavcodec
pkg-config --atleast-version=58 libavutil
pkg-config --atleast-version=7 libswscale
pkg-config --atleast-version=7.85 libcurl

[[ -x "$NINFER_CUDA_ROOT/bin/nvcc" ]] || {
  printf 'CUDA compiler not found at %s/bin/nvcc.\n' "$NINFER_CUDA_ROOT" >&2
  printf 'Recreate the pinned vLLM runtime first.\n' >&2
  exit 1
}

mkdir -p "$(dirname -- "$NINFER_SOURCE_DIR")" "$NINFER_INSTALL_DIR/bin" "$NINFER_INSTALL_DIR/lib"

if [[ ! -d "$NINFER_SOURCE_DIR/.git" ]]; then
  git clone https://github.com/Neroued/ninfer.git "$NINFER_SOURCE_DIR"
fi

git -C "$NINFER_SOURCE_DIR" fetch origin "$NINFER_SOURCE_REF"
git -C "$NINFER_SOURCE_DIR" checkout --detach "$NINFER_SOURCE_REF"

cmake -S "$NINFER_SOURCE_DIR" -B "$NINFER_SOURCE_DIR/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_COMPILER="$NINFER_CUDA_ROOT/bin/nvcc" \
  -DCUDAToolkit_ROOT="$NINFER_CUDA_ROOT" \
  -DCMAKE_BUILD_RPATH="$NINFER_INSTALL_DIR/lib"

cmake --build "$NINFER_SOURCE_DIR/build" --parallel 2

install -m 0755 \
  "$NINFER_SOURCE_DIR/build/apps/ninfer" \
  "$NINFER_SOURCE_DIR/build/apps/ninfer-serve" \
  "$NINFER_INSTALL_DIR/bin/"
install -m 0644 "$NINFER_CUDA_ROOT/lib/libcudart.so.13" "$NINFER_INSTALL_DIR/lib/"

ldd "$NINFER_INSTALL_DIR/bin/ninfer-serve" | grep 'libcudart.so.13'
"$NINFER_INSTALL_DIR/bin/ninfer-serve" --help >/dev/null
printf 'Installed NInfer %s at %s\n' "$NINFER_SOURCE_REF" "$NINFER_INSTALL_DIR"
