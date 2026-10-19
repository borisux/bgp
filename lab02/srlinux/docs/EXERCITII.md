# BGP-02 — Exerciții practice Nokia SR Linux

## 0. Deploy

```bash
make up
make status
```

Rezultatul așteptat: 4 noduri SR Linux și toate sesiunile eBGP în `established`.

## 1. Identifică cei doi vecini CE

```bash
make ce
```

În CLI SR Linux:

```text
show network-instance default protocols bgp summary
show network-instance default protocols bgp neighbor 10.0.12.2 detail
show network-instance default protocols bgp neighbor 10.0.13.2 detail
```

Întrebări: ce înseamnă `peer-as`? Câte sesiuni eBGP are CE?

## 2. Urmărește prefixul și selecția best path

```text
show network-instance default protocols bgp routes ipv4 prefix 203.0.113.0/24
show network-instance default route-table ipv4-unicast prefix 203.0.113.0/24 detail
```

Observă `Route source`, `AS Path`, `BGP next-hop` și `LocalPref`.
Așteptat: ISP-A (`10.0.12.2`) câștigă prin LocalPref 200; ISP-B are 100.

**Important:** LOCAL_PREF nu se trimite pe sesiunile eBGP; valoarea este atribuită local prin `import-policy` pe CE.

## 3. Vezi politicile în configurația reală

```text
info from running /routing-policy
info from running /network-instance default protocols bgp
```

Găsește `PREFER-ISP-A` și `PREFER-ISP-B` în `configs/ce.cli`.

## 4. Provoacă o întrerupere ISP-A

Ieși din CLI (`exit`), apoi pe VM:

```bash
make failover
make routes
```

Așteptat: peer-ul CE->ISP-A nu mai este `established`; ruta `203.0.113.0/24` folosește `10.0.13.2` cu LOCAL_PREF 100.

**Distincție:** schimbarea de mai sus este convergență BGP obișnuită, nu BGP Fast Reroute cu backup instalat în FIB.

## 5. Revino la ISP-A

```bash
make restore
make verify
```

Așteptat: noul best path este `10.0.12.2` cu LOCAL_PREF 200.

## 6. Test de conectivitate

Din CE:

```text
ping 203.0.113.1 network-instance default
```

Prefixul /24 este originat de o rută statică de tip blackhole pe ORIGIN, dar 203.0.113.1/32 este local pe `system0.0`, deci răspunde la ping. CE exportă prefixele locale pentru întoarcerea traficului.

## 7. Experimente manuale (opțional)

În CE, după `enter candidate`:

```text
set / routing-policy policy PREFER-ISP-B default-action bgp local-preference set 250
commit now
```

Acum ISP-B trebuie să câștige chiar când ambele sesiuni sunt active. Nu executa `make verify` până nu revii la valorile implicite: `make reset` recreează laboratorul de la configurațiile versionate în Git.

## 8. Depanare

```bash
make status
make routes
sudo docker logs clab-bgp02-srl-ce --tail 80
sudo docker exec -it clab-bgp02-srl-ce sr_cli
```

În SR Linux, verifică starea portului și adresa IPv4:

```text
show interface ethernet-1/1 detail
show network-instance default protocols bgp summary
```

Dacă `make failover` raportează HTTP 401, verifică datele JSON-RPC ale imaginii SR Linux (`SRL_USER`/`SRL_PASSWORD`); contul implicit de lab este `admin` / `NokiaSrl1!`.
