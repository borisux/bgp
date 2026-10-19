#!/usr/bin/env bash
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo 'This installer supports Ubuntu 24.04 LTS; /etc/os-release missing.' >&2
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then
  echo "This installer was written for Ubuntu Server 24.04 LTS (found ${ID:-unknown})." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y curl git make jq vim tcpdump traceroute iproute2 iputils-ping unzip util-linux python3 python3-yaml qemu-guest-agent
if systemctl list-unit-files qemu-guest-agent.service --no-legend 2>/dev/null | grep -q qemu-guest-agent; then
  sudo systemctl enable --now qemu-guest-agent || true
fi

if command -v docker >/dev/null 2>&1 && command -v containerlab >/dev/null 2>&1; then
  echo 'Docker and Containerlab already installed; skipping installer.'
else
  echo 'Installing Docker + Containerlab with the upstream Containerlab quick setup script.'
  echo 'Review https://containerlab.dev/install/ before running on an untrusted host.'
  export SETUP_SSHD=false
  curl -fsSL https://containerlab.dev/setup | sudo -E bash -s all
fi

sudo systemctl enable --now docker
printf '\n=== Tool versions ===\n'
sudo docker --version
containerlab version
printf '\nHost ready. Deploy with: make up\n'
