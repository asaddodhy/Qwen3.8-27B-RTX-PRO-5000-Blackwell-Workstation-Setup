# Experimental NInfer Setup

## Result

NInfer's documentation currently lists only the NVIDIA GeForce RTX 5090
(`sm_120a`) as supported. The unchanged NInfer source nevertheless compiled and
ran successfully on this NVIDIA RTX PRO 5000 Blackwell (`sm_120`) because both
are GB202-family Blackwell devices and the runtime does not enforce a GPU-name
check.

This remains an experimental, locally validated configuration rather than
upstream-supported hardware.

## Versions And Artifact

| Component | Value |
| --- | --- |
| NInfer source | `Neroued/ninfer` |
| Tested commit | `feaf4dd0983fdaeb2ba4c06eec6da350e644fb3a` |
| Minimum artifact runtime | `5d2c1f5590b8f4c3d106a75f65210eb4efb8f4e1` |
| Artifact | `neroued/Qwen3.8-27B-nvfp4-NInfer` |
| Artifact filename | `qwen3_8_27b_nvfp4.ninfer` |
| Artifact size | 21,492,695,040 bytes, 20.02 GiB |
| Artifact SHA-256 | `bb3360522a06e136e0367f5703414d26272b7285c8a6ab6194135c17dbd81b32` |
| Compile target | `sm_120a` |
| CUDA compiler | 13.2.78 |

The NVFP4 artifact is a mixed profile: NVFP4 MLP tensors plus row-scaled FP8
for embeddings, attention/GDN projections, output head, and later MLP layers.

## Persistent Locations

```text
NInfer executable:
~/.local/lib/ninfer/bin/ninfer

NInfer server:
~/.local/lib/ninfer/bin/ninfer-serve

Bundled CUDA runtime library:
~/.local/lib/ninfer/lib/libcudart.so.13

Model artifact:
/home/dodhya/Documents/Default Project/qwen-bench/models/NInfer-Qwen3.8-27B-NVFP4/qwen3_8_27b_nvfp4.ninfer
```

The source and build directory used during testing was `/tmp/opencode/ninfer`.
It is temporary and can be deleted or lost after reboot; the installed binaries
and model listed above are persistent.

## Build Dependencies

```bash
sudo apt install -y \
  cmake ninja-build pkg-config \
  libavformat-dev libavcodec-dev libavutil-dev \
  libswscale-dev libcurl4-openssl-dev
```

NInfer was configured and built with:

```bash
git clone https://github.com/Neroued/ninfer.git /tmp/opencode/ninfer
cd /tmp/opencode/ninfer

cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_COMPILER=/tmp/opencode/qwen-runtime/lib/python3.13/site-packages/nvidia/cu13/bin/nvcc \
  -DCUDAToolkit_ROOT=/tmp/opencode/qwen-runtime/lib/python3.13/site-packages/nvidia/cu13 \
  -DCMAKE_BUILD_RPATH=$HOME/.local/lib/ninfer/lib

cmake --build build --parallel 2
```

The repository automates these same tested commands:

```bash
cp config.ninfer.env.example config.ninfer.env
./scripts/install-ninfer.sh
```

Parallelism was limited to two because this host has approximately 64 GB RAM
and prior unrestricted CUDA compilation exhausted RAM and swap.

The two binaries were copied to `~/.local/lib/ninfer/bin`, and
`libcudart.so.13` was copied to `~/.local/lib/ninfer/lib`. CMake embedded the
persistent library directory in the binaries' RUNPATH.

## Download And Verify Artifact

```bash
./scripts/download-ninfer-model.sh
```

The script verifies the exact SHA-256 after download. The artifact was placed
on the persistent home filesystem because `/tmp` is a 31 GB tmpfs and Xet
reconstruction exceeded that filesystem's quota.

## Start And Load

```bash
cp config.ninfer.env.example config.ninfer.env
./scripts/start-ninfer.sh
./scripts/health-ninfer.sh --wait
```

Starting the NInfer server loads the model. The measured startup time from the
SATA ext4 filesystem was approximately 41 seconds.

## Stop And Unload

```bash
./scripts/stop-ninfer.sh
```

Stopping the service released model VRAM completely, returning the GPU to its
approximately 36 MiB desktop baseline.

## Status And Logs

```bash
./scripts/status-ninfer.sh
./scripts/logs-ninfer.sh
```

## API

```text
Local base URL: http://127.0.0.1:8080/v1
LAN base URL: http://192.168.1.6:8080/v1
Tailscale base URL: http://100.73.145.5:8080/v1
Model ID: qwen3.8-27b-ninfer
Authentication: bearer key from ignored config.ninfer.env
```

NInfer supports OpenAI Chat Completions/Responses and Anthropic Messages.
NInfer's `/health` remains unauthenticated by upstream design; `/v1/*` requires
the configured bearer key.

## Benchmark Method

The same deterministic client workload used for vLLM was used here:

- 31-token prompt
- 512 generated tokens
- Temperature 0.0
- Thinking disabled server-wide
- One warm-up plus three measured requests
- End-to-end HTTP client timing
- 65,536-token context and KV capacity
- INT8 group-64 KV cache
- CUDA graphs enabled
- Prefix reuse enabled by default
- Maximum concurrency 1 for this single-stream comparison

## Benchmark Results

| Engine/setting | Measured tok/s | Average | NInfer acceptance |
| --- | --- | ---: | ---: |
| vLLM MTP4 | 84.23, 84.52, 84.05 | 84.27 | 53.4% |
| NInfer MTP3 | 104.46, 104.16, 104.31 | 104.31 | 51.2% |
| NInfer MTP4 | 121.46, 121.18, 120.99 | 121.21 | 48.4% |
| **NInfer MTP5** | **130.68, 130.39, 130.06** | **130.37** | **47.9%** |

NInfer MTP5 was 54.7% faster than the best measured vLLM configuration on this
specific single-request workload. NInfer's internal phase metric reported
approximately 130.8-131.4 decode tok/s on measured MTP5 requests and 3.38
committed tokens per speculative round.

## Groupwise-Int Artifact Comparison

The second published Qwen3.8 NInfer profile was also downloaded, checksum
verified, and tested on the same RTX PRO 5000. It is NInfer's custom mixed
Q4/Q5/Q6 plus W8 artifact, not a GGUF and not a runtime-selectable Q4/Q5/Q6
mode.

```text
Repository: neroued/Qwen3.8-27B-NInfer
Filename: qwen3_8_27b.ninfer
Size: 18,210,531,328 bytes (16.96 GiB)
SHA-256: eec39564993d6e9c7d5e383382a760f093465c9d163ec9a1bd6ad50aaac6a509bbcb192a8afa5
Persistent location:
/home/dodhya/Documents/Default Project/qwen-bench/models/NInfer-Qwen3.8-27B-Groupwise/qwen3_8_27b.ninfer
```

The server configuration and client benchmark were otherwise identical to the
NVFP4 tests: 65,536 context/KV capacity, INT8 group-64 KV, CUDA graphs,
single-request capacity, thinking disabled, and 31 prompt plus 512 output
tokens.

| Groupwise setting | Measured tok/s | Average | Acceptance |
| --- | --- | ---: | ---: |
| **MTP3** | **106.46, 106.08, 105.82** | **106.12** | **58.8%** |
| MTP4 | 100.72, 100.10, 99.46 | 100.09 | 50.7% |
| MTP5 | 100.79, 100.20, 99.24 | 100.08 | 47.9% |

MTP3 is the optimum tested window for groupwise-int. Wider windows increased
speculative work but did not improve committed throughput.

### Resource Comparison

| Metric | Groupwise-int | NVFP4 |
| --- | ---: | ---: |
| Best setting | MTP3 | MTP5 |
| Best average throughput | 106.12 tok/s | **130.37 tok/s** |
| Artifact size | **16.96 GiB** | 20.02 GiB |
| Observed GPU memory while serving | **20,189 MiB** | 23,323 MiB |
| Free after weights | **30.26 GiB** | 27.21 GiB |
| Model startup from SATA storage | **33.6-34.1 s** | 39.4-41.8 s |

Groupwise-int uses approximately 3.1 GiB less observed VRAM and starts about
6-8 seconds faster, but its best measured generation throughput is 18.6% lower
than NVFP4 for this workload. NVFP4 remains the default active NInfer profile.

### Published Accuracy Results

NInfer's model cards report these matching evaluation rows:

| Benchmark | Groupwise-int | NVFP4 |
| --- | ---: | ---: |
| IFBench | **77.67%** | 77.00% |
| AIME 2025 | 96.67% | 96.67% |
| AIME 2026 | 96.67% | 96.67% |
| GPQA Diamond | 87.37% | **90.40%** |
| ERQA | 66.25% | 66.25% |
| RealWorldQA | 82.22% | **83.53%** |

These are single-sample evaluation results. NVFP4 leads on GPQA and
RealWorldQA, groupwise-int narrowly leads on IFBench, and the other listed
tests tie. They do not establish universal accuracy for every workload.

## Functional Validation

A CLI run with MTP3, 16K context, INT8 KV, CUDA graphs, and 64 generated tokens
completed successfully with no speculative fallback. It reported 111.19 decode
tok/s and 54.93% MTP acceptance.

The persistent server installation also returned the exact requested response
`persistent NInfer works` through its OpenAI-compatible API and unloaded cleanly.

## Limitations

- RTX PRO 5000 support is not claimed by NInfer upstream.
- NInfer supports MTP draft windows 1-5 for this target; do not use 6 or 7.
- The engine is specialized for one GPU and up to eight startup-fixed active
  requests. It is not a replacement for vLLM's broad model/runtime support.
- No CPU/GPU offload, multi-GPU, distributed serving, large-scale continuous
  batching, priority scheduling, or QoS is provided.
- The tested artifact is NInfer-specific and cannot be loaded by LM Studio,
  llama.cpp, Transformers, or vLLM.
- NInfer parses tool calls but does not execute them.

## Safety

Unload LM Studio and all other GPU models before starting NInfer. Do not kill an
unknown GPU process without identifying it. Keep the API on localhost unless an
API key, firewall, and appropriate network controls are configured.
