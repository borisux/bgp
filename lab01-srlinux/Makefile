.DEFAULT_GOAL := help
.PHONY: help install up check status down logs r1 r2 lint

help:
	@echo 'BGP-01 FRRouting Lab'
	@echo '  make install  - install Ubuntu host dependencies (Docker + Containerlab)'
	@echo '  make up       - deploy lab, wait for eBGP and verify routing'
	@echo '  make check    - verify eBGP routes and end-to-end loopback ping'
	@echo '  make status   - list lab nodes'
	@echo '  make r1       - open R1 vtysh CLI'
	@echo '  make r2       - open R2 vtysh CLI'
	@echo '  make logs     - show recent container logs'
	@echo '  make down     - destroy only this lab'
	@echo '  make lint     - static config and shell checks'

install:
	bash scripts/install-host.sh

up:
	bash scripts/deploy.sh

check:
	bash check.sh

status:
	sudo containerlab inspect -t bgp01.clab.yml

r1:
	sudo docker exec -it clab-bgp01-r1 vtysh

r2:
	sudo docker exec -it clab-bgp01-r2 vtysh

logs:
	sudo docker logs --tail 80 clab-bgp01-r1
	sudo docker logs --tail 80 clab-bgp01-r2

down:
	sudo containerlab destroy -t bgp01.clab.yml --cleanup

lint:
	@for file in check.sh scripts/*.sh; do bash -n "$$file" || exit; done
	python3 scripts/static_lint.py
