#!/usr/bin/env bash
# Usage: bash check.sh [--wait] [--expect-b]
# When --expect-b is used, verifies the route-map experiment preferring ISP-B.
set -euo pipefail
wait_mode=0
expect='a'
for arg in "$@"; do
 case "$arg" in
  --wait) wait_mode=1 ;;
  --expect-b) expect='b' ;;
  *) echo "Unknown option: $arg" >&2; exit 2 ;;
 esac
done
if [[ "$expect" == a ]]; then
  preferred_nh=10.0.12.2
  other_nh=10.0.13.2
else
  preferred_nh=10.0.13.2
  other_nh=10.0.12.2
fi
nodes=(ce isp-a isp-b origin)
# All directed BGP neighbor checks (four sessions = eight endpoints).
peers=(
 'ce 10.0.12.2'
 'ce 10.0.13.2'
 'isp-a 10.0.12.1'
 'isp-a 10.0.24.2'
 'isp-b 10.0.13.1'
 'isp-b 10.0.34.2'
 'origin 10.0.24.1'
 'origin 10.0.34.1'
)
dkr() { sudo docker "$@"; }
router() { dkr exec "clab-bgp02-$1" vtysh -c "$2"; }
bgp_detail() { router ce 'show bgp ipv4 unicast 203.0.113.0/24'; }
check_routing() {
 local n pair ip summary rib kernel
 for n in "${nodes[@]}"; do
   [[ $(dkr inspect -f '{{.State.Running}}' "clab-bgp02-$n" 2>/dev/null) == true ]] || return 1
 done
 for pair in "${peers[@]}"; do
   read -r n ip <<<"$pair"
   summary=$(router "$n" 'show bgp ipv4 unicast summary established' 2>/dev/null) || return 1
   grep -Fq "$ip" <<<"$summary" || return 1
 done
 rib=$(bgp_detail 2>/dev/null) || return 1
 grep -Fq '10.0.12.2' <<<"$rib" || return 1
 grep -Fq '10.0.13.2' <<<"$rib" || return 1
 kernel=$(dkr exec clab-bgp02-ce ip -4 route show 203.0.113.0/24 2>/dev/null) || return 1
 grep -Fq "via $preferred_nh" <<<"$kernel" || return 1
 # Reject ECMP or stale preferred-path mismatch.
 if grep -Fq "via $other_nh" <<<"$kernel"; then return 1; fi
 # Origin must have a BGP-learned return route for CE's sourced ping.
 dkr exec clab-bgp02-origin ip -4 route show 192.0.2.1/32 | grep -q 'via ' || return 1
}

show_diagnostics() {
 echo '=== Diagnostics: BGP summary, CE candidates, kernel ===' >&2
 local n
 for n in "${nodes[@]}"; do
   echo "--- $n ---" >&2
   router "$n" 'show bgp ipv4 unicast summary' >&2 || true
   dkr exec "clab-bgp02-$n" ip -br address >&2 || true
 done
 bgp_detail >&2 || true
 dkr exec clab-bgp02-ce ip -4 route show 203.0.113.0/24 >&2 || true
}
if (( wait_mode )); then
 seconds=${WAIT_SECONDS:-120}
 [[ $seconds =~ ^[0-9]+$ ]] || { echo 'WAIT_SECONDS must be a nonnegative integer' >&2; exit 2; }
 attempts=$((seconds / 3 + 1))
 converged=0
 for ((i=1; i<=attempts; i++)); do
    if check_routing; then converged=1; break; fi
    printf 'Waiting for BGP-02 (%s/%s) ...
' "$i" "$attempts"
    if (( i < attempts )); then sleep 3; fi
 done
 if (( ! converged )); then
    echo 'FAIL: routes, sessions, or best path did not converge.' >&2
    show_diagnostics
    exit 1
 fi
fi
if ! check_routing; then
 echo "FAIL: expected ISP-$expect as best path (via $preferred_nh)." >&2
 show_diagnostics
 exit 1
fi
printf '
=== CE: two BGP paths, one best route ===
'
bgp_detail
printf '
=== CE: Linux forwarding route ===
'
dkr exec clab-bgp02-ce ip -4 route show 203.0.113.0/24
printf '
=== ORIGIN: return route to CE ===
'
dkr exec clab-bgp02-origin ip -4 route show 192.0.2.1/32
printf '
=== End-to-end ping (source CE loopback) ===
'
pid=$(dkr inspect -f '{{.State.Pid}}' clab-bgp02-ce)
sudo nsenter -t "$pid" -n ping -c 2 -W 2 -I 192.0.2.1 203.0.113.1 || {
 echo 'FAIL: end-to-end ping failed (check return route and ip forwarding).' >&2
 exit 1
}
printf '
SUCCESS: BGP-02 operational, both ISPs established; preferred ISP-%s.
' "${expect^^}"
