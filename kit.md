---
schema: kit/1.0
slug: qwen38-27b-rtx-pro-5000-blackwell
title: Qwen3.8-27B on RTX PRO 5000 Blackwell Workstation
summary: Reproduce an 84 tok/s Qwen3.8-27B NVFP4 vLLM server on an RTX PRO 5000 Blackwell 48 GB workstation.
version: 1.2.0
owner: asaddodhy
license: MIT
tags: [qwen3-8, vllm, nvfp4, blackwell, local-llm, inference, benchmark]
tools: [terminal, git, uv, systemd, huggingface-cli, nvidia-smi]
skills: [local-llm-deployment, gpu-inference-debugging]
tech: [python, pytorch, cuda, flashinfer, cutlass, bash]
testedHarnesses: [OpenCode]
model:
  provider: huggingface
  name: Inferact/Qwen3.8-27B-NVFP4
  version: 6128240ebaf4eaa7bad2b3d1c72c37d677c5f462
  hosting: Local vLLM 0.27.1 server on one NVIDIA RTX PRO 5000 Blackwell 48 GB
parameters:
  - name: max_model_len
    value: "65536"
    description: Per-request context ceiling selected for practical speed and memory use.
  - name: kv_cache_dtype
    value: fp8
  - name: gpu_memory_utilization
    value: "0.92"
  - name: max_num_seqs
    value: "8"
  - name: mtp_speculative_tokens
    value: "4"
    description: Best measured MTP width, averaging 84.27 tok/s.
  - name: max_jobs
    value: "2"
    description: Prevents FlashInfer compilation from exhausting 64 GB host RAM.
memory:
  scope: per-install
  backing: markdown
  writePolicy: merge-with-review
  retention: Keep benchmark and troubleshooting history indefinitely
  reviewMode: manual
  entityTypes: [machine-profile, package-pins, benchmarks, failures]
resolverHints:
  - match: Reproduce or repair the Qwen vLLM setup
    load: [docs/MACHINE_SPECS.md, docs/INSTALLATION.md, README.md]
    purpose: Load exact host constraints and package pins before changing the runtime.
  - match: Compare or tune inference speed
    load: [docs/BENCHMARKS.md, docs/NINFER.md]
    purpose: Preserve the benchmark method when comparing configurations.
failures:
  - problem: FlashInfer Ninja generation broke on a workspace path containing spaces.
    resolution: Launch through the no-space alias /tmp/opencode/qwen-bench.
    scope: environment
  - problem: CUDA 13.3 NVVM emitted PTX 9.3 while CUDA 13.2 ptxas supported PTX 9.2.
    resolution: Pin NVCC, runtime, CRT, NVVM, and CCCL to compatible CUDA 13.2 releases.
    scope: environment
  - problem: Parallel SM120 kernel compilation exhausted 61 GiB RAM and 8 GiB swap.
    resolution: Set MAX_JOBS=2 for FlashInfer JIT compilation.
    scope: environment
  - problem: FlashInfer expected cu13/lib64 and an unversioned libcudart.so missing from the pip layout.
    resolution: Add lib64 and libcudart compatibility symlinks inside the isolated runtime.
    scope: environment
  - problem: NVIDIA Xid 154 marked the GPU reset-required after a GSP heartbeat timeout.
    resolution: Reboot, verify nvidia-smi, and run a CUDA tensor operation before continuing.
    scope: environment
  - problem: NInfer's 20 GiB artifact could not be reconstructed on the 31 GiB /tmp tmpfs.
    resolution: Download the artifact directly to the persistent home filesystem.
    scope: environment
  - problem: vLLM crashed with CUDA illegal memory access and Xid 31 when concurrency four followed sequential 8K and 32K context requests.
    resolution: Avoid this mixed-context concurrency sequence; verify CUDA health after failure and retest only with an isolated upgraded stack.
    scope: environment
inputs:
  - name: workstation
    description: The RTX PRO 5000 Blackwell workstation described in docs/MACHINE_SPECS.md.
  - name: model_access
    description: Network access to the public Inferact/Qwen3.8-27B-NVFP4 Hugging Face repository.
outputs:
  - name: local_api
    description: OpenAI-compatible Qwen3.8-27B endpoint at http://127.0.0.1:8000/v1.
  - name: validated_runtime
    description: Pinned vLLM and CUDA environment with native SM120 NVFP4 kernels.
  - name: benchmark
    description: Repeatable single-stream 512-token throughput measurements for vLLM and experimental NInfer.
useCases:
  - scenario: Restore this workstation's known-good local Qwen deployment after reboot or environment loss.
    constraints: [One RTX PRO 5000 Blackwell, Ubuntu Linux, at least 64 GB host RAM]
  - scenario: Establish a baseline before changing context, MTP width, or inference engine.
    constraints: [Use the exact benchmark prompt and method]
prerequisites:
  - name: NVIDIA driver and NVML
    check: nvidia-smi
  - name: uv
    check: uv --version
  - name: Git
    check: git --version
  - name: curl
    check: curl --version
  - name: systemd user manager
    check: systemctl --user is-system-running
dependencies:
  runtime: CPython 3.13 and CUDA 13.2 package set
  cli: [uv, git, curl, nvidia-smi, systemctl]
verification:
  command: ./scripts/preflight.sh
  expected: Preflight complete. The machine is ready to start the validated server.
fileManifest:
  - path: scripts/install-runtime.sh
    role: source
    description: Recreates the pinned Python and CUDA runtime.
  - path: scripts/start-server.sh
    role: source
    description: Loads the model and starts the validated MTP4 vLLM service.
  - path: scripts/stop-server.sh
    role: source
    description: Stops vLLM and unloads its model from VRAM.
  - path: scripts/preflight.sh
    role: source
    description: Checks machine readiness and exact package pins.
  - path: scripts/benchmark.py
    role: source
    description: Repeats the published throughput benchmark method.
  - path: scripts/install-ninfer.sh
    role: source
    description: Builds and installs the pinned experimental NInfer runtime.
  - path: scripts/start-ninfer.sh
    role: source
    description: Loads the NInfer artifact with the best measured MTP5 configuration.
  - path: scripts/benchmark-ninfer.py
    role: source
    description: Repeats the NInfer comparison benchmark.
selfContained: false
environment:
  runtime: CPython 3.13, vLLM 0.27.1, PyTorch 2.13.0+cu132
  os: linux
  platforms: [Ubuntu 26.04 LTS, NVIDIA Blackwell sm_120]
  notes: Exact tested machine is documented in docs/MACHINE_SPECS.md.
  adaptationNotes: Other Blackwell GPUs may need different memory utilization, context, power, or CUDA package choices; benchmark instead of assuming these numbers transfer.
---

## Goal

Recreate and operate the known-good Qwen3.8-27B NVFP4 deployment that averaged
84.27 generated tokens per second with supported vLLM, plus the separately
validated experimental NInfer deployment that averaged 130.37 tokens per
second. Preserve runtime pins, lifecycle commands, API access, validation, and
the benchmark methods used to select vLLM MTP4 and NInfer MTP5.

## When to Use

Use this kit when a future agent must restore the setup after reboot or runtime
loss, diagnose a regression, reproduce the benchmark, or make a controlled
configuration change. It is also the starting point for adding a model manager
without losing the validated native NVFP4 runtime.

## Inputs

The workflow assumes access to this repository, the target workstation, and the
public Hugging Face checkpoint. Existing model weights and compiled caches can
be reused; otherwise the workflow downloads and rebuilds them.

## Setup

### Models

Use `Inferact/Qwen3.8-27B-NVFP4` at the revision recorded in frontmatter. The
model occupies approximately 25 GB on disk and loaded in about 23.31 GiB before
cache and graph reservations in the measured vLLM process.

### Services

The only runtime service is a localhost vLLM OpenAI-compatible API managed as a
transient user systemd unit. No cloud inference provider or API secret is used.

### Parameters

Start from 65,536 context, FP8 KV, memory utilization 0.92, eight maximum
sequences, text-only mode, CUDA graphs enabled, and MTP4. Do not substitute MTP3
or a wider speculative window without rerunning the benchmark.

### Environment

Read `docs/MACHINE_SPECS.md` and `docs/INSTALLATION.md` first. Copy
`config.env.example` to the ignored `config.env`, then adjust only paths that
differ. The existing validated runtime is temporary under `/tmp/opencode`.

## Steps

1. Run `./scripts/machine-inventory.sh` and compare the sanitized output with
   `docs/MACHINE_SPECS.md`; investigate material GPU, driver, kernel, or memory
   differences before proceeding.
2. Copy `config.env.example` to `config.env` and verify the persistent model
   source and no-space work alias paths.
3. Run `./scripts/preflight.sh`. If only the runtime or model is absent, continue
   with the corresponding installation step. Stop for NVIDIA reset or
   driver/library mismatch errors.
4. Run `./scripts/install-runtime.sh` when the pinned runtime is absent or
   damaged. Preserve all CUDA 13.2 pins and compatibility symlinks.
5. Run `./scripts/download-model.sh` only when the checkpoint is missing.
6. Ensure no LM Studio, llama.cpp, or other compute process occupies the GPU.
7. Run `./scripts/start-server.sh`, then `./scripts/health.sh --wait`.
8. Verify `GET http://127.0.0.1:8000/v1/models` includes `qwen3.8-27b` and run
   `./scripts/chat.sh "Reply with one short sentence."`.
9. Run `./scripts/benchmark.py` after warm-up. Compare measured results with
   `docs/BENCHMARKS.md` while accounting for clocks, thermals, and active load.
10. Use `./scripts/stop-server.sh` to stop the API and unload the model. Confirm
    VRAM release with `./scripts/status.sh` or `nvidia-smi`.
11. For the optional experimental NInfer path, read `docs/NINFER.md`, run
    `./scripts/install-ninfer.sh`, download and verify its artifact, then use the
    dedicated NInfer lifecycle and benchmark scripts. Never run both engines at
    once on this 48 GB GPU.
12. Do not reproduce the known vLLM mixed long-context/concurrency-four failure
    sequence. Read `docs/BENCHMARKS.md` before any concurrent-load testing.

## Failures Overcome

The workflow records path escaping, CUDA component mismatch, linker layout,
host-memory exhaustion, GPU reset, and driver reload failures because each one
occurred on the measured machine. Do not remove these workarounds as cleanup
without proving that the updated package stack no longer needs them.

## Validation

Preflight must pass, the health endpoint must return HTTP 200, `/v1/models` must
list `qwen3.8-27b`, and a non-thinking chat completion must succeed. For full
performance validation, the three measured 512-token runs should be compared to
the published MTP4 average of 84.27 tok/s using the same prompt and method.

## Outputs

The completed workflow leaves a usable localhost API, reproducible lifecycle
scripts, persistent model and compilation caches, and benchmark output that a
future agent can compare against the known-good result.

## Constraints

The kit does not bundle the 25 GB model, 7.6 GB Python environment, or compiled
binary caches, so `selfContained` is false. It is verified only on the machine
profile in this repository. The 64 GB host needs `MAX_JOBS=2` during kernel
compilation, and the server expects exclusive use of nearly all GPU VRAM.

## Safety Notes

Never publish GPU UUIDs, serial numbers, MAC addresses, IP addresses, tokens, or
the ignored `config.env`. Do not kill unknown GPU processes: identify whether
they belong to LM Studio or the user first. Keep the API bound to localhost by
default; changing to `0.0.0.0` requires firewalling and authentication. Avoid
deleting working model and kernel caches until a replacement runtime has passed
health and benchmark validation.
