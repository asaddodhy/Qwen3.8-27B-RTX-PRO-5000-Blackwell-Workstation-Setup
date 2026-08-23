# Agent Entry Point

This repository records the known-good Qwen3.8-27B NVFP4 setup for one NVIDIA
RTX PRO 5000 Blackwell 48 GB workstation.

Before changing or reproducing the setup:

1. Read `kit.md` as the primary ordered workflow.
2. Read `docs/MACHINE_SPECS.md` and `docs/INSTALLATION.md` before changing CUDA,
   driver, package, path, context, or memory settings.
3. Copy `config.env.example` to the ignored `config.env` if it is absent.
4. Run `./scripts/machine-inventory.sh` and `./scripts/preflight.sh`.
5. Do not kill unknown GPU processes. Identify LM Studio, llama.cpp, vLLM, or
   another user-owned process and ask before stopping it.
6. Keep CUDA compiler components on the documented 13.2 versions unless a new
   stack is tested independently.
7. Preserve `MAX_JOBS=2` for first-time FlashInfer kernel compilation on this
   64 GB host.
8. Never commit `config.env`, credentials, machine serials, UUIDs, MAC/IP
   addresses, model weights, Python environments, or generated caches.
9. Validate server health and API output before benchmarking.
10. Use the exact benchmark method in `docs/BENCHMARKS.md` for comparisons.

The baseline to protect is 84.27 tok/s average with MTP4, 65,536 context limit,
FP8 KV cache, text-only mode, and native SM120 NVFP4 kernels.
