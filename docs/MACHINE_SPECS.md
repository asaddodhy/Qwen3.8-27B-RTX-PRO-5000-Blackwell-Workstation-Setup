# Machine Specification

This is the sanitized hardware and software profile of the workstation used for
the published benchmarks. It contains reproducibility-relevant details but
intentionally excludes serial numbers, UUIDs, MAC addresses, usernames, host
names, and private network information.

Snapshot date: 2026-08-23.

## System

| Component | Specification |
| --- | --- |
| Architecture | x86-64 / AMD64 |
| Firmware vendor | American Megatrends Inc. |
| BIOS version | L1.91 |
| Motherboard | ASRock Z490M Pro4 |
| NUMA topology | One node, CPUs 0-11 |

The DMI system vendor and product fields contain the OEM placeholders
`To Be Filled By O.E.M.` and are not meaningful.

## CPU

| Component | Specification |
| --- | --- |
| Model | Intel Core i5-10600K at 4.10 GHz |
| Generation | Comet Lake-S |
| Sockets | 1 |
| Physical cores | 6 |
| Threads | 12 |
| Threads per core | 2 |
| Maximum reported frequency | 4.8 GHz |
| Minimum reported frequency | 800 MHz |
| L1 data cache | 192 KiB total, 6 instances |
| L1 instruction cache | 192 KiB total, 6 instances |
| L2 cache | 1.5 MiB total, 6 instances |
| L3 cache | 12 MiB |
| Physical address width | 39 bits |
| Virtual address width | 48 bits |
| Relevant ISA | SSE4.1/4.2, AVX, AVX2, FMA, AES, BMI1/2 |

## Memory

| Component | Specification |
| --- | --- |
| Installed memory reported by Linux | 64,171,556 KiB, approximately 61.2 GiB usable |
| Swap | 8 GiB file at `/swap.img` |

DIMM manufacturer, part number, speed, and channel population were not captured
because unprivileged DMI access does not expose them. They are not required for
the measured GPU decode path. During the initial unrestricted FlashInfer build,
61 GiB RAM plus swap was insufficient; limiting compilation with `MAX_JOBS=2`
reduced peak memory and succeeded.

At the snapshot, swap remained nearly full from prior compilation. Rebooting or
cycling swap may improve host responsiveness but does not change model output.

## GPU

| Component | Specification |
| --- | --- |
| Model | NVIDIA RTX PRO 5000 Blackwell |
| GPU family | GB202GL |
| PCI device ID | `10de:2bb3` |
| VRAM reported by NVIDIA | 48,935 MiB |
| Compute capability | 12.0 (`sm_120`) |
| Default/max power limit | 300 W / 300 W |
| VBIOS | 98.02.A5.00.02 |
| Driver | NVIDIA open kernel module 610.43.02 |
| CUDA version reported by driver | 13.3 UMD |
| PCIe topology | CPU root complex, x16 link |
| PCIe maximum negotiated generation | Gen 3 on this host |
| NUMA affinity | Node 0, CPUs 0-11 |
| NVLink | None |

The GPU drops to PCIe Gen 1 while idle and negotiates up under load. The host's
Comet Lake/Z490 platform limits the card to PCIe Gen 3 x16. Decode is primarily
limited by local GPU memory traffic, so this did not prevent the measured 84.27
tok/s result. Long model loading and host-to-device transfers can still benefit
from a newer PCIe platform.

## Integrated Graphics

| Component | Specification |
| --- | --- |
| GPU | Intel UHD Graphics 630 |
| Driver | `i915` |

## Storage

| Device | Capacity | Interface | Usage |
| --- | ---: | --- | --- |
| Samsung SSD 850 PRO 1TB | 953.9 GiB | SATA | Linux root plus other partitions |
| SanDisk Extreme Pro 500GB | 465.8 GiB | NVMe | Separate NTFS installation/data partition |

The tested model and runtime reside on the Linux root filesystem:

```text
Filesystem: ext4
Backing device: SATA Samsung SSD 850 PRO
Root partition: approximately 476 GiB
```

Model load time is affected by this storage choice. It does not materially
affect steady-state decode after weights are resident in VRAM.

## Network And Other Controllers

| Component | Specification |
| --- | --- |
| Wired Ethernet | Intel I219-V using `e1000e` |
| Wireless | Broadcom BCM4360 802.11ac |
| SATA controller | Intel Comet Lake AHCI |
| NVMe controller | SanDisk/WD controller using `nvme` |

Network addresses and adapter identifiers are intentionally omitted.

## Operating System And Toolchain

| Component | Version |
| --- | --- |
| Distribution | Ubuntu 26.04 LTS, Resolute |
| Kernel | 7.0.0-29-generic, PREEMPT_DYNAMIC |
| NVIDIA package | `nvidia-driver-610-open` 610.43.02 |
| Python, system | 3.14.4 |
| Python used by vLLM | CPython 3.13.14 |
| uv | 0.12.1 |
| GCC | 15.2.0 |
| CMake | 4.2.3 |
| Ninja | 1.13.2 |
| Git | 2.53.0 |

## Validated AI Runtime

| Package | Version |
| --- | --- |
| vLLM | 0.27.1 |
| PyTorch | 2.13.0+cu132 |
| FlashInfer | 0.6.16.post3 |
| NVIDIA CUTLASS DSL | 4.6.0 |
| CUDA NVCC | 13.2.78 |
| CUDA runtime | 13.2.75 |
| CUDA CRT | 13.2.78 |
| NVVM | 13.2.78 |
| CUDA CCCL | 13.2.75 |

The installed display/compute driver may support a newer CUDA UMD than the
compiler used by PyTorch and FlashInfer. This is expected. The runtime compiler
components listed above must remain mutually compatible at CUDA 13.2.

## Capacity And Operational Constraints

- The 48 GB GPU can hold the 24.57 GiB checkpoint, MTP state, CUDA graphs, and
  a substantial FP8 KV pool entirely in VRAM.
- The tested server reserves most VRAM using `--gpu-memory-utilization 0.92`.
  Unload LM Studio, llama.cpp, or other GPU models before starting vLLM.
- The 64 GB host RAM is adequate for normal model loading but not unconstrained
  parallel compilation of all FlashInfer SM120 kernels.
- The current runtime under `/tmp/opencode/qwen-runtime` is temporary. The
  model and caches under the home filesystem are persistent.
- The original workspace path contains a space. FlashInfer Ninja generation
  required a no-space alias under `/tmp/opencode/qwen-bench`.

## Refreshing This Snapshot

Run the sanitized inventory script:

```bash
./scripts/machine-inventory.sh
```

Review output before publishing. The script is designed not to request serial
numbers, UUIDs, MAC addresses, or IP addresses.
