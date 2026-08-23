# Benchmark Results

## Method

Every setting used the same model and server configuration except for the MTP
speculative window.

- One request at a time
- 31 prompt tokens
- Exactly 512 generated tokens
- Thinking disabled
- Temperature 0.0
- One warm-up request
- Three measured requests
- End-to-end client timing, including small HTTP and prefill overhead

Prompt:

```text
Write a detailed technical explanation of how virtual memory works in Linux.
Continue until the token limit.
```

Run the included benchmark against a loaded server:

```bash
./scripts/benchmark.py
```

## Results

| Setting | Run 1 | Run 2 | Run 3 | Average | Acceptance |
| --- | ---: | ---: | ---: | ---: | ---: |
| No MTP | 47.07 | 47.08 | 47.09 | 47.08 | N/A |
| MTP2 | 76.60 | 75.69 | 71.44 | 74.58 | 73.7% |
| MTP3 | 80.35 | 79.24 | 73.99 | 77.86 | Not recorded |
| **MTP4** | **84.23** | **84.52** | **84.05** | **84.27** | 53.4% |
| MTP5 | 75.34 | 70.04 | 69.11 | 71.50 | 41.4% |
| MTP6 | 79.85 | 78.33 | 77.67 | 78.62 | 41.6% |
| MTP7 | 75.94 | 73.43 | 74.81 | 74.73 | 36.4% |

## Interpretation

MTP4 was approximately 79% faster than baseline and 8% faster than MTP2 for
this workload. Raw speculative acceptance declines with wider windows, but MTP4
still commits enough tokens per target verification to outperform narrower
windows. MTP5-7 add drafting and verification work without enough accepted
tokens to improve throughput.

These numbers are not universal model speed ratings. Long active contexts,
reasoning mode, different output distributions, concurrent requests, and other
sampling parameters can materially change MTP acceptance and throughput.

## NInfer Comparison

After the vLLM campaign, unchanged NInfer source compiled for `sm_120a` was
validated experimentally on the same RTX PRO 5000. The same deterministic
31-token prompt and 512-token output workload produced:

| Setting | Run 1 | Run 2 | Run 3 | Average | Acceptance |
| --- | ---: | ---: | ---: | ---: | ---: |
| NInfer MTP3 | 104.46 | 104.16 | 104.31 | 104.31 | 51.2% |
| NInfer MTP4 | 121.46 | 121.18 | 120.99 | 121.21 | 48.4% |
| **NInfer MTP5** | **130.68** | **130.39** | **130.06** | **130.37** | **47.9%** |

NInfer used INT8 group-64 KV cache, CUDA graphs, 65,536 context/KV capacity,
and maximum concurrency one. Prefix reuse remained enabled. See `docs/NINFER.md`
for the distinction between upstream support and local validation.

## vLLM Long-Context Results

These requests used the validated vLLM MTP4 server and 512 generated tokens.
The reported rate is completion tokens divided by total client-observed time,
so it includes prompt prefill rather than isolating decode only.

| Prompt tokens | Completion tokens | Total time | End-to-end completion tok/s |
| ---: | ---: | ---: | ---: |
| 8,158 | 512 | 7.803 s | 65.62 |
| 32,734 | 512 | 12.233 s | 41.85 |

This decline is expected: larger active prompts require more prefill work and
increase attention/cache work during generation. Do not compare these values
directly with the short 31-token prompt's 84.27 tok/s average as if they were
decode-only measurements.

## vLLM Concurrent Requests

On a fresh vLLM MTP4 server, after short single-request warm-up/benchmarking,
four simultaneous short prompts each generated 512 tokens successfully:

| Concurrency | Total completion tokens | Wall time | Aggregate tok/s |
| ---: | ---: | ---: | ---: |
| 4 | 2,048 | 8.459 s | 242.12 |

Individual client-observed latencies ranged from 7.21 to 8.46 seconds. The
server was configured with `--max-num-seqs 8` and reported no failed requests in
this fresh-server run.

### Stateful Failure Sequence

A different sequence was not stable:

1. Start the same vLLM MTP4 server.
2. Complete an approximately 8K prompt plus 512 output tokens.
3. Complete an approximately 32K prompt plus 512 output tokens.
4. Submit four simultaneous short 512-token requests.

During step 4, vLLM 0.27.1/FlashInfer encountered a CUDA illegal memory access
while building attention metadata. The NVIDIA driver logged Xid 31 (MMU fault),
all four requests returned HTTP 500, and the engine exited. This was not a VRAM
out-of-memory event; cache usage was reported near 21% immediately beforehand.

The GPU did not enter reset-required state. A fresh PyTorch CUDA matrix
multiplication succeeded afterward, and NVIDIA reported recovery action `None`,
so no reboot was required.

Treat concurrent vLLM MTP4 serving as **conditionally validated**, not fully
stable across mixed long-context and batched workloads. Do not reproduce the
known failing sequence on a production service. Prefer NInfer for the tested
single-user latency path, or retest concurrency after upgrading vLLM/FlashInfer
in an isolated environment.
