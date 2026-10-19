#!/usr/bin/env bash
# Route withdrawal exercise. Restores CE->ISP-A even after an error.
set -euo pipefail
node=clab-bgp02-ce
restore() {
  echo 'Restoring CE <-> ISP-A peering ...'
  sudo docker exec "$node" vtysh \
    -c 'configure terminal' -c 'router bgp 65000' \
    -c 'no neighbor 10.0.12.2 shutdown' || true
}
trap restore EXIT
printf 'Baseline verification first ...
'
bash check.sh
printf '
Disabling the CE BGP session towards ISP-A (only inside the lab) ...
'
sudo docker exec "$node" vtysh \
  -c 'configure terminal' -c 'router bgp 65000' \
  -c 'neighbor 10.0.12.2 shutdown'
# While A is admin-down, the normal check's eight-session check is intentionally not applicable.
echo 'Waiting for failover via ISP-B ...'
failover_ready=0
for ((i=1; i<=21; i++)); do
   out=$(sudo docker exec "$node" ip -4 route show 203.0.113.0/24) || out=''
   if grep -Fq 'via 10.0.13.2' <<<"$out"; then failover_ready=1; break; fi
   sleep 2
done
if (( !failover_ready )); then
 echo 'FAIL: CE did not switch forwarding to ISP-B.' >&2
 exit 1
fi
sudo docker exec "$node" ip -4 route show 203.0.113.0/24
pid=$(sudo docker inspect -f '{{.State.Pid}}' "$node")
sudo nsenter -t "$pid" -n ping -c 2 -W 2 -I 192.0.2.1 203.0.113.1
printf 'PASS: forwarding continued using ISP-B.
'
restore
trap - EXIT
printf 'Waiting for CE to prefer ISP-A again ...
'
bash check.sh --wait
