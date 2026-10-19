#!/usr/bin/env bash
set -euo pipefail
# Intentionally never install software from this lab.
if command -v pveversion >/dev/null 2>&1 || [[ -d /etc/pve/nodes ]]; then
    echo 'ERROR: Proxmox hypervisor detected. Run inside a Debian/Ubuntu VM, not on the host.' >&2
    exit 1
fi
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --container --quiet; then
    echo 'ERROR: container/LXC detected. Use a full Proxmox VM for this lab.' >&2
    exit 1
fi
for cmd in sudo docker containerlab nsenter ping python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
       echo "Missing required command: $cmd. Complete lab01 host installation inside the VM." >&2
       exit 1
    fi
done
if ! sudo docker info >/dev/null 2>&1; then
    echo 'Docker is not available. Start/install Docker inside the VM.' >&2
    exit 1
fi
echo 'PASS: safe host checks and Docker/Containerlab binaries are available.'
