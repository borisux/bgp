# LAB02 — Configurare manuală Nokia SR Linux (4 routere)

La fiecare echipament, `make ce PLATFORM=srlinux` sau `make isp-a PLATFORM=srlinux` intră în `sr_cli`. Pentru citirea configurației existente: `info from running /network-instance default protocols bgp` sau `info from running /routing-policy`.

**Metodă manuală, pe un router curat:** intri în `enter candidate`, introduci fiecare linie `set / ...` a routerului de mai jos, apoi `commit now`. Fișierele `srlinux/configs/*.cli` conțin aceleași linii; Containerlab le aplică automat la `make up`. În laboratorul deja configurat, inspectează comenzile fără să le dublezi și experimentează doar schimbări deliberate.

Comparație CLI: FRR `router bgp 65000` corespunde Nokia `set / network-instance default protocols bgp autonomous-system 65000`; FRR `neighbor ... remote-as` corespunde Nokia `neighbor ... peer-as`; FRR `route-map ... in` corespunde Nokia `group ... import-policy [...]`. Nokia folosește `commit now`.

## Router CE — comenzi CLI integrale

```text
enter candidate
# Nokia SR Linux partial CLI configuration, applied by containerlab at deploy
set / interface system0 subinterface 0 ipv4 address 192.0.2.1/32
set / network-instance default interface system0.0
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.12.1/30
set / network-instance default interface ethernet-1/1.0
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/2 subinterface 0 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 address 10.0.13.1/30
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp autonomous-system 65000
set / network-instance default protocols bgp router-id 192.0.2.1
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp afi-safi ipv4-unicast admin-state enable
set / routing-policy policy EXPORT-LOCAL default-action policy-result reject
set / routing-policy policy EXPORT-LOCAL statement allow match protocol local
set / routing-policy policy EXPORT-LOCAL statement allow action policy-result accept
set / routing-policy policy PREFER-ISP-A default-action policy-result accept
set / routing-policy policy PREFER-ISP-A default-action bgp local-preference set 200
set / routing-policy policy PREFER-ISP-B default-action policy-result accept
set / routing-policy policy PREFER-ISP-B default-action bgp local-preference set 100
set / network-instance default protocols bgp group ISP-A export-policy [ EXPORT-LOCAL ]
set / network-instance default protocols bgp group ISP-A import-policy [ PREFER-ISP-A ]
set / network-instance default protocols bgp group ISP-A ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.12.2 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.12.2 peer-group ISP-A
set / network-instance default protocols bgp neighbor 10.0.12.2 peer-as 65010
set / network-instance default protocols bgp group ISP-B export-policy [ EXPORT-LOCAL ]
set / network-instance default protocols bgp group ISP-B import-policy [ PREFER-ISP-B ]
set / network-instance default protocols bgp group ISP-B ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.13.2 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.13.2 peer-group ISP-B
set / network-instance default protocols bgp neighbor 10.0.13.2 peer-as 65020
commit now
```

## Router ISP-A — comenzi CLI integrale

```text
enter candidate
# Nokia SR Linux partial CLI configuration, applied by containerlab at deploy
set / interface system0 subinterface 0 ipv4 address 10.10.10.10/32
set / network-instance default interface system0.0
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.12.2/30
set / network-instance default interface ethernet-1/1.0
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/2 subinterface 0 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 address 10.0.24.1/30
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp autonomous-system 65010
set / network-instance default protocols bgp router-id 10.10.10.10
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp afi-safi ipv4-unicast admin-state enable
set / routing-policy policy EXPORT-BGP default-action policy-result reject
set / routing-policy policy EXPORT-BGP statement allow match protocol bgp
set / routing-policy policy EXPORT-BGP statement allow action policy-result accept
set / routing-policy policy IMPORT-ALL default-action policy-result accept
set / network-instance default protocols bgp group CE export-policy [ EXPORT-BGP ]
set / network-instance default protocols bgp group CE import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group CE ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.12.1 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.12.1 peer-group CE
set / network-instance default protocols bgp neighbor 10.0.12.1 peer-as 65000
set / network-instance default protocols bgp group ORIGIN export-policy [ EXPORT-BGP ]
set / network-instance default protocols bgp group ORIGIN import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group ORIGIN ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.24.2 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.24.2 peer-group ORIGIN
set / network-instance default protocols bgp neighbor 10.0.24.2 peer-as 65030
commit now
```

## Router ISP-B — comenzi CLI integrale

```text
enter candidate
# Nokia SR Linux partial CLI configuration, applied by containerlab at deploy
set / interface system0 subinterface 0 ipv4 address 10.20.20.20/32
set / network-instance default interface system0.0
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.13.2/30
set / network-instance default interface ethernet-1/1.0
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/2 subinterface 0 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 address 10.0.34.1/30
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp autonomous-system 65020
set / network-instance default protocols bgp router-id 10.20.20.20
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp afi-safi ipv4-unicast admin-state enable
set / routing-policy policy EXPORT-BGP default-action policy-result reject
set / routing-policy policy EXPORT-BGP statement allow match protocol bgp
set / routing-policy policy EXPORT-BGP statement allow action policy-result accept
set / routing-policy policy IMPORT-ALL default-action policy-result accept
set / network-instance default protocols bgp group CE export-policy [ EXPORT-BGP ]
set / network-instance default protocols bgp group CE import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group CE ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.13.1 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.13.1 peer-group CE
set / network-instance default protocols bgp neighbor 10.0.13.1 peer-as 65000
set / network-instance default protocols bgp group ORIGIN export-policy [ EXPORT-BGP ]
set / network-instance default protocols bgp group ORIGIN import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group ORIGIN ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.34.2 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.34.2 peer-group ORIGIN
set / network-instance default protocols bgp neighbor 10.0.34.2 peer-as 65030
commit now
```

## Router ORIGIN — comenzi CLI integrale

```text
enter candidate
# Nokia SR Linux partial CLI configuration, applied by containerlab at deploy
set / interface system0 subinterface 0 ipv4 address 203.0.113.1/32
set / network-instance default interface system0.0
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 address 10.0.24.2/30
set / network-instance default interface ethernet-1/1.0
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/2 subinterface 0 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 admin-state enable
set / interface ethernet-1/2 subinterface 0 ipv4 address 10.0.34.2/30
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp autonomous-system 65030
set / network-instance default protocols bgp router-id 203.0.113.1
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp afi-safi ipv4-unicast admin-state enable
# A test route originates the /24; the /32 system0 route means 203.0.113.1 replies to ping.
set / network-instance default next-hop-groups group BH blackhole
set / network-instance default static-routes route 203.0.113.0/24 admin-state enable
set / network-instance default static-routes route 203.0.113.0/24 next-hop-group BH
set / routing-policy policy EXPORT-STATIC default-action policy-result reject
set / routing-policy policy EXPORT-STATIC statement allow match protocol static
set / routing-policy policy EXPORT-STATIC statement allow action policy-result accept
set / routing-policy policy IMPORT-ALL default-action policy-result accept
set / network-instance default protocols bgp group ISP-A export-policy [ EXPORT-STATIC ]
set / network-instance default protocols bgp group ISP-A import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group ISP-A ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.24.1 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.24.1 peer-group ISP-A
set / network-instance default protocols bgp neighbor 10.0.24.1 peer-as 65010
set / network-instance default protocols bgp group ISP-B export-policy [ EXPORT-STATIC ]
set / network-instance default protocols bgp group ISP-B import-policy [ IMPORT-ALL ]
set / network-instance default protocols bgp group ISP-B ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.34.1 admin-state enable
set / network-instance default protocols bgp neighbor 10.0.34.1 peer-group ISP-B
set / network-instance default protocols bgp neighbor 10.0.34.1 peer-as 65020
commit now
```

## Exercițiu: modifică LOCAL_PREF în CE

```text
enter candidate
set / routing-policy policy PREFER-ISP-B default-action bgp local-preference set 250
commit now
show network-instance default protocols bgp routes ipv4 prefix 203.0.113.0/24
```

Restaurează prin `make reset PLATFORM=srlinux`.
