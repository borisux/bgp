# LAB02 — Configurare manuală FRRouting (4 routere)

Această pagină reproduce **exact configurația de pornire** din `frr/*/frr.conf`. Pentru studiu, deschide routerul cu `make ce PLATFORM=frr`, apoi `show running-config`.

Dacă configurezi de la zero într-o topologie fără `startup-config`, intră în `vtysh`, apoi `configure terminal`. Liniile `frr defaults` / `hostname` fac parte din fișierul de configurare; comenzile `interface`, `router bgp`, `route-map` sunt cele relevante în `vtysh`. Pentru a aplica modificări în laboratorul deja pornit, editează doar secțiunile pe care vrei să le experimentezi și folosește `write memory` numai dacă vrei să păstrezi modificarea în configurația runtime.

## Logica politicii BGP

- În CE: `FROM-ISP-A` setează 200, `FROM-ISP-B` setează 100. Comenzile `neighbor ... route-map ... in` aplică politica **la primire**.
- În ORIGIN: `network 203.0.113.0/24` introduce prefixul local în BGP. Trebuie să existe exact acel prefix în tabela IP.
- În ISP-A/B: sesiunile eBGP cu CE și ORIGIN distribuie prefixul, demonstrând tranzitul.
- FRR din lab dezactivează cerința de politici eBGP prin `no bgp ebgp-requires-policy` numai pentru scop didactic; în producție folosește filtre explicite.

## Router CE — configurația integrală

```frr
frr defaults traditional
hostname CE
!
interface eth1
 ip address 10.0.12.1/30
exit
!
interface eth2
 ip address 10.0.13.1/30
exit
!
interface lo
 ip address 192.0.2.1/32
exit
!
! Import policy: prefer ISP-A even though both paths have equal AS-PATH length.
route-map FROM-ISP-A permit 10
 set local-preference 200
exit
!
route-map FROM-ISP-B permit 10
 set local-preference 100
exit
!
router bgp 65000
 bgp router-id 192.0.2.1
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.12.2 remote-as 65010
 neighbor 10.0.12.2 description ISP-A
 neighbor 10.0.13.2 remote-as 65020
 neighbor 10.0.13.2 description ISP-B
 !
 address-family ipv4 unicast
  neighbor 10.0.12.2 activate
  neighbor 10.0.12.2 route-map FROM-ISP-A in
  neighbor 10.0.13.2 activate
  neighbor 10.0.13.2 route-map FROM-ISP-B in
  network 192.0.2.1/32
 exit-address-family
exit
!
```

## Router ISP-A — configurația integrală

```frr
frr defaults traditional
hostname ISP-A
!
interface eth1
 ip address 10.0.12.2/30
exit
!
interface eth2
 ip address 10.0.24.1/30
exit
!
router bgp 65010
 bgp router-id 10.255.0.10
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.12.1 remote-as 65000
 neighbor 10.0.12.1 description CE
 neighbor 10.0.24.2 remote-as 65030
 neighbor 10.0.24.2 description ORIGIN
 !
 address-family ipv4 unicast
  neighbor 10.0.12.1 activate
  neighbor 10.0.24.2 activate
 exit-address-family
exit
!
```

## Router ISP-B — configurația integrală

```frr
frr defaults traditional
hostname ISP-B
!
interface eth1
 ip address 10.0.13.2/30
exit
!
interface eth2
 ip address 10.0.34.1/30
exit
!
router bgp 65020
 bgp router-id 10.255.0.20
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.13.1 remote-as 65000
 neighbor 10.0.13.1 description CE
 neighbor 10.0.34.2 remote-as 65030
 neighbor 10.0.34.2 description ORIGIN
 !
 address-family ipv4 unicast
  neighbor 10.0.13.1 activate
  neighbor 10.0.34.2 activate
 exit-address-family
exit
!
```

## Router ORIGIN — configurația integrală

```frr
frr defaults traditional
hostname ORIGIN
!
interface eth1
 ip address 10.0.24.2/30
exit
!
interface eth2
 ip address 10.0.34.2/30
exit
!
interface lo
 ip address 203.0.113.1/24
exit
!
router bgp 65030
 bgp router-id 203.0.113.1
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.24.1 remote-as 65010
 neighbor 10.0.24.1 description ISP-A
 neighbor 10.0.34.1 remote-as 65020
 neighbor 10.0.34.1 description ISP-B
 !
 address-family ipv4 unicast
  neighbor 10.0.24.1 activate
  neighbor 10.0.34.1 activate
  network 203.0.113.0/24
 exit-address-family
exit
!
```

