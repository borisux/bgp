#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for cmd in sudo docker containerlab ip nsenter ping grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'ERROR: required command not found: %s\n' "$cmd" >&2
    printf 'On Ubuntu 24.04, install host tools with: make install\n' >&2
    exit 1
  fi
done

if ! sudo docker info >/dev/null 2>&1; then
  echo 'ERROR: Docker daemon is unavailable. Check: sudo systemctl status docker' >&2
  exit 1
fi

printf '\n[1/3] Deploying FRRouting BGP-01 topology...\n'
sudo containerlab deploy -t bgp01.clab.yml

printf '\n[2/3] Containerlab node status...\n'
sudo containerlab inspect -t bgp01.clab.yml

printf '\n[3/3] Waiting for two Established eBGP sessions and kernel routes...\n'
if ! bash check.sh --wait; then
  echo 'BGP-01 did not pass validation. Diagnostics:' >&2
  sudo docker logs --tail 40 clab-bgp01-r1 2>&1 || true
  sudo docker logs --tail 40 clab-bgp01-r2 2>&1 || true
  exit 1
fi

echo
echo 'LAB IS UP: eBGP Established and both loopback routes installed.'
echo 'Next: make r1  |  make r2  |  make check  |  make down'
