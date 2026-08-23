# Qwen3.8-27B on RTX PRO 5000 Blackwell Workstation

Reproducible setup for running `Inferact/Qwen3.8-27B-NVFP4` on one NVIDIA
RTX PRO 5000 Blackwell 48 GB with vLLM, native NVFP4 kernels, FP8 KV cache,
CUDA graphs, and MTP speculative decoding.

The best tested configuration generated **84.27 tokens/second** on average for
a 512-token, single-request workload. MTP4 was 79% faster than no MTP.

## Tested System

| Component | Value |
| --- | --- |
| GPU | NVIDIA RTX PRO 5000 Blackwell |
| VRAM | 48,935 MiB |
| Compute capability | 12.0 (`sm_120`) |
| Power limit | 300 W |
| Driver | 610.43.02 |
| OS | Ubuntu 26.04 LTS |
| Model | `Inferact/Qwen3.8-27B-NVFP4` |
| Model size on disk | Approximately 25 GB |
| vLLM | 0.27.1 |
| PyTorch | 2.13.0+cu132 |
| FlashInfer | 0.6.16.post3 |

## Validated Configuration

| Setting | Value |
| --- | --- |
| Weight format | ModelOpt NVFP4 |
| NVFP4 kernel | `FlashInferCutlassNvFp4LinearKernel` |
| Context limit | 65,536 tokens per request |
| KV cache | FP8 |
| MTP window | 4 speculative tokens |
| GPU memory utilization | 0.92 |
| Maximum sequences | 8 |
| Mode | Text-only |
| CUDA graphs | Enabled |
| API | OpenAI-compatible, `127.0.0.1:8000` |
| Served model name | `qwen3.8-27b` |

The model supports 262,144 tokens natively. This setup deliberately caps each
request at 65,536 tokens for a practical speed and memory balance. vLLM created
a physical KV pool larger than this limit, but `--max-model-len 65536` remains
the per-request ceiling.

## Repository Layout

```text
.
├── AGENTS.md
├── LICENSE
├── README.md
├── config.env.example
├── kit.md
├── docs/
│   ├── BENCHMARKS.md
│   ├── INSTALLATION.md
│   └── MACHINE_SPECS.md
└── scripts/
    ├── benchmark.py
    ├── chat.sh
    ├── download-model.sh
    ├── health.sh
    ├── install-runtime.sh
    ├── logs.sh
    ├── machine-inventory.sh
    ├── preflight.sh
    ├── restart-server.sh
    ├── start-server.sh
    ├── status.sh
    └── stop-server.sh
```

## Current Installation Locations

These are the locations used for the measured results:

```text
Model:
/home/dodhya/Documents/Default Project/qwen-bench/models/Inferact-Qwen3.8-27B-NVFP4

Validated Python environment:
/tmp/opencode/qwen-runtime

No-space model alias:
/tmp/opencode/qwen-bench

FlashInfer kernel cache:
/home/dodhya/.cache/flashinfer

vLLM compile cache:
/home/dodhya/.cache/vllm
```

The model and caches are persistent. The runtime and alias under
`/tmp/opencode` may disappear after reboot. Run `scripts/install-runtime.sh`
if the runtime disappears. `scripts/start-server.sh` recreates the no-space
work alias from `WORK_DIR_SOURCE` automatically. A future improvement is moving
the runtime to a persistent path without spaces.

## Initial Setup

Copy the example configuration:

```bash
cp config.env.example config.env
```

Review `config.env`, particularly `MODEL_PATH`. Then recreate the exact tested
runtime if needed:

```bash
./scripts/install-runtime.sh
```

Download the model if it is not already present:

```bash
./scripts/download-model.sh
```

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for the full installation
history, exact package pins, and troubleshooting details.

The exact sanitized workstation specification is in
[docs/MACHINE_SPECS.md](docs/MACHINE_SPECS.md). `kit.md` packages the workflow
in Journey's `kit/1.0` format so a future agent can follow the same recovery,
installation, validation, and benchmarking sequence.

## Load Model And Start Server

Starting the server loads the model into VRAM:

```bash
./scripts/start-server.sh
```

vLLM does not have a separate idle server and model-load operation in this
configuration. Starting the vLLM process starts the API server and loads its
configured model; stopping that process stops the API and unloads the model.

Wait until it is ready:

```bash
./scripts/health.sh --wait
```

The first launch can take several minutes while kernels and CUDA graphs are
compiled. Later launches reuse caches and are faster.

## Stop Server And Unload Model

Stopping the server unloads the model and releases its VRAM:

```bash
./scripts/stop-server.sh
```

## Restart Server

```bash
./scripts/restart-server.sh
```

This performs a stop followed by a fresh start, which is more reliable than
restarting a transient systemd unit.

## Status And Logs

```bash
./scripts/status.sh
./scripts/logs.sh
```

Use `Ctrl-C` to stop following logs; this does not stop the model server.

## API Access

```text
Base URL: http://127.0.0.1:8000/v1
API key: EMPTY (or any non-empty value)
Model: qwen3.8-27b
```

Example request:

```bash
./scripts/chat.sh "Explain virtual memory in three sentences."
```

Direct `curl` example:

```bash
curl http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer EMPTY' \
  -d '{
    "model": "qwen3.8-27b",
    "messages": [
      {"role": "user", "content": "Explain virtual memory briefly."}
    ],
    "max_tokens": 256,
    "temperature": 0.7,
    "chat_template_kwargs": {"enable_thinking": false}
  }'
```

Python clients should use:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:8000/v1",
    api_key="EMPTY",
)

response = client.chat.completions.create(
    model="qwen3.8-27b",
    messages=[{"role": "user", "content": "Hello"}],
    extra_body={
        "chat_template_kwargs": {"enable_thinking": False},
    },
)
print(response.choices[0].message.content)
```

## Benchmark Summary

| Setting | Measured tok/s | Average tok/s | Draft acceptance |
| --- | --- | ---: | ---: |
| No MTP | 47.07, 47.08, 47.09 | 47.08 | N/A |
| MTP2 | 76.60, 75.69, 71.44 | 74.58 | 73.7% |
| MTP3 | 80.35, 79.24, 73.99 | 77.86 | Not recorded |
| **MTP4** | **84.23, 84.52, 84.05** | **84.27** | 53.4% |
| MTP5 | 75.34, 70.04, 69.11 | 71.50 | 41.4% |
| MTP6 | 79.85, 78.33, 77.67 | 78.62 | 41.6% |
| MTP7 | 75.94, 73.43, 74.81 | 74.73 | 36.4% |

See [docs/BENCHMARKS.md](docs/BENCHMARKS.md) for methodology and interpretation.

## Notes

- MTP4 was optimal for the tested output. MTP5-7 performed more speculative
  work but accepted too few additional tokens to improve throughput.
- The checkpoint contains one trained MTP layer. Wider windows repeatedly apply
  that layer; they are not additional trained prediction heads.
- Results vary with prompt content, sampling, reasoning mode, active context,
  output length, and concurrency.
- This setup is text-only. Remove `--language-model-only` to test images, but
  expect different VRAM usage and performance.
- Bind to `0.0.0.0` only when LAN access is required, and add authentication or
  firewall rules before exposing the API beyond localhost.

## Agent Reproduction Kit

Future agents should begin with:

```bash
cp config.env.example config.env
./scripts/machine-inventory.sh
./scripts/preflight.sh
```

Then read `kit.md` and follow its ordered steps. The kit intentionally does not
include model weights, the Python environment, or generated CUDA binaries, but
the repository contains the scripts needed to recreate them.
