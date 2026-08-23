#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' '== Operating System =='
lsb_release -a 2>/dev/null || true
uname -srvm

printf '%s\n' '== Motherboard And BIOS =='
for field in board_vendor board_name bios_vendor bios_version; do
  path="/sys/class/dmi/id/$field"
  [[ -r "$path" ]] && printf '%s: %s\n' "$field" "$(<"$path")"
done

printf '%s\n' '== CPU =='
lscpu | awk -F: '/^(Architecture|CPU\(s\)|On-line CPU|Model name|Thread|Core|Socket|CPU max MHz|CPU min MHz|L1d cache|L1i cache|L2 cache|L3 cache|NUMA node)/ {gsub(/^[ \t]+/, "", $2); print $1 ": " $2}'

printf '%s\n' '== Memory =='
awk '/^MemTotal:/ {print}' /proc/meminfo
free -h
swapon --show

printf '%s\n' '== GPU =='
nvidia-smi --query-gpu=name,memory.total,driver_version,power.default_limit,power.max_limit,compute_cap,vbios_version,pci.device_id,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max --format=csv
nvidia-smi topo -m

printf '%s\n' '== Storage =='
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,ROTA,TRAN
df -hT / /home

printf '%s\n' '== Toolchain =='
python3 --version
uv --version
cmake --version | sed -n '1p'
ninja --version
gcc --version | sed -n '1p'
git --version

printf '%s\n' '== Privacy Note =='
printf '%s\n' 'Serials, UUIDs, MAC addresses, IP addresses, hostname, and username were not requested.'
