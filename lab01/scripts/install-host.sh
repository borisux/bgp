#!/usr/bin/env bash
# Install BGP-01 host prerequisites on a dedicated Debian/Ubuntu VM.
# Run "bash scripts/install-host.sh --check" for a non-modifying preflight.
set -euo pipefail

preflight() {
  if [[ ! -r /etc/os-release ]]; then
    echo 'ERROR: /etc/os-release missing; only Debian/Ubuntu VMs are supported.' >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    ubuntu|debian) ;;
    *)
      echo "ERROR: unsupported operating system: ${ID:-unknown}. Use a Debian or Ubuntu VM." >&2
      exit 1
      ;;
  esac

  # Proxmox VE uses Debian as its base distro. Installing Docker on the
  # Proxmox hypervisor could interfere with networking and firewall rules.
  if command -v pveversion >/dev/null 2>&1 || \
     dpkg-query -W -f='${Status}' pve-manager 2>/dev/null | grep -Fq 'install ok installed'; then
    echo 'ERROR: this looks like a Proxmox VE HOST, not a guest VM.' >&2
    echo 'Create a separate Debian/Ubuntu VM in Proxmox, clone this repo there and run make install.' >&2
    exit 1
  fi

  if command -v systemd-detect-virt >/dev/null 2>&1 && \
     systemd-detect-virt --container --quiet; then
    echo 'ERROR: an OS container (LXC/Docker) was detected. This installer targets a full VM.' >&2
    echo 'Use a Debian/Ubuntu VM with Docker networking support for this lab.' >&2
    exit 1
  fi

  echo "Detected guest OS: ${PRETTY_NAME:-${ID} ${VERSION_ID:-}}"
  echo 'Target: Debian/Ubuntu VM; Proxmox VE host installation is blocked.'
}

preflight
if [[ "${1:-}" == '--check' ]]; then
  echo 'PASS: OS and host checks passed; no software installed.'
  echo "Docker: $(command -v docker || echo 'not installed')"
  echo "Containerlab: $(command -v containerlab || echo 'not installed')"
  exit 0
fi

if [[ $# -gt 0 ]]; then
  echo 'Usage: bash scripts/install-host.sh [--check]' >&2
  exit 2
fi

# Minimal Debian installations may not include sudo when invoked as root.
if ! command -v sudo >/dev/null 2>&1; then
  if [[ $EUID -eq 0 ]]; then
    apt-get update
    apt-get install -y sudo
  else
    echo 'ERROR: sudo is required. Ask an administrator to install sudo or run as root.' >&2
    exit 1
  fi
fi

sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl git make jq vim tcpdump traceroute \
  iproute2 iputils-ping unzip util-linux python3 python3-yaml \
  qemu-guest-agent

# A QEMU guest should run the guest agent; other VM types can skip it.
if systemctl list-unit-files qemu-guest-agent.service --no-legend 2>/dev/null | grep -q 'qemu-guest-agent'; then
  sudo systemctl enable --now qemu-guest-agent || true
fi

# Do not use the official "all" setup if one tool is already installed: its
# Docker component may replace an existing Docker installation. Install only
# the missing components, leaving other Docker installations intact.
if ! command -v docker >/dev/null 2>&1; then
  echo 'Installing Docker using the official Containerlab setup script...'
  export SETUP_SSHD=false
  curl -fsSL https://containerlab.dev/setup | sudo -E bash -s install-docker
else
  echo 'Docker already installed; leaving it unchanged.'
fi

if ! command -v containerlab >/dev/null 2>&1; then
  echo 'Installing Containerlab using the official Containerlab setup script...'
  export SETUP_SSHD=false
  curl -fsSL https://containerlab.dev/setup | sudo -E bash -s install-containerlab
else
  echo 'Containerlab already installed; leaving it unchanged.'
fi

sudo systemctl enable --now docker
printf '\n=== Tool versions ===\n'
sudo docker --version
containerlab version
printf '\nHost ready. Deploy with: make up\n'
