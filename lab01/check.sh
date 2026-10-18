#!/usr/bin/env bash
# Check both eBGP peers, kernel routes, and end-to-end connectivity.
# Usage: bash check.sh [--wait]. With --wait, retry for up to WAIT_SECONDS (default 120).
set -euo pipefail

R1=clab-bgp01-r1
R2=clab-bgp01-r2

run_docker() { sudo docker "$@"; }

is_ready() {
  [[ $(run_docker inspect -f '{{.State.Running}}' "$R1" 2>/dev/null) == true ]] || return 1
  [[ $(run_docker inspect -f '{{.State.Running}}' "$R2" 2>/dev/null) == true ]] || return 1
  run_docker exec "$R1" vtysh -c 'show bgp ipv4 unicast summary established' 2>/dev/null | grep -Fq '10.0.12.2' || return 1
  run_docker exec "$R2" vtysh -c 'show bgp ipv4 unicast summary established' 2>/dev/null | grep -Fq '10.0.12.1' || return 1
  run_docker exec "$R1" ip -4 route show 198.51.100.1/32 | grep -Fq 'via 10.0.12.2' || return 1
  run_docker exec "$R2" ip -4 route show 192.0.2.1/32 | grep -Fq 'via 10.0.12.1' || return 1
}

if [[ ${1:-} == '--wait' ]]; then
  wait_seconds=${WAIT_SECONDS:-120}
  if ! [[ $wait_seconds =~ ^[0-9]+$ ]]; then
    echo 'WAIT_SECONDS must be a nonnegative integer' >&2
    exit 2
  fi
  tries=$((wait_seconds / 3 + 1))
  ready=0
  for ((i=1; i<=tries; i++)); do
    if is_ready; then ready=1; break; fi
    printf '  Waiting for convergence (%s/%s)\n' "$i" "$tries"
    if (( i < tries )); then sleep 3; fi
  done
  if (( ! ready )); then
    echo 'FAIL: BGP did not converge or kernel routes are missing.' >&2
    for node in "$R1" "$R2"; do
      run_docker exec "$node" vtysh -c 'show bgp ipv4 unicast summary' || true
      run_docker exec "$node" ip -br addr || true
    done
    exit 1
  fi
fi

printf '\n=== Container status ===\n'
run_docker ps --filter 'name=clab-bgp01-' --format 'table {{.Names}}\t{{.Status}}'
printf '\n=== R1: BGP summary ===\n'
run_docker exec "$R1" vtysh -c 'show bgp ipv4 unicast summary'
printf '\n=== R2: BGP summary ===\n'
run_docker exec "$R2" vtysh -c 'show bgp ipv4 unicast summary'
printf '\n=== R1: route to R2 loopback ===\n'
run_docker exec "$R1" vtysh -c 'show bgp ipv4 unicast 198.51.100.1/32'
run_docker exec "$R1" ip -4 route show 198.51.100.1/32
printf '\n=== R2: route to R1 loopback ===\n'
run_docker exec "$R2" vtysh -c 'show bgp ipv4 unicast 192.0.2.1/32'
run_docker exec "$R2" ip -4 route show 192.0.2.1/32

if ! is_ready; then
  echo 'FAIL: at least one neighbor is not Established, or a remote loopback route is missing.' >&2
  exit 1
fi
printf '\nPASS: both neighbors Established; both remote /32 routes installed.\n'

# Use the host ping binary inside each router network namespace; the container may not have ping.
printf '\n=== End-to-end loopback ping ===\n'
for row in "$R1 192.0.2.1 198.51.100.1" "$R2 198.51.100.1 192.0.2.1"; do
  read -r node src dst <<<"$row"
  pid=$(run_docker inspect -f '{{.State.Pid}}' "$node")
  printf '  %s: %s -> %s\n' "$node" "$src" "$dst"
  if sudo nsenter -t "$pid" -n ping -c 2 -W 2 -I "$src" "$dst"; then
    echo '  PASS'
  else
    echo "FAIL: ICMP loopback ping failed for $node" >&2
    exit 1
  fi
done
printf '\nSUCCESS: BGP-01 operational (eBGP + routing + ping).\n'
