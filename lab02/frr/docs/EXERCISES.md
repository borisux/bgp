# BGP-02 guided exercises — do them in order

## 1. Observe two paths to the same prefix

From the Debian/Ubuntu VM (never from the Proxmox host):

```bash
cd ~/labs/bgp/lab02
make up
make ce
```

Inside CE's FRRouting CLI (`vtysh`):

```text
show bgp ipv4 unicast summary
show bgp ipv4 unicast 203.0.113.0/24
show bgp ipv4 unicast neighbors 10.0.12.2 routes
show bgp ipv4 unicast neighbors 10.0.13.2 routes
show ip route bgp
show running-config
```

The same **destination prefix** arrives from both ISPs. AS-PATH is
`65010 65030` via A and `65020 65030` via B (equal lengths). Import
route-maps assign LOCAL_PREF 200 to A and 100 to B. Larger wins **inside
our AS** and CE installs ISP-A as the Linux forwarding next-hop.

Back on the VM:

```bash
sudo docker exec clab-bgp02-ce ip -4 route show 203.0.113.0/24
```

Expected: a route via `10.0.12.2`.

## 2. Change preference without tearing down either peering

Back in CE's vtysh (`make ce`):

```text
configure terminal
route-map FROM-ISP-A permit 10
 set local-preference 50
exit
end
clear bgp 10.0.12.2 soft in
show bgp ipv4 unicast 203.0.113.0/24
```

Now B has LOCAL_PREF 100 vs A's 50; observe best path via `10.0.13.2`.
The **soft inbound reset** asks FRR to re-apply inbound policy without
tearing down the BGP TCP session (assuming normal route-refresh support).

In VM shell:

```bash
make check-b
```

`make check` deliberately fails here: it checks the *versioned baseline*
which prefers A. This is expected during exercise 2. You can restore
baseline by running:

```bash
make reset
```

`make reset` destroys **only** the BGP-02 lab and deploys from files in
this repository. Uncommitted CLI modifications are lost.

## 3. BGP failover (without rebooting VM or touching Proxmox)

After returning to baseline:

```bash
make failover
```

The script shuts down only CE's BGP neighbor facing A. It verifies CE
forwards via B, tests end-to-end reachability, restores the neighbor,
and checks that A again wins after reconvergence.

For a purely manual version, `make ce`, then:

```text
configure terminal
router bgp 65000
 neighbor 10.0.12.2 shutdown
end
show bgp ipv4 unicast 203.0.113.0/24
```

Restore with:

```text
configure terminal
router bgp 65000
 no neighbor 10.0.12.2 shutdown
end
```

Then, on VM: `bash check.sh --wait`.

## 4. Break and troubleshoot

Try changing CE's inbound LOCAL_PREF values again. Check both BGP RIB
and Linux FIB after each soft inbound refresh. Consider how things
differ if you **remove** BGP `network 203.0.113.0/24` on ORIGIN or
shut down a peering on ISP-B instead. Restore with `make reset`.

## Review questions

1. Why does R1/CE learn two distinct AS-PATHs for `203.0.113.0/24`?
2. Why is LOCAL_PREF evaluated before AS-PATH length?
3. Is LOCAL_PREF normally sent to an eBGP neighbor in another AS?
4. Why is an advertised customer prefix needed for sourced ping replies?
5. What is the difference between a BGP route in RIB and Linux next-hop?
6. If A has LOCAL_PREF 200 but its BGP session fails, does 200 still matter?
7. Why should an ISP's AS-PATH from CE be rewritten when it passes transit?

**Answers:** (1) Two independent upstream AS paths from the same origin.
(2) BGP's decision process considers higher LOCAL_PREF before shorter
AS-PATH. (3) No, not in normal eBGP: it is a within-AS attribute. (4)
Return routing must exist for packets sourced from CE's loopback. (5)
BGP considers candidate paths; the selected route is installed in the
system forwarding table. (6) No, failed routes are withdrawn and backup
wins. (7) Transit prepends its own AS when propagating to eBGP neighbors.
