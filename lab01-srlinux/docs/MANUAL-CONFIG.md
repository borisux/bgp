# BGP-01 — Configurare manuală FRRouting (`vtysh`)

Acest document explică **cum ai construi manual** aceeași configurație. Modul implicit al acestui repository este însă **automatizat**: `make up` pornește routerele și aplică direct fișierele versionate `r1/frr.conf` și `r2/frr.conf`.

> Nu executa pas cu pas comenzile manuale peste laboratorul deja complet configurat decât dacă testezi intenționat modificările. Comenzile din acest document reprezintă configurația *de la zero*. Pentru o încercare manuală completă folosește o topologie nouă fără `startup-config`, nu modifica neintenționat fișierele de bază.

## Cum intri în routere

Din VM Ubuntu:

```bash
make r1            # echivalent cu: sudo docker exec -it clab-bgp01-r1 vtysh
make r2            # echivalent cu: sudo docker exec -it clab-bgp01-r2 vtysh
```

În `vtysh`, intri în `configure terminal` pentru a edita configurația FRR. Comenzile de verificare (`show ...`) se execută în mod privilegiat, în afara configurației, cu `end`.

## Configurare R1 — AS 65001

```text
configure terminal
hostname R1
interface eth1
 ip address 10.0.12.1/30
exit
interface lo
 ip address 192.0.2.1/32
exit
router bgp 65001
 bgp router-id 192.0.2.1
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.12.2 remote-as 65002
 neighbor 10.0.12.2 description R2-AS65002
 address-family ipv4 unicast
  neighbor 10.0.12.2 activate
  network 192.0.2.1/32
 exit-address-family
exit
end
```

## Configurare R2 — AS 65002

```text
configure terminal
hostname R2
interface eth1
 ip address 10.0.12.2/30
exit
interface lo
 ip address 198.51.100.1/32
exit
router bgp 65002
 bgp router-id 198.51.100.1
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 10.0.12.1 remote-as 65001
 neighbor 10.0.12.1 description R1-AS65001
 address-family ipv4 unicast
  neighbor 10.0.12.1 activate
  network 198.51.100.1/32
 exit-address-family
exit
end
```

## De ce fiecare comandă contează

| Comandă | Ce face |
|---|---|
| `interface eth1` | Selectează interfața de date conectată la celălalt router. `eth0` este management Docker. |
| `ip address 10.0.12.x/30` | Configurează adresarea de pe linkul comun. |
| `interface lo` / `ip address .../32` | Creează un prefix local de demonstrat prin BGP. |
| `router bgp 65001` | Pornește configurația procesului BGP folosind AS-ul local. |
| `bgp router-id ...` | Identificatorul BGP pe 32 biți; aici alegem loopback-ul. |
| `neighbor ... remote-as ...` | Definește peer-ul și AS-ul acestuia: diferit => eBGP. |
| `no bgp default ipv4-unicast` | Nu activa implicit familia IPv4 la fiecare neighbor; o activăm explicit. |
| `address-family ipv4 unicast` | Intră în contextul familiei IPv4 unicast. |
| `neighbor ... activate` | Activează schimbul de rute IPv4 unicast cu acel vecin. |
| `network X/32` | Originează ruta în BGP doar dacă prefixul exact este prezent în tabela de rutare. |
| `no bgp ebgp-requires-policy` | Elimină pentru **acest lab** obligația unei politici eBGP explicite. **Nu este setare recomandată pentru producție.** |

### Sesiunea și rutele

```text
show bgp ipv4 unicast summary
show bgp ipv4 unicast
show bgp ipv4 unicast 198.51.100.1/32
show bgp neighbors
show ip route
show running-config
```

Dacă R1 vede pe `10.0.12.2` cu 1 prefix primit și ruta spre `198.51.100.1/32` via `10.0.12.2`, ai înțeles schimbul de bază BGP.

## Cum păstrezi modificările

- Schimbarea manuală făcută în `vtysh` este **running config**, nu neapărat un fișier Git actualizat.
- `write memory` salvează în configurația gestionată de containerlab, sub `clab-bgp01/`, **nu** rescrie automat `r1/frr.conf` sau `r2/frr.conf` din repo.
- La un deploy nou, `enforce-startup-config: true` readuce configurațiile din repo. Pentru schimbări persistente, editează fișierele din `r1/` și `r2/` și refă deploy-ul (`make down && make up`).
- Pentru proiecte reale, păstrează politici explicite de import/export. Filtrarea prefixelor este subiectul laboratorului BGP-03.

## Provocări practice

1. Schimbă numai router-id pe R1 și verifică ce se întâmplă cu sesiunea.
2. Șterge `network 192.0.2.1/32` din R1. R2 mai are ruta?
3. Pune `shutdown` pe `eth1` (prin Linux: `ip link set eth1 down`) și observă retragerea rutei.
4. Compară tabela BGP cu `show ip route` și `ip -4 route`.
5. Captează TCP/179 și identifică OPEN, KEEPALIVE și UPDATE în Wireshark.
