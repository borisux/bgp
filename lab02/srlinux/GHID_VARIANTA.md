# BGP-02 · Dual ISP, LOCAL_PREF și failover cu Nokia SR Linux

**Curs practic BGP: de la zero la expert** · **Platformă:** Proxmox VM Linux + Docker + Containerlab · **NOS:** Nokia SR Linux 25.10.2 (4 routere).

> Laborator complet automatizat prin `Makefile`. `make up` creează topologia și aplică fișierele `configs/*.cli` înainte să ruleze testele automate. **Nu este nevoie de configurare manuală inițială.**

## Obiective

1. Recunoașterea BGP `Established`, AS_PATH și NEXT_HOP într-o topologie de 4 AS-uri.
2. Înțelegerea `LOCAL_PREF`: **200 pe ISP-A**, **100 pe ISP-B**.
3. Urmărirea prefixului `203.0.113.0/24` prin două tranzite diferite.
4. Simularea failover-ului, revenirea la calea primară și diagnosticarea stărilor BGP.
5. Citirea și editarea configurației Nokia SR Linux în sintaxă CLI nativă.

## Diagramă și adrese

Vezi [docs/TOPOLOGIE.md](docs/TOPOLOGIE.md) (diagramă Mermaid pentru GitHub și plan de adresare).

```text
                CE AS65000
            e1-1 /     \ e1-2
                /       \
      e1-1 ISP-A       ISP-B e1-1
          AS65010       AS65020
           e1-2 \       / e1-2
                 \     /
                ORIGIN AS65030
                203.0.113.0/24
```

## Cerințe

- O VM Debian/Ubuntu pe Proxmox, cu Docker, Containerlab, `make`, `python3`, `curl`.
- `sudo` funcțional pentru utilizator; acces la Internet pentru imaginea oficială Nokia.
- Recomandat: **minimum 4 vCPU și 8 GB RAM disponibili VM-ului**; mărește dacă observi lipsă de memorie (4 containere SR Linux pot consuma resurse semnificative).
- Routerele folosesc imaginea publică `ghcr.io/nokia/srlinux:25.10.2` (fixată, pentru reproductibilitate).

**Nu executa `make install` din Lab-01 aici.** Instalarea Docker/Containerlab este o etapă separată; această versiune funcționează și pe Debian, fără restricția „Ubuntu Server 24.04 only”.

## Pornire rapidă

Din rădăcina laboratorului:

```bash
make preflight
make lint
make pull
make up
```

`make up` configurează routerele folosind `startup-config: configs/<router>.cli` și rulează `make verify` (teste pentru toate peering-urile și calea câștigătoare). Reexecutarea `make up` când lab-ul este deja activ nu este un reset; pentru revenire la configurația originală folosește `make reset`.

## Comenzi Makefile

| Comandă | Acțiune |
|---|---|
| `make preflight` | Verifică Docker, Containerlab, Python, curl |
| `make lint` | Verificări statice (nu rulează SR Linux) |
| `make pull` | Descarcă imaginea Nokia |
| `make up` | Deploy + configurație automată + verificare |
| `make verify` | Verifică peering și best path cu timeout |
| `make status` | Listează routerele și adresele de management |
| `make ce`, `make isp-a`, `make isp-b`, `make origin` | CLI nativ `sr_cli` |
| `make routes` | Afișează ruta BGP pentru prefix pe CE |
| `make failover` | Dezactivează portul CE către ISP-A, verifică backup-ul |
| `make restore` | Reactivează portul CE către ISP-A, verifică primarul |
| `make reset` | Destroy + deploy cu configurațiile inițiale |
| `make down` | Îndepărtează DOAR această topologie |

## Cum funcționează auto-configurarea?

Fiecare nod declară `startup-config` în [bgp02.clab.yml](bgp02.clab.yml). Containerlab aplică comenzile `set / ...` peste configurația de management predefinită la primul deploy.

La CE, politicile de import `PREFER-ISP-A` și `PREFER-ISP-B` setează `LOCAL_PREF`. ISP-urile tranzitează rutele BGP doar prin `EXPORT-BGP`; ORIGIN injectează ruta statică /24 prin `EXPORT-STATIC`. CE exportă prefixele locale prin `EXPORT-LOCAL`, astfel încât traficul ICMP poate reveni de la ORIGIN.

**Important:** policy `EXPORT-BGP` / `EXPORT-LOCAL` sunt simplificate pedagogic pentru o topologie izolată; într-o rețea de producție se impune filtrare strictă de prefixe și protecție contra route leak. Vom studia asta în laboratoarele avansate.

## Teste manuale

```bash
make ce
```

```text
show network-instance default protocols bgp summary
show network-instance default protocols bgp routes ipv4 prefix 203.0.113.0/24
show network-instance default route-table ipv4-unicast prefix 203.0.113.0/24 detail
ping 203.0.113.1 network-instance default
```

Așteptat în starea inițială: **ruta best via ISP-A `10.0.12.2`, LocalPref 200**; a doua rută via ISP-B `10.0.13.2`, LocalPref 100.

Apoi:

```bash
make failover
make routes
make restore
make verify
```

## Exerciții ghidate

[docs/EXERCITII.md](docs/EXERCITII.md) include explicațiile despre fiecare politică, ruta BGP, preluarea traficului și depanare.

## Fișiere

```text
lab02-srlinux/
├── README.md
├── Makefile
├── bgp02.clab.yml
├── configs/
│   ├── ce.cli
│   ├── isp-a.cli
│   ├── isp-b.cli
│   └── origin.cli
├── docs/
│   ├── TOPOLOGIE.md
│   └── EXERCITII.md
└── scripts/
    ├── client.py
    ├── check.py
    ├── change.py
    └── lint.py
```

## Depanare / note despre compatibilitate

- Testele din `make verify`, `make failover` și `make restore` folosesc JSON-RPC pe adresele management din rețeaua Docker `clab`. Configurația implicită Containerlab activează JSON-RPC. Pentru alte credentiale exportă `SRL_USER` și `SRL_PASSWORD`; implicit doar pentru lab: `admin` / `NokiaSrl1!`.
- Dacă ai un firewall care blochează accesul local la Docker bridge, fă managementul și testele manual cu `make ce`, apoi `make routes`.
- `make lint` face verificări offline ale structurii, nu verifică semantica Nokia SR Linux.
- **Autorul nu a executat imaginile pe VM-ul utilizatorului**: verificările de runtime (`make up`, `make verify`) trebuie rulate în VM pentru a confirma compatibilitatea versiunilor folosite. Raportează erorile și ajustăm configurația în repo.
- Modificările manuale rămân în configurația live a containerelor; `make reset` distruge/recreează topologia, refăcând bazele versiunii din Git.

## Referințe

- https://containerlab.dev/manual/kinds/srl/
- https://learn.srlinux.dev/cli/show-commands/bgp/
- https://documentation.nokia.com/srlinux/25-10/books/routing-protocols/route-policies.html
- https://github.com/nokia/srlinux-container-image
