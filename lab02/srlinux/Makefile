.DEFAULT_GOAL := help
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
TOPO := bgp02.clab.yml
CLAB := sudo -E containerlab
DOCKER := sudo -E docker
PY := sudo -E python3

.PHONY: help preflight lint pull up deploy verify check status nodes ce isp-a isp-b origin routes failover restore reset down destroy clean
help:
	@echo 'BGP-02 SR Linux | targets:'
	@echo '  make preflight      verificari VM si unelte'
	@echo '  make lint           verificari statice (fara pornirea containerelor)'
	@echo '  make pull           download SR Linux 25.10.2'
	@echo '  make up             deploy si verify (configurare automatizata)'
	@echo '  make verify         teste BGP automate, cu timeout'
	@echo '  make status         inspect Containerlab'
	@echo '  make routes         tabela BGP CE'
	@echo '  make ce             CLI Nokia CE'
	@echo '  make isp-a          CLI Nokia ISP-A'
	@echo '  make isp-b          CLI Nokia ISP-B'
	@echo '  make origin         CLI Nokia ORIGIN'
	@echo '  make failover       dezactiveaza CE->ISP-A si verifica ISP-B'
	@echo '  make restore        reactiveaza CE->ISP-A si verifica ISP-A'
	@echo '  make down           sterge topologia; nu afecteaza alte lab-uri'
	@echo '  make reset          sterge si recreeaza cu configuratia initiala'

preflight:
	@command -v containerlab >/dev/null || { echo 'Eroare: lipseste containerlab'; exit 1; }
	@command -v docker >/dev/null || { echo 'Eroare: lipseste docker'; exit 1; }
	@command -v python3 >/dev/null || { echo 'Eroare: lipseste python3'; exit 1; }
	@command -v curl >/dev/null || { echo 'Eroare: lipseste curl'; exit 1; }
	@$(DOCKER) info >/dev/null
	@$(CLAB) version
	@echo 'OK: Docker daemon + Containerlab + Python'

lint:
	@python3 scripts/lint.py

pull: preflight
	@$(DOCKER) pull ghcr.io/nokia/srlinux:25.10.2

up: preflight lint
	@$(CLAB) deploy -t $(TOPO)
	@$(MAKE) verify

deploy: up

verify:
	@$(PY) scripts/check.py --mode primary --wait 180

check: verify

status nodes:
	@$(CLAB) inspect -t $(TOPO)

routes:
	@$(DOCKER) exec clab-bgp02-srl-ce sr_cli 'show network-instance default protocols bgp routes ipv4 prefix 203.0.113.0/24'

ce:
	@$(DOCKER) exec -it clab-bgp02-srl-ce sr_cli

isp-a:
	@$(DOCKER) exec -it clab-bgp02-srl-isp-a sr_cli

isp-b:
	@$(DOCKER) exec -it clab-bgp02-srl-isp-b sr_cli

origin:
	@$(DOCKER) exec -it clab-bgp02-srl-origin sr_cli

failover:
	@$(PY) scripts/change.py disable
	@$(PY) scripts/check.py --mode backup --wait 180

restore:
	@$(PY) scripts/change.py enable
	@$(PY) scripts/check.py --mode primary --wait 180

down destroy:
	@$(CLAB) destroy -t $(TOPO) --cleanup

reset:
	@$(MAKE) down
	@$(MAKE) up

clean: down
