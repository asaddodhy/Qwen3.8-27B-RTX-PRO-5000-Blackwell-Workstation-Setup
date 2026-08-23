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
