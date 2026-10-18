#!/usr/bin/env bash
# No privileged operations are performed: tests use --check (read-only).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT
cat > "$TEMP/systemd-detect-virt" <<'SH'
#!/bin/sh
# CI may execute inside a container; mock VM (non-container) to test OS guard.
if [ "${1:-}" = '--container' ]; then exit 1; fi
printf 'kvm\n'
SH
chmod +x "$TEMP/systemd-detect-virt"

printf 'Testing Debian/Ubuntu VM preflight ...\n'
PATH="$TEMP:$PATH" bash "$ROOT/scripts/install-host.sh" --check > "$TEMP/out"
grep -Fq 'PASS: OS and host checks passed' "$TEMP/out"

printf '#!/bin/sh\nexit 0\n' > "$TEMP/pveversion"
chmod +x "$TEMP/pveversion"
printf 'Testing Proxmox host guard ...\n'
if PATH="$TEMP:$PATH" bash "$ROOT/scripts/install-host.sh" --check > "$TEMP/out" 2>&1; then
  echo 'FAIL: a mocked Proxmox host was not rejected.' >&2
  exit 1
fi
grep -Fq 'Proxmox VE HOST' "$TEMP/out"
printf 'PASS: preflight accepts a VM and rejects a Proxmox host.\n'
