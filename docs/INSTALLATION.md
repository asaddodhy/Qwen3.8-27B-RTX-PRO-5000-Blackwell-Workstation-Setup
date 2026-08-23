# Installation And Configuration

## 1. System Prerequisites

The measured system used Ubuntu 26.04 LTS, NVIDIA driver 610.43.02, and an RTX
PRO 5000 Blackwell with compute capability 12.0.

Confirm the GPU and driver:

```bash
nvidia-smi --query-gpu=name,memory.total,driver_version,power.limit,compute_cap --format=csv
```

Install `uv` if it is unavailable, following the official Astral documentation.

## 2. Runtime Creation

The tested environment is recreated by:

```bash
./scripts/install-runtime.sh
```

The script installs:

```text
vLLM                     0.27.1
PyTorch                  2.13.0+cu132
FlashInfer               0.6.16.post3
NVIDIA CUTLASS DSL       4.6.0
CUDA NVCC                13.2.78
CUDA runtime             13.2.75
CUDA CRT                 13.2.78
NVVM                     13.2.78
CUDA CCCL                13.2.75
```

The CUDA compiler components must remain aligned to CUDA 13.2. The initial pip
resolution mixed NVVM/CRT 13.3 with ptxas 13.2, producing PTX 9.3 that ptxas
9.2 could not assemble.

## 3. CUDA Wheel Compatibility Symlinks

NVIDIA's pip runtime places libraries in `cu13/lib`. FlashInfer 0.6.16 expects
`cu13/lib64` and the unversioned linker name `libcudart.so`. The installation
script adds:

```bash
ln -s lib "$CUDA_HOME/lib64"
ln -s libcudart.so.13 "$CUDA_HOME/lib/libcudart.so"
```

## 4. Model Download

```bash
./scripts/download-model.sh
```

This downloads `Inferact/Qwen3.8-27B-NVFP4`, approximately 25 GB.

## 5. Why A No-Space Path Is Used

FlashInfer's generated Ninja build did not correctly escape the space in the
original workspace path `Default Project`. The measured setup therefore uses:

```text
/tmp/opencode/qwen-runtime
/tmp/opencode/qwen-bench
```

The second path is a symlink to the persistent model/project directory. The
runtime itself currently resides under `/tmp`; moving it to a persistent path
without spaces is recommended for long-term use. `start-server.sh` recreates
the work-directory symlink automatically from `WORK_DIR_SOURCE` after reboot.

## 6. First Kernel Compilation

The first native NVFP4 launch compiles SM120 FlashInfer kernels. Unrestricted
parallel compilation exhausted 61 GB of system RAM and swap. `MAX_JOBS=2`
reduced peak memory substantially and completed successfully.

Do not delete these caches unless troubleshooting:

```text
~/.cache/flashinfer
~/.cache/vllm
```

## 7. Driver Problems Encountered

Two host issues were discovered and corrected:

- NVIDIA Xid 154 and a GSP heartbeat timeout placed the GPU in reset-required
  state. A reboot cleared it.
- NVIDIA userspace libraries were upgraded to 610.43.02 while kernel module
  595.84 remained loaded. A second reboot loaded the matching module.

Validate both CUDA and NVML before starting vLLM:

```bash
nvidia-smi
/tmp/opencode/qwen-runtime/bin/python -c \
  'import torch; print(torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))'
```

## 8. Server Configuration Rationale

- NVFP4 uses native Blackwell FP4 execution and reduces weight traffic.
- FP8 KV cache leaves more room for active context.
- MTP4 provided the best measured single-stream decode throughput.
- A 65,536-token request limit is a practical default despite the model's 262K
  native context.
- `--language-model-only` avoids reserving vision encoder resources for a
  text-focused deployment.
- CUDA graphs remain enabled because they improved the intended decode path.
